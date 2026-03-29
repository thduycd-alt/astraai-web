import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

/// Xử lý FCM notification khi app ở background (top-level function bắt buộc)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] Background message: ${message.messageId}');
}

class FCMService {
  static final FCMService _i = FCMService._();
  factory FCMService() => _i;
  FCMService._();

  final _messaging = FirebaseMessaging.instance;
  String? _token;

  // Callback để navigate khi tap notification
  void Function(String symbol)? onNavigateToStock;

  /// Khởi động FCM — gọi trong main() sau Firebase.initializeApp()
  Future<void> initialize() async {
    // 1. Xin quyền notification (iOS/Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true, badge: true, sound: true,
      announcement: false, carPlay: false,
      criticalAlert: false, provisional: false,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

    // 2. Lấy FCM token và đăng ký lên backend
    _token = await _messaging.getToken();
    debugPrint('[FCM] Token: $_token');
    if (_token != null) {
      await _subscribeTopics(_token!);
    }

    // 3. Token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _token = newToken;
      _subscribeTopics(newToken);
    });

    // 4. Foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForeground);

    // 5. App opened từ notification (background → foreground)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 6. App mở từ terminated state bởi notification
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      Future.delayed(const Duration(milliseconds: 500), () => _handleNotificationTap(initial));
    }
  }

  Future<void> _subscribeTopics(String token) async {
    // Subscribe theo topic để nhận push từ backend
    await _messaging.subscribeToTopic('market_alerts');
    await _messaging.subscribeToTopic('whale_alerts');
    debugPrint('[FCM] Subscribed to: market_alerts, whale_alerts');

    // Đăng ký token lên backend
    try {
      final dio = Dio(BaseOptions(
        baseUrl: 'https://astraai-signals-api.onrender.com/api/v1',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ));
      await dio.post('/notifications/subscribe',
        queryParameters: {'token': token, 'topic': 'market_alerts'});
    } catch (e) {
      debugPrint('[FCM] Backend subscribe error: $e');
    }
  }

  void _handleForeground(RemoteMessage message) {
    debugPrint('[FCM] Foreground: ${message.notification?.title}');
    // Notification được hiển thị bởi Firebase tự động trên iOS
    // Android: cần thêm flutter_local_notifications nếu muốn hiện trên foreground
  }

  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final symbol = data['symbol'] as String?;
    final type   = data['type']   as String?;
    debugPrint('[FCM] Tapped: type=$type symbol=$symbol');

    if (symbol != null && symbol.isNotEmpty) {
      onNavigateToStock?.call(symbol.toUpperCase());
    }
  }

  String? get token => _token;
}

// Singleton để dùng toàn app
final fcmService = FCMService();
