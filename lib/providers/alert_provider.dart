import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

final dio = Dio();
const String _alertUrl = 'http://127.0.0.1:8000/api/v1/alerts/shark';

// Provider lưu trữ ID các cảnh báo đã show để tránh lặp lại spam Màn Hình
final shownAlertsProvider = StateProvider<Set<int>>((ref) => {});

// Stream liên tục quạt API mỗi 15 giây để rình cá mập
final sharkAlertStreamProvider = StreamProvider<List<dynamic>>((ref) async* {
  while (true) {
    try {
      final response = await dio.get(_alertUrl);
      if (response.statusCode == 200) {
        final alerts = response.data['alerts'] as List<dynamic>? ?? [];
        yield alerts;
      }
    } catch (e) {
      // Nuốt lỗi mạng lẳng lặng chờ loop sau
    }
    await Future.delayed(const Duration(seconds: 15));
  }
});
