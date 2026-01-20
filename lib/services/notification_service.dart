import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  io.Socket? _socket;
  bool _isConnected = false;
  String? _userId;
  final List<Function(Map<String, dynamic>)> _listeners = [];

  String get userId => _userId ?? 'public';
  bool get isConnected => _isConnected;

  Future<void> connect({String? userId}) async {
    // If already connected, don't reconnect
    if (_socket != null && _isConnected) {
      debugPrint('✅ Already connected to notification server');
      return;
    }

    // Disconnect existing socket if it exists but not connected
    if (_socket != null) {
      debugPrint('🔄 Disconnecting existing socket...');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
    }

    // Get or create public user ID
    if (userId == null || userId == 'public') {
      userId = await _getOrCreatePublicUserId();
    }

    _userId = userId;
    debugPrint('👤 User ID: $userId');

    const serverUrl = 'https://maxwin688.site';
    debugPrint('🔗 Connecting to notification server: $serverUrl');

    try {
      // Create socket WITHOUT auto-connect so we can set up listeners first
      _socket = io.io(
        serverUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .disableAutoConnect() // Disable auto-connect so we can set up listeners first
            .enableReconnection()
            .setReconnectionDelay(1000)
            .setReconnectionAttempts(5)
            .setTimeout(20000)
            .build(),
      );

      // Set up ALL listeners BEFORE connecting
      _socket!.onConnect((_) {
        debugPrint('🔌 Connected to notification server');
        _isConnected = true;
        debugPrint('📝 Registering user: $userId');
        _socket!.emit('register', userId);
      });

      _socket!.onDisconnect((_) {
        debugPrint('❌ Disconnected from notification server');
        _isConnected = false;
      });

      _socket!.on('receive_noti', (data) {
        debugPrint('📨 Received notification event');
        debugPrint('📦 Notification data type: ${data.runtimeType}');
        debugPrint('📦 Notification data: $data');

        Map<String, dynamic>? notificationData;

        // Handle different data formats
        if (data is Map<String, dynamic>) {
          notificationData = data;
        } else if (data is List &&
            data.isNotEmpty &&
            data[0] is Map<String, dynamic>) {
          // Sometimes socket.io sends data as a list
          notificationData = data[0] as Map<String, dynamic>;
        } else {
          debugPrint(
            '⚠️ Notification data format not recognized: ${data.runtimeType}',
          );
          return;
        }

        // notificationData is guaranteed to be non-null at this point

        final toUserId = notificationData['to_user_id'];
        debugPrint(
          '👤 Notification to_user_id: $toUserId, current userId: $userId',
        );

        // Handle public broadcasts - accept if to_user_id is 'public', 'all', or matches our userId
        if (toUserId == 'public' || toUserId == 'all' || toUserId == userId) {
          debugPrint('✅ Notification matches - notifying listeners');
          _notifyListeners(notificationData);
        } else {
          debugPrint(
            '⚠️ Notification does not match - ignoring (to_user_id: $toUserId, userId: $userId)',
          );
        }
      });

      _socket!.onConnectError((error) {
        debugPrint('❌ Connection error: $error');
        _isConnected = false;
      });

      _socket!.onError((error) {
        debugPrint('❌ Socket error: $error');
      });

      // Now connect after all listeners are set up
      debugPrint('🚀 Connecting socket...');
      _socket!.connect();
    } catch (e) {
      debugPrint('❌ Error connecting to notification server: $e');
      _isConnected = false;
    }
  }

  Future<String> _getOrCreatePublicUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('public_user_id');
    if (userId == null) {
      userId =
          'public_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().hashCode}';
      await prefs.setString('public_user_id', userId);
    }
    return userId;
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  void onNotification(Function(Map<String, dynamic>) callback) {
    _listeners.add(callback);
  }

  void removeListener(Function(Map<String, dynamic>) callback) {
    _listeners.remove(callback);
  }

  void _notifyListeners(Map<String, dynamic> data) {
    for (var listener in _listeners) {
      try {
        listener(data);
      } catch (e) {
        debugPrint('Error in notification listener: $e');
      }
    }
  }
}
