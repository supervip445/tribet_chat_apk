import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📬 Background message received: ${message.messageId}');
  debugPrint('📦 Title: ${message.notification?.title}');
  debugPrint('📦 Body: ${message.notification?.body}');
  debugPrint('📦 Data: ${message.data}');
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _fcmToken;
  final List<Function(RemoteMessage)> _messageListeners = [];

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _fcmToken != null;

  /// Initialize FCM and request permissions
  Future<void> initialize() async {
    try {
      debugPrint('🔥 Initializing Firebase Cloud Messaging...');

      // Request notification permissions (Android 13+)
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('📱 Notification permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ Notification permission granted');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('⚠️ Notification permission granted provisionally');
      } else {
        debugPrint('❌ Notification permission denied');
        return;
      }

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Get FCM token
      await _getFCMToken();

      // Subscribe to 'public' topic to receive broadcast notifications
      try {
        await _firebaseMessaging.subscribeToTopic('public');
        debugPrint('✅ Subscribed to FCM topic: public');
      } catch (e) {
        debugPrint('⚠️ Error subscribing to topic: $e');
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 FCM token refreshed: $newToken');
        _fcmToken = newToken;
        _saveFCMToken(newToken);
        // Re-subscribe to topic after token refresh
        _firebaseMessaging.subscribeToTopic('public').catchError((e) {
          debugPrint('⚠️ Error re-subscribing to topic: $e');
        });
      });

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📨 Foreground message received');
        debugPrint('📦 Title: ${message.notification?.title}');
        debugPrint('📦 Body: ${message.notification?.body}');
        debugPrint('📦 Data: ${message.data}');
        
        // Notify all listeners
        for (var listener in _messageListeners) {
          try {
            listener(message);
          } catch (e) {
            debugPrint('❌ Error in message listener: $e');
          }
        }
      });

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('📬 Notification tapped (app in background)');
        debugPrint('📦 Data: ${message.data}');
        
        // Notify all listeners
        for (var listener in _messageListeners) {
          try {
            listener(message);
          } catch (e) {
            debugPrint('❌ Error in message listener: $e');
          }
        }
      });

      // Check if app was opened from a notification
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('📬 App opened from notification');
        debugPrint('📦 Data: ${initialMessage.data}');
        
        // Notify all listeners
        for (var listener in _messageListeners) {
          try {
            listener(initialMessage);
          } catch (e) {
            debugPrint('❌ Error in message listener: $e');
          }
        }
      }

      debugPrint('✅ FCM initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error initializing FCM: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }

  /// Get FCM token
  Future<String?> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        debugPrint('✅ FCM token obtained: $_fcmToken');
        await _saveFCMToken(_fcmToken!);
      } else {
        debugPrint('⚠️ FCM token is null');
      }
      return _fcmToken;
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Save FCM token to SharedPreferences
  Future<void> _saveFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      debugPrint('💾 FCM token saved to SharedPreferences');
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  /// Get saved FCM token from SharedPreferences
  Future<String?> getSavedFCMToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('fcm_token');
    } catch (e) {
      debugPrint('❌ Error getting saved FCM token: $e');
      return null;
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic $topic: $e');
    }
  }

  /// Add a message listener
  void onMessage(Function(RemoteMessage) callback) {
    _messageListeners.add(callback);
  }

  /// Remove a message listener
  void removeMessageListener(Function(RemoteMessage) callback) {
    _messageListeners.remove(callback);
  }

  /// Delete FCM token (for logout)
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');
      debugPrint('🗑️ FCM token deleted');
    } catch (e) {
      debugPrint('❌ Error deleting FCM token: $e');
    }
  }
}

