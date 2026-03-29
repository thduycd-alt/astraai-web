import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum AppThemeMode {
  nightPro,
  lightClassic,
  matrixNeon
}

class ThemeNotifier extends StateNotifier<AppThemeMode> {
  ThemeNotifier() : super(AppThemeMode.nightPro) {
    _loadTheme();
  }

  void _loadTheme() {
    final box = Hive.box('app_data');
    final savedTheme = box.get('selected_theme', defaultValue: 'nightPro');
    if (savedTheme == 'lightClassic') state = AppThemeMode.lightClassic;
    else if (savedTheme == 'matrixNeon') state = AppThemeMode.matrixNeon;
    else state = AppThemeMode.nightPro;
  }

  void setTheme(AppThemeMode mode) {
    if (state != mode) {
      state = mode;
      Hive.box('app_data').put('selected_theme', mode.name);
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  return ThemeNotifier();
});

class AppThemes {
  static ThemeData getTheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.lightClassic:
        return ThemeData.light().copyWith(
          primaryColor: const Color(0xFF2962FF),
          scaffoldBackgroundColor: const Color(0xFFF5F6FA),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFFFFFFF),
            foregroundColor: Colors.black87,
            elevation: 1,
            centerTitle: true,
          ),
          cardColor: Colors.white,
        );
      
      case AppThemeMode.matrixNeon:
        return ThemeData.dark().copyWith(
          primaryColor: const Color(0xFF00E676),
          scaffoldBackgroundColor: const Color(0xFF050A05),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF021002),
            foregroundColor: Color(0xFF00E676),
            elevation: 0,
            centerTitle: true,
          ),
          cardColor: const Color(0xFF051205),
        );
        
      case AppThemeMode.nightPro:
      default:
        return ThemeData.dark().copyWith(
          primaryColor: const Color(0xFF6200EA),
          scaffoldBackgroundColor: const Color(0xFF0A0A0E),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF101015),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          cardColor: const Color(0xFF13141C),
        );
    }
  }
}
