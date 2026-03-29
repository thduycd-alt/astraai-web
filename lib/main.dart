import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/market_overview_screen.dart';
import 'screens/screener_screen.dart';
import 'screens/portfolio_screen.dart';
import 'screens/price_alert_screen.dart';
import 'screens/analysis_screen.dart';
import 'services/fcm_service.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase init với config chính xác từ Firebase Console
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Background FCM handler (top-level, bắt buộc)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await Hive.initFlutter();
  await Hive.openBox('app_data');

  runApp(const ProviderScope(child: AstraAISignalsApp()));
}

class AstraAISignalsApp extends ConsumerWidget {
  const AstraAISignalsApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(themeProvider);
    return MaterialApp(
      title: 'AstraAI Signals',
      theme: AppThemes.getTheme(currentThemeMode),
      home: const _MainShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _MainShell extends StatefulWidget {
  const _MainShell();
  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _initFCM();
  }

  Future<void> _initFCM() async {
    fcmService.onNavigateToStock = (symbol) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => AnalysisScreen(symbol: symbol),
      ));
    };
    await fcmService.initialize();
  }

  static const _screens = [
    HomeScreen(),
    MarketOverviewScreen(),
    ScreenerScreen(),
    PortfolioScreen(),
    PriceAlertScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: _AstraBottomNav(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

class _AstraBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _AstraBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(icon: Icons.home_rounded,                   label: 'Trang chủ'),
      _NavItem(icon: Icons.bar_chart_rounded,              label: 'Toàn cảnh'),
      _NavItem(icon: Icons.search_rounded,                 label: 'Screener'),
      _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Danh mục'),
      _NavItem(icon: Icons.notifications_rounded,          label: 'Alert'),
    ];

    return Container(
      height: 66,
      decoration: BoxDecoration(
        color: const Color(0xFF13141C),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 16)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final selected = i == currentIndex;
          final color    = selected ? const Color(0xFFB2FF59) : Colors.white30;
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFB2FF59).withOpacity(0.08) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(items[i].icon, color: color, size: 22),
                const SizedBox(height: 3),
                Text(items[i].label, style: TextStyle(color: color, fontSize: 9.5,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
              ]),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
