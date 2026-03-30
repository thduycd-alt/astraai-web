import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../providers/stock_provider.dart';
import '../models/analysis_result.dart';
import '../widgets/layer_card.dart';
import '../widgets/intraday_chart.dart';
import '../widgets/comment_section.dart';
import '../widgets/financial_calendar_card.dart';
import '../widgets/valuation_panel.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  final String symbol;

  const AnalysisScreen({super.key, required this.symbol});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  Timer? _refreshTimer;

  /// Trả về true nếu đang trong giờ giao dịch VN (T2-T7, 9:00-11:30 và 13:00-15:00)
  bool _isTradingHours() {
    final now = DateTime.now();
    if (now.weekday > 6) return false; // Chủ nhật
    final h = now.hour;
    final m = now.minute;
    if (h == 9 || h == 10 || (h == 11 && m <= 30)) return true;
    if (h == 13 || h == 14 || (h == 15 && m == 0)) return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    // Auto-refresh mỗi 3 phút trong phiên giao dịch
    _refreshTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      if (_isTradingHours() && mounted) {
        ref.invalidate(stockAnalysisProvider(widget.symbol));
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final symbol = widget.symbol;
    final analysisAsyncValue = ref.watch(stockAnalysisProvider(symbol));
    final box = Hive.box('app_data');

    return Scaffold(
      appBar: AppBar(
        title: const Text('AstraAI Siêu Tâm', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A1A1A),
        actions: [
          ValueListenableBuilder(
            valueListenable: box.listenable(keys: ['watchlist_symbols']),
            builder: (context, Box b, _) {
              final list = List<String>.from(b.get('watchlist_symbols', defaultValue: <String>[]));
              final isBookmarked = list.contains(symbol);
              
              return IconButton(
                icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border, color: Colors.orangeAccent, size: 28),
                tooltip: 'Thêm vào Danh mục',
                onPressed: () {
                  if (isBookmarked) {
                    list.remove(symbol);
                  } else {
                    list.insert(0, symbol);
                  }
                  b.put('watchlist_symbols', list);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(isBookmarked ? 'Đã xóa $symbol khỏi Theo dõi' : 'Đã thêm $symbol vào Danh Mục!', style: const TextStyle(color: Colors.white)),
                    backgroundColor: Colors.deepPurple,
                    duration: const Duration(seconds: 1),
                  ));
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.smart_toy_rounded, color: Colors.purpleAccent, size: 28),
            tooltip: 'Hỏi AI Chatbot RAG',
            onPressed: () {
              // Route to Chat Bot AI
            },
          )
        ],
      ),
      backgroundColor: const Color(0xFF0A0A0E), // Ultra dark background matches Home Screen
      body: analysisAsyncValue.when(
        data: (result) => RefreshIndicator(
          onRefresh: () => ref.refresh(stockAnalysisProvider(symbol).future),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                
                // Mới: Bảng Header Cổ Phiếu Tức Thời (Realtime Mobile View)
                if (result.tickerInfo != null)
                  TickerInfoHeader(info: result.tickerInfo!),

                if (result.valuationMetrics != null)
                  ValuationPanel(metrics: result.valuationMetrics!),

                if (result.v4Metrics != null)
                  V4MetricsPanel(metrics: result.v4Metrics!),

                // Component Biểu Đồ Nến Thực Chiến V3
                if (result.chartData.isNotEmpty)
                  IntradayChart(symbol: symbol, initialChartData: result.chartData, v4Metrics: result.v4Metrics)
                else
                  const Padding(padding: EdgeInsets.all(20), child: Text("Đang tải dữ liệu biểu đồ...", style: TextStyle(color: Colors.grey))),
                
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))]
                  ),
                  child: Column(
                    children: [
                      const Text('TỔNG ĐIỂM ASTRA-AI', style: TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      const SizedBox(height: 8),
                      Text(
                        '${result.finalScore}',
                        style: TextStyle(
                          fontSize: 64, 
                          fontWeight: FontWeight.w900,
                          color: result.finalScore >= 70 ? const Color(0xFF00E676) : (result.finalScore < 40 ? const Color(0xFFFF3D00) : Colors.amberAccent),
                          height: 1.1,
                          letterSpacing: -2.0
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                           color: (result.finalScore >= 70 ? const Color(0xFF00E676) : (result.finalScore < 40 ? const Color(0xFFFF3D00) : Colors.amberAccent)).withOpacity(0.15),
                           borderRadius: BorderRadius.circular(20)
                        ),
                        child: Text(
                          result.finalScore >= 70 ? 'MẠNH MẼ MUA' : (result.finalScore < 40 ? 'BÁN QUYẾT LIỆT' : 'NẮM GIỮ / QUAN SÁT'),
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: result.finalScore >= 70 ? const Color(0xFF00E676) : (result.finalScore < 40 ? const Color(0xFFFF3D00) : Colors.amberAccent),
                          ),
                        ),
                      )
                    ]
                  )
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                  child: Text(
                    result.recommendation,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w500, height: 1.6, fontStyle: FontStyle.italic),
                  ),
                ),
                const SizedBox(height: 10),
                
                // Hiển thị động 7 Tầng Sâu từ AI Backend
                if (result.layerList.isNotEmpty)
                  ..._buildLayerCards(result.layerList)
                else
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('AI không phản hồi đủ dữ liệu để xây dựng 7 tầng.', style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)),
                  ),
                const SizedBox(height: 20),

                // Tầng 8: Lịch Sự Kiện Tài Chính
                if (result.financialCalendar != null)
                  FinancialCalendarCard(calendar: result.financialCalendar!),

                const SizedBox(height: 20),
                CommentSection(symbol: symbol),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.deepPurpleAccent),
              const SizedBox(height: 16),
              Text(
                'AstraAI đang phân tích $symbol...\n⏳ Lần đầu mất 30-60 giây (server khởi động)',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.cloud_off_rounded, color: Colors.white24, size: 56),
              const SizedBox(height: 16),
              const Text('Không kết nối được server',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              const Text(
                'Server có thể đang khởi động lại (30-60 giây).\nVui lòng thử lại.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, height: 1.5, fontSize: 13)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6200EA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => ref.invalidate(stockAnalysisProvider(symbol)),
              ),
            ]),
          ),
        ),
      ),
    );
  }


  List<Widget> _buildLayerCards(List<LayerInfo> layers) {
    try {
      return layers
        .where((layer) => layer.content.isNotEmpty)
        .map((layer) => LayerCard(
          title: layer.title,
          content: layer.content,
          statusColor: _hexToColor(layer.colorHex),
        ))
        .toList();
    } catch (e) {
      return [const Padding(
        padding: EdgeInsets.all(20),
        child: Text('Đang tổng hợp 8 tầng phân tích...', style: TextStyle(color: Colors.white54)),
      )];
    }
  }

  Color _hexToColor(String hexString) {
    if (hexString.isEmpty) return const Color(0xFF448AFF);
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch(e) {
      return const Color(0xFF448AFF); // Tránh văng app (Màn hình xám) nếu AI sinh lỗi mã màu
    }
  }
}

class TickerInfoHeader extends StatelessWidget {
  final TickerInfo info;
  const TickerInfoHeader({super.key, required this.info});

  String _formatNumber(num value) {
    String str = value.toStringAsFixed(2);
    if (str.endsWith('.00')) str = str.substring(0, str.length - 3);
    List<String> parts = str.split('.');
    parts[0] = parts[0].replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    return parts.join('.');
  }

  @override
  Widget build(BuildContext context) {
    final isUp = info.change >= 0;
    final color = isUp ? const Color(0xFF00E676) : const Color(0xFFFF3D00); // Vibrant Binance Green/Red
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF13141C),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(info.symbol, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text(info.companyName, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_formatNumber(info.price), style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10)
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: color, size: 14),
                        const SizedBox(width: 4),
                        Text('${info.change} (${info.pctChange}%)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1, color: Colors.white.withOpacity(0.08)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStat("Khối lượng (Live)", "${_formatNumber(info.volume/1000)}K"),
              _buildStat("Giá trị (VNĐ)", "${_formatNumber(info.valueBil)} Tỷ"),
              _buildStat("Khối Ngoại Mua", "${_formatNumber(info.foreignBuyBil)} Tỷ", const Color(0xFF00E676)),
              _buildStat("Khối Ngoại Bán", "${_formatNumber(info.foreignSellBil)} Tỷ", const Color(0xFFFF3D00)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, [Color? valColor]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: valColor ?? Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class V4MetricsPanel extends StatelessWidget {
  final V4Metrics metrics;
  const V4MetricsPanel({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF13141C),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE040FB).withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE040FB).withOpacity(0.08), 
            blurRadius: 20, 
            spreadRadius: 2
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE040FB).withOpacity(0.2),
                  shape: BoxShape.circle
                ),
                child: const Icon(Icons.psychology_rounded, color: Color(0xFFE040FB), size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'ASTRA-AI V4 ELITE: ĐỌC VỊ BÓNG CÁ MẬP', 
                style: TextStyle(color: Color(0xFFE040FB), fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Hành vi Cầm trịch (Whale Shadowing)', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
          const SizedBox(height: 6),
          Text(metrics.whaleStyle, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, height: 1.4)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tọa Độ Nén Giá AI', style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
              Text('${metrics.compressionScore}% LỰC BẬT', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: metrics.compressionScore / 100.0,
              minHeight: 12,
              backgroundColor: Colors.white.withOpacity(0.05),
              valueColor: AlwaysStoppedAnimation<Color>(
                metrics.compressionScore >= 70 ? const Color(0xFF00E676) : (metrics.compressionScore < 40 ? const Color(0xFFFF3D00) : Colors.amberAccent)
              ),
            ),
          )
        ],
      ),
    );
  }
}

class ValuationPanel extends StatelessWidget {
  final ValuationMetrics metrics;
  const ValuationPanel({super.key, required this.metrics});

  String _formatNumber(num value) {
    String str = value.toStringAsFixed(2);
    if (str.endsWith('.00')) str = str.substring(0, str.length - 3);
    List<String> parts = str.split('.');
    parts[0] = parts[0].replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    return parts.join('.');
  }

  @override
  Widget build(BuildContext context) {
    final upside = metrics.upside;
    final isUndervalued = upside > 0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isUndervalued 
            ? [const Color(0xFF004D40), const Color(0xFF13141C)] 
            : [const Color(0xFF3E2723), const Color(0xFF13141C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isUndervalued ? const Color(0xFF00E676).withOpacity(0.5) : const Color(0xFFFF3D00).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet, color: isUndervalued ? const Color(0xFF00E676) : const Color(0xFFFF3D00), size: 20),
              const SizedBox(width: 8),
              Text('Định giá theo phương pháp Tầm soát cổ phiếu', style: TextStyle(color: isUndervalued ? const Color(0xFF00E676) : const Color(0xFFFF3D00), fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Giá Trị Thực Minh Bạch', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(_formatNumber(metrics.fairValue), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Biên An Toàn (Upside)', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isUndervalued ? const Color(0xFF00E676).withOpacity(0.2) : const Color(0xFFFF3D00).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8)
                    ),
                    child: Text('${upside > 0 ? "+" : ""}$upside%', style: TextStyle(color: isUndervalued ? const Color(0xFF00E676) : const Color(0xFFFF3D00), fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Giá Mục Tiêu CTCK (Tham khảo):', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
              Text(_formatNumber(metrics.referencePrice), style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text('💡 Định Giá Tầm Soát: [ EPS (${_formatNumber(metrics.eps)}) x ${metrics.pe} (P/E chuẩn Ngành) ] \nCổ phiếu được chiết khấu theo nguyên lý P/E tương lai kỳ vọng, nhằm tìm ra được giá trị tĩnh cốt lõi mà không bị ảnh hưởng bởi tâm lý Mua Bán hoảng loạn trên bảng điện.', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontStyle: FontStyle.italic, height: 1.5)),
          const SizedBox(height: 12),
          Container(
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: const Color(0xFF448AFF).withOpacity(0.1),
               borderRadius: BorderRadius.circular(8),
               border: Border.all(color: const Color(0xFF448AFF).withOpacity(0.3))
             ),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 const Row(
                   children: [
                     Icon(Icons.auto_awesome, color: Color(0xFF448AFF), size: 16),
                     SizedBox(width: 6),
                     Text('ASTRA-AI FORWARD EPS RAG', style: TextStyle(color: Color(0xFF448AFF), fontWeight: FontWeight.bold, fontSize: 11))
                   ]
                 ),
                 const SizedBox(height: 6),
                 Text(metrics.aiReasoning, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.5))
               ]
             )
          )
        ],
      ),
    );
  }
}
