import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/api_service.dart';
import '../providers/theme_provider.dart';
import '../providers/alert_provider.dart';
import 'analysis_screen.dart';
import 'market_overview_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController searchController = TextEditingController();
  final Box appDataBox = Hive.box('app_data');
  Map<String, dynamic> _quotes = {};
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchLiveQuotes();
    // Khởi động Hyperspeed Background Poller mỗi 3 giây cho Lưới Watchlist
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchLiveQuotes();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveQuotes() async {
    final watchlist = getWatchlist();
    if (watchlist.isEmpty) return;
    try {
      final data = await apiService.getWatchlistQuotes(watchlist);
      if (mounted) {
        setState(() {
          _quotes = data;
        });
      }
    } catch (e) {
      debugPrint("Quote polling error: $e");
    }
  }

  List<String> getWatchlist() {
    final list = appDataBox.get('watchlist_symbols', defaultValue: <String>[]);
    return List<String>.from(list);
  }

  void addSymbol(String symbol) {
    if (symbol.isEmpty) return;
    symbol = symbol.trim().toUpperCase();
    final list = getWatchlist();
    if (!list.contains(symbol)) {
      list.insert(0, symbol); // Thêm lên đầu danh sách
      appDataBox.put('watchlist_symbols', list);
      _fetchLiveQuotes();
    }
    searchController.clear();
  }

  void removeSymbol(String symbol) {
    final list = getWatchlist();
    list.remove(symbol);
    appDataBox.put('watchlist_symbols', list);
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe luồng cảnh báo Cá Mập
    ref.listen<AsyncValue<List<dynamic>>>(sharkAlertStreamProvider, (previous, next) {
      if (next is AsyncData && next.value != null && next.value!.isNotEmpty) {
        final newAlerts = next.value!;
        final shownAlerts = ref.read(shownAlertsProvider);
        
        for (var alert in newAlerts) {
          final int id = alert['id'];
          if (!shownAlerts.contains(id)) {
            // Đánh dấu đã hiển thị
            ref.read(shownAlertsProvider.notifier).state = {...shownAlerts, id};
            
            // Bắn Còi Báo Động (Snackbar)
            final bool isGreen = alert['color'] == 'GREEN';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: isGreen ? const Color(0xFF00E676) : const Color(0xFFFF3D00),
                duration: const Duration(seconds: 6),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height - 150, left: 16, right: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                dismissDirection: DismissDirection.up,
                content: Row(
                  children: [
                    const Icon(Icons.crisis_alert_rounded, color: Colors.black87, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(alert['title'], style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(alert['message'], style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.2)),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            );
          }
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Sàn Chỉ Huy AstraAI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Theme.of(context).appBarTheme.foregroundColor)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          PopupMenuButton<AppThemeMode>(
            icon: const Icon(Icons.palette_rounded, color: Colors.purpleAccent),
            tooltip: 'Chọn Giao Diện',
            onSelected: (AppThemeMode mode) {
              ref.read(themeProvider.notifier).setTheme(mode);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<AppThemeMode>>[
              const PopupMenuItem<AppThemeMode>(value: AppThemeMode.nightPro, child: Text('🌙 Night Pro')),
              const PopupMenuItem<AppThemeMode>(value: AppThemeMode.lightClassic, child: Text('☀️ Light Classic')),
              const PopupMenuItem<AppThemeMode>(value: AppThemeMode.matrixNeon, child: Text('💻 Matrix Neon')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.dashboard_customize_rounded, color: Colors.cyanAccent),
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const MarketOverviewScreen())
              );
            },
          )
        ]
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Thanh Thêm Mã Mới (Search Bar)
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1))
            ),
            child: Row(
               children: [
                 Expanded(
                   child: TextField(
                     controller: searchController,
                     textCapitalization: TextCapitalization.characters,
                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                     decoration: InputDecoration(
                       hintText: 'Nhập mã cổ phiếu (VD: HPG, VHM)...',
                       hintStyle: const TextStyle(fontWeight: FontWeight.normal, color: Colors.grey, fontSize: 14),
                       prefixIcon: const Icon(Icons.search_rounded, color: Colors.cyanAccent),
                       filled: true,
                       fillColor: Colors.grey.withOpacity(0.1),
                       contentPadding: const EdgeInsets.symmetric(vertical: 14),
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                     ),
                     onSubmitted: (value) => addSymbol(value),
                   ),
                 ),
                 const SizedBox(width: 12),
                 Container(
                   decoration: const BoxDecoration(
                     shape: BoxShape.circle,
                     color: Colors.cyanAccent,
                   ),
                   child: IconButton(
                     icon: const Icon(Icons.add_rounded, color: Colors.black, size: 28),
                     onPressed: () => addSymbol(searchController.text),
                   ),
                 )
               ],
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Lưới Theo Dõi Dòng Tiền (Watchlist)',
                style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Lưới Watchlist (Grid View)
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: appDataBox.listenable(keys: ['watchlist_symbols']),
              builder: (context, Box box, _) {
                final watchlist = getWatchlist();

                if (watchlist.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'Lưới Chỉ Huy đang trống.\nHãy tìm và lưu mã cổ phiếu để AI bắt đầu quét Dòng tiền Cá mập!',
                        textAlign: TextAlign.center, 
                        style: TextStyle(color: Colors.white30, fontSize: 16, height: 1.5)
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 cột trên điện thoại
                    childAspectRatio: 1.4, // Tỷ lệ thẻ
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: watchlist.length,
                  itemBuilder: (context, index) {
                    final sym = watchlist[index];
                    final quote = _quotes[sym];
                    final double price = (quote?['price'] ?? 0).toDouble();
                    final double pct = (quote?['pct_change'] ?? 0).toDouble();
                    final bool isUp = pct > 0;
                    final bool isDown = pct < 0;
                    final Color color = isUp ? Colors.greenAccent : (isDown ? Colors.redAccent : Colors.orangeAccent);

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AnalysisScreen(symbol: sym)),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withOpacity(0.1)),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, offset: Offset(0, 4), blurRadius: 6)
                          ]
                        ),
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(sym, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87)),
                                  const SizedBox(height: 8),
                                  if (price > 0)
                                    Row(
                                      children: [
                                        Text('$price', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                                          child: Text('${isUp ? '+' : ''}$pct%', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                                        )
                                      ],
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orangeAccent.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8)
                                      ),
                                      child: const Text('Đang Sync Giá...', style: TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold))
                                    )
                                ],
                              ),
                            ),
                            Positioned(
                              right: 2,
                              top: 2,
                              child: IconButton(
                                icon: const Icon(Icons.close_rounded, color: Colors.white30, size: 20),
                                onPressed: () => removeSymbol(sym),
                              ),
                            ),
                            const Positioned(
                              right: 16,
                              bottom: 16,
                              child: Icon(Icons.show_chart_rounded, color: Colors.white12, size: 40)
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
