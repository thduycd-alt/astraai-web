import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dio/dio.dart';

// ─── Model ─────────────────────────────────────────────────────────────────
class SharkAlert {
  final int    id;
  final String title;
  final String message;
  final String color;      // 'GREEN' | 'RED'
  final String symbol;
  final DateTime time;
  bool   dismissed;

  SharkAlert({
    required this.id, required this.title, required this.message,
    required this.color, required this.symbol, required this.time,
    this.dismissed = false,
  });

  Map toJson() => {
    'id': id, 't': title, 'm': message, 'c': color,
    's': symbol, 'ts': time.millisecondsSinceEpoch, 'd': dismissed,
  };
  factory SharkAlert.fromJson(Map j) => SharkAlert(
    id: j['id'], title: j['t'], message: j['m'], color: j['c'],
    symbol: j['s'] ?? '', time: DateTime.fromMillisecondsSinceEpoch(j['ts']),
    dismissed: j['d'] ?? false,
  );
  factory SharkAlert.fromApi(Map a) => SharkAlert(
    id: a['id'] ?? DateTime.now().millisecondsSinceEpoch,
    title: a['title'] ?? '',
    message: a['message'] ?? '',
    color: a['color'] ?? 'RED',
    symbol: _parseSymbol(a['message'] ?? ''),
    time: DateTime.now(),
  );

  static String _parseSymbol(String msg) {
    // Thử extract mã CP từ message (kiểu "... TCB trong ...")
    final r = RegExp(r'\b([A-Z]{3,4})\b');
    final m = r.firstMatch(msg);
    return m?.group(1) ?? '';
  }
}

// ─── History Provider ───────────────────────────────────────────────────────
class AlertHistoryNotifier extends StateNotifier<List<SharkAlert>> {
  AlertHistoryNotifier() : super([]) { _load(); }

  void _load() {
    try {
      final raw = Hive.box('app_data').get('shark_history', defaultValue: []) as List;
      state = raw.map((m) => SharkAlert.fromJson(Map.from(m))).toList();
    } catch (_) {}
  }

  void add(SharkAlert alert) {
    // Tránh duplicate
    if (state.any((a) => a.id == alert.id)) return;
    state = [alert, ...state].take(50).toList(); // giữ 50 alert gần nhất
    _save();
  }

  void dismiss(int id) {
    state = state.map((a) => a.id == id ? (a..dismissed = true) : a).toList();
    _save();
  }

  void clearAll() {
    state = [];
    _save();
  }

  void _save() {
    Hive.box('app_data').put('shark_history', state.map((a) => a.toJson()).toList());
  }
}

final alertHistoryProvider =
    StateNotifierProvider<AlertHistoryNotifier, List<SharkAlert>>(
        (_) => AlertHistoryNotifier());

// ─── Market Hours Check ─────────────────────────────────────────────────────
bool isMarketOpen() {
  final now = DateTime.now().toUtc().add(const Duration(hours: 7)); // GMT+7
  final wd  = now.weekday; // Mon=1 … Sun=7
  if (wd == 6 || wd == 7) return false; // Thứ 7, CN
  final h = now.hour, m = now.minute;
  final totalMin = h * 60 + m;
  // Sàn HOSE: 9:00–11:30 và 13:00–15:00
  return (totalMin >= 540 && totalMin <= 690) ||
         (totalMin >= 780 && totalMin <= 900);
}

// ─── Stream Provider ────────────────────────────────────────────────────────
const String _alertUrl = 'https://astraai-signals-api.onrender.com/api/v1/alerts/shark';

final shownAlertsProvider = StateProvider<Set<int>>((ref) => {});

final sharkAlertStreamProvider = StreamProvider<List<SharkAlert>>((ref) async* {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
  ));

  while (true) {
    if (!isMarketOpen()) {
      // Ngoài giờ giao dịch: báo trống, không gọi API
      yield [];
    } else {
      try {
        final response = await dio.get(_alertUrl);
        if (response.statusCode == 200) {
          final raw = response.data['alerts'] as List<dynamic>? ?? [];
          final alerts = raw.map((a) => SharkAlert.fromApi(Map.from(a))).toList();
          yield alerts;
        }
      } catch (_) {
        yield [];
      }
    }
    await Future.delayed(const Duration(seconds: 20));
  }
});
