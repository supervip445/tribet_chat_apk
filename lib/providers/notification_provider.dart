import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/notification_service.dart';
import '../services/fcm_service.dart';
import 'dart:developer' as developer;

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String? route;
  final String? type;
  final Map<String, dynamic>? data;
  final DateTime timestamp;
  bool read;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.route,
    this.type,
    this.data,
    required this.timestamp,
    this.read = false,
  });
}

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final FCMService _fcmService = FCMService();
  final List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;

  NotificationProvider() {
    _initialize();
  }

  void _initialize() async {
    developer.log('🔔 Initializing notification provider...');
    
    // Check badge support first
    try {
      final isSupported = await FlutterAppBadger.isAppBadgeSupported();
      developer.log('📱 App badge support check: $isSupported');
    } catch (e) {
      developer.log('⚠️ Error checking badge support: $e');
    }
    
    // Initialize FCM (Firebase Cloud Messaging) for push notifications
    try {
      await _fcmService.initialize();
      developer.log('✅ FCM initialized');
      
      // Listen for FCM messages
      _fcmService.onMessage((RemoteMessage message) {
        developer.log('📬 FCM message received in provider');
        _handleFCMNotification(message);
      });
    } catch (e) {
      developer.log('⚠️ Error initializing FCM: $e');
    }
    
    // Initialize Socket.IO for real-time notifications
    await _notificationService.connect();
    developer.log('✅ Notification service connected');
    _notificationService.onNotification(_handleNotification);
    developer.log('👂 Notification listener registered');
    
    // Initialize app badge
    await _updateAppBadge();
    developer.log('📱 App badge initialized');
  }

  /// Handle FCM push notification
  void _handleFCMNotification(RemoteMessage message) async {
    developer.log('📬 Handling FCM notification');
    
    final notification = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? message.data['title'] ?? 'Notification',
      body: message.notification?.body ?? message.data['body'] ?? '',
      route: message.data['route'],
      type: message.data['type'],
      data: message.data,
      timestamp: message.sentTime ?? DateTime.now(),
      read: false,
    );

    developer.log('✅ Created FCM notification: ${notification.title}');
    _notifications.insert(0, notification);
    _unreadCount++;
    developer.log('📊 Total notifications: ${_notifications.length}, Unread: $_unreadCount');
    
    // Notify listeners first to update UI immediately
    notifyListeners();

    // Update app icon badge
    developer.log('📱 Updating app badge with count: $_unreadCount');
    await _updateAppBadge();

    // Play notification sound
    _playNotificationSound();
    developer.log('🔔 FCM notification handled successfully');
  }

  Future<void> _updateAppBadge() async {
    try {
      developer.log('📱 Updating app badge...');
      developer.log('📱 Current unread count: $_unreadCount');
      
      // Add a small delay to ensure state is fully updated
      await Future.delayed(const Duration(milliseconds: 50));
      
      final isSupported = await FlutterAppBadger.isAppBadgeSupported();
      developer.log('📱 App badge supported: $isSupported');
      
      if (isSupported) {
        if (_unreadCount > 0) {
          developer.log('📱 Setting badge count to: $_unreadCount');
          try {
            await FlutterAppBadger.updateBadgeCount(_unreadCount);
            developer.log('✅ Badge count set to $_unreadCount');
            
            // Verify the badge was set by checking again after a short delay
            await Future.delayed(const Duration(milliseconds: 200));
            developer.log('✅ Badge update confirmed');
          } catch (updateError) {
            developer.log('❌ Error updating badge count: $updateError');
            // Retry with exponential backoff
            for (int i = 0; i < 3; i++) {
              await Future.delayed(Duration(milliseconds: 100 * (i + 1)));
              try {
                await FlutterAppBadger.updateBadgeCount(_unreadCount);
                developer.log('✅ Badge count updated on retry ${i + 1}');
                break;
              } catch (retryError) {
                developer.log('❌ Badge update retry ${i + 1} failed: $retryError');
                if (i == 2) {
                  developer.log('❌ All badge update attempts failed');
                }
              }
            }
          }
        } else {
          developer.log('📱 Removing badge (unread count is 0)');
          try {
            await FlutterAppBadger.removeBadge();
            developer.log('✅ Badge removed successfully');
          } catch (removeError) {
            developer.log('❌ Error removing badge: $removeError');
          }
        }
      } else {
        developer.log('⚠️ App badge is NOT supported on this device/launcher');
        developer.log('⚠️ Note: Badges work on iOS and some Android launchers');
        developer.log('⚠️ Supported launchers: Samsung One UI, Xiaomi MIUI, Huawei EMUI, etc.');
        developer.log('⚠️ Stock Android launchers (Pixel, OnePlus) do NOT support badges');
      }
    } catch (e, stackTrace) {
      developer.log('❌ Error in _updateAppBadge: $e');
      developer.log('❌ Stack trace: $stackTrace');
    }
  }

  void _handleNotification(Map<String, dynamic> data) async {
    developer.log('🔔 Handling notification in provider');
    developer.log('📦 Notification data: $data');
    
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      route: data['notification_data']?['route'],
      type: data['notification_data']?['type'],
      data: data['notification_data'],
      timestamp: DateTime.now(),
      read: false,
    );

    developer.log('✅ Created notification: ${notification.title}');
    _notifications.insert(0, notification);
    _unreadCount++;
    developer.log('📊 Total notifications: ${_notifications.length}, Unread: $_unreadCount');
    
    // Notify listeners first to update UI immediately
    notifyListeners();

    // Update app icon badge - do this after notifying listeners
    developer.log('📱 Updating app badge with count: $_unreadCount');
    await _updateAppBadge();

    // Play notification sound
    _playNotificationSound();
    developer.log('🔔 Notification handled successfully');
  }

  Future<void> _playNotificationSound() async {
    try {
      // Try loading from network (Laravel public folder)
      await _audioPlayer.play(UrlSource('https://goldencitycasino123.pro/sounds/noti.wav'));
    } catch (e) {
      developer.log('Error playing notification sound from network: $e');
      // Fallback: Try loading from assets if network doesn't work
      try {
        await _audioPlayer.play(AssetSource('sounds/noti.wav'));
      } catch (e2) {
        developer.log('Error playing notification sound from assets: $e2');
      }
    }
  }

  void markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].read) {
      _notifications[index].read = true;
      _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      notifyListeners();
      // Update app icon badge
      await _updateAppBadge();
    }
  }

  void markAllAsRead() async {
    for (var notification in _notifications) {
      notification.read = true;
    }
    _unreadCount = 0;
    notifyListeners();
    // Update app icon badge
    await _updateAppBadge();
  }

  void clearNotifications() async {
    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();
    await _updateAppBadge();
  }

  @override
  void dispose() {
    _notificationService.disconnect();
    _audioPlayer.dispose();
    super.dispose();
  }
}

