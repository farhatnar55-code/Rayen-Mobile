import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rayen_mobile/core/router/app_router.dart';
import 'package:rayen_mobile/features/authentication/domain/models/user_model.dart';

class PushNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    'rayen_notifications',
    'Rayen Notifications',
    description: 'Notifications for training updates',
    importance: Importance.high,
  );

  String? _currentUserId;
  String? _currentToken;

  Future<void> initialize({
    Future<void> Function(RemoteMessage message)? onForegroundMessage,
    Future<void> Function(RemoteMessage message)? onOpenMessage,
  }) async {
    await _requestPermissions();
    await _initializeLocalNotifications();

    FirebaseMessaging.onMessage.listen((message) async {
      await _showLocalNotification(message);
      if (onForegroundMessage != null) {
        await onForegroundMessage(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      if (onOpenMessage != null) {
        await onOpenMessage(message);
      } else {
        _openRouteFromMessage(message);
      }
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      if (onOpenMessage != null) {
        await onOpenMessage(initialMessage);
      } else {
        _openRouteFromMessage(initialMessage);
      }
    }

    _messaging.onTokenRefresh.listen((token) {
      unawaited(_saveToken(token));
    });
  }

  Future<void> syncUser(UserModel? user) async {
    if (user == null) {
      await clearCurrentUser();
      return;
    }

    if (_currentUserId == user.uid) {
      return;
    }

    await clearCurrentUser();
    _currentUserId = user.uid;
    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      _currentToken = token;
      await _saveToken(token);
    }
  }

  Future<void> clearCurrentUser() async {
    final token = _currentToken ?? await _messaging.getToken();
    if (_currentUserId != null && token != null && token.isNotEmpty) {
      await _firestore.collection('user_devices').doc(token).delete();
    }
    _currentUserId = null;
    _currentToken = null;
  }

  Future<void> _saveToken(String token) async {
    if (_currentUserId == null || token.isEmpty) return;

    _currentToken = token;
    await _firestore.collection('user_devices').doc(token).set({
      'userId': _currentUserId,
      'token': token,
      'platform': Platform.isIOS ? 'ios' : 'android',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _requestPermissions() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    if (Platform.isAndroid) {
      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _localNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final route = response.payload;
        if (route != null && route.isNotEmpty) {
          _navigate(route);
        }
      },
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'rayen_notifications',
      'Rayen Notifications',
      channelDescription: 'Notifications for training updates',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);
    await _localNotificationsPlugin.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data['targetRoute'] as String?,
    );
  }

  void _openRouteFromMessage(RemoteMessage message) {
    final route = message.data['targetRoute'] as String?;
    if (route != null && route.isNotEmpty) {
      _navigate(route);
    }
  }

  void _navigate(String route) {
    final router = AppRouter.currentRouter;
    if (router != null) {
      router.go(route);
    }
  }
}
