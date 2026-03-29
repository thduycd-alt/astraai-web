import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/home_screen.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(); // Uncomment đoạn này sau khi connect Google Services Firebase.
  
  await Hive.initFlutter();
  await Hive.openBox('app_data'); // Hộp chứa Watchlist và Config
  
  runApp(
    const ProviderScope(
      child: AstraAISignalsApp(),
    ),
  );
}

class AstraAISignalsApp extends ConsumerWidget {
  const AstraAISignalsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(themeProvider);
    
    return MaterialApp(
      title: 'AstraAI Signals',
      theme: AppThemes.getTheme(currentThemeMode),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
