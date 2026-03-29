import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_treemap/treemap.dart';
import '../providers/market_provider.dart';
import '../services/api_service.dart';
import 'analysis_screen.dart';
import '../widgets/index_candle_chart.dart';

class MarketOverviewScreen extends ConsumerStatefulWidget {
  const MarketOverviewScreen({super.key});

  @override
  ConsumerState<MarketOverviewScreen> createState() => _MarketOverviewScreenState();
}

class _MarketOverviewScreenState extends ConsumerState<MarketOverviewScreen> {
  Timer? _sectorTimer;
  Timer? _marketTimer;
  String _lastUpdated = '';
  bool   _aiExpanded  = false;
  bool   _isWakingUp  = true;

  @override
  void initState() {
    super.initState();
    // Refresh Sector Flow mỗi 5 phút trong phiên giao dịch
    _sectorTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      ref.invalidate(sectorRotationProvider);
      setState(() => _lastUpdated = _nowTime());
    });
    // Refresh Market Overview mỗi 10 phút
    _marketTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      ref.invalidate(marketOverviewProvider);
    });
    _lastUpdated = _nowTime();
    // Wake-up ping cho Render free tier
    apiService.wakeUpServer().then((_) {
      if (mounted) setState(() => _isWakingUp = false);
    });
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) setState(() => _isWakingUp = false);
    });
  }

  @override
  void dispose() {
    _sectorTimer?.cancel();
    _marketTimer?.cancel();
    super.dispose();
  }

  String _nowTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}:${now.second.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    final marketAsyncValue   = ref.watch(marketOverviewProvider);
    final rotationAsyncValue = ref.watch(sectorRotationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Toàn cảnh thị trường',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: const Color(0xFF101015),
      ),
      backgroundColor: const Color(0xFF0A0A0E),
      body: Column(children: [
        // Banner đánh thức server Render
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _isWakingUp
            ? Container(
                key: const ValueKey('wakeup'),
                color: Colors.amber.withOpacity(0.12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: const Row(children: [
                  SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.amber)),
                  SizedBox(width: 10),
                  Expanded(child: Text('⚡ Đang đánh thức server (~30-60s lần đầu)...',
                    style: TextStyle(color: Colors.amber, fontSize: 11))),
                ]),
              )
            : const SizedBox.shrink(key: ValueKey('done')),
        ),
        Expanded(child: CustomScrollView(
        slivers: [
          // 1. Sector Rotation AI ALERT
          SliverToBoxAdapter(
            child: rotationAsyncValue.when(
              data: (data) {
                final alerts      = data['active_alerts'] as List<dynamic>? ?? [];
                final lastUpdated = data['last_updated'] as String? ?? _lastUpdated;
                final nextMin     = data['next_refresh_minutes'] as int? ?? 5;

                return Column(children: [
                  // Timestamp bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Row(children: [
                      const Icon(Icons.access_time_rounded, color: Colors.white24, size: 12),
                      const SizedBox(width: 4),
                      Text('Cập nhật lúc $lastUpdated • Tự động làm mới mỗi $nextMin phút',
                          style: const TextStyle(color: Colors.white24, fontSize: 10)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          ref.invalidate(sectorRotationProvider);
                          ref.invalidate(marketOverviewProvider);
                          setState(() => _lastUpdated = _nowTime());
                        },
                        child: const Row(children: [
                          Icon(Icons.refresh_rounded, color: Color(0xFF40C4FF), size: 13),
                          SizedBox(width: 3),
                          Text('Làm mới', style: TextStyle(color: Color(0xFF40C4FF), fontSize: 10)),
                        ]),
                      ),
                    ]),
                  ),
                  if (alerts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('AI: Không có lệnh luân chuyển dòng tiền đột biến.', style: TextStyle(color: Colors.white38, fontSize: 13)),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.15),
                          border: Border.all(color: Colors.redAccent, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.crisis_alert_rounded, color: Colors.orangeAccent, size: 28),
                              const SizedBox(width: 8),
                              Expanded(child: Text(alerts[0]['title'] ?? '',
                                  style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 16))),
                            ]),
                            const SizedBox(height: 8),
                            Text(alerts[0]['message'] ?? '',
                                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
                          ],
                        ),
                      ),
                    ),
                ]);
              },
              loading: () => const SizedBox.shrink(),
              error: (err, stack) => const SizedBox.shrink(),
            ),
          ),
          // 2. Chỉ số VNIndex, Heatmap Overview & Chart
          SliverToBoxAdapter(
            child: marketAsyncValue.when(
              data: (data) {
                final indexData = data['index'] ?? {};
                final heatmapList = data['heatmap'] as List<dynamic>? ?? [];
                final foreignList = data['foreign_flow'] as List<dynamic>? ?? [];
                final sectorList = data['sector_flow'] as List<dynamic>? ?? [];
                final aiEvaluation = data['ai_evaluation'] as String? ?? '';
                
                final double vnindex = (indexData['VNINDEX'] ?? 0).toDouble();
                final double change = (indexData['change'] ?? 0).toDouble();
                final double percentChange = (indexData['percent_change'] ?? 0).toDouble();
                final bool isUp = change >= 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Chỉ Số VNINDEX
                      Text(
                        'VNINDEX: $vnindex',
                        style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color: isUp ? const Color(0xFF69F0AE) : const Color(0xFFFF5252)),
                      ),
                      Text(
                        '${isUp ? "+" : ""}$change (${isUp ? "+" : ""}$percentChange%)',
                        style: TextStyle(fontSize: 22, color: isUp ? const Color(0xFF69F0AE) : const Color(0xFFFF5252)),
                      ),
                      const SizedBox(height: 14),
                      // ── Biểu Đồ Nến Chỉ Số ────────────────────────────────
                      const Align(alignment: Alignment.centerLeft,
                        child: Text('📈 Biểu Đồ Chỉ Số Thị Trường',
                          style: TextStyle(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.bold))),
                      const SizedBox(height: 6),
                      const IndexCandleChart(),
                      const SizedBox(height: 24),


                      
                      // Biểu Dồ Heatmap 14 Ngành
                      const Align(alignment: Alignment.centerLeft, child: Text('🔥 Dòng Tiền Phân Bổ Vốn Hóa (Heatmap)', style: TextStyle(color: Colors.orangeAccent, fontSize: 16, fontWeight: FontWeight.bold))),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        height: 350,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF101015),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: SfTreemap(
                          dataCount: heatmapList.length,
                          weightValueMapper: (int index) => (heatmapList[index]['value'] as num).toDouble(),
                          levels: [
                            TreemapLevel(
                              padding: const EdgeInsets.all(2),
                              groupMapper: (int index) => heatmapList[index]['symbol'],
                              colorValueMapper: (TreemapTile tile) {
                                return (heatmapList[tile.indices[0]]['percent_change'] as num).toDouble();
                              },
                              labelBuilder: (BuildContext context, TreemapTile tile) {
                                final symbol = tile.group;
                                final pct = (heatmapList[tile.indices[0]]['percent_change'] as num).toDouble();
                                return InkWell(
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => AnalysisScreen(symbol: symbol)));
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.white24, width: 0.5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(symbol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                        const SizedBox(height: 2),
                                        Text('${pct > 0 ? '+' : ''}$pct%', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                          ],
                          colorMappers: [
                            TreemapColorMapper.range(from: -15, to: -2, color: const Color(0xFFFF3D00)), // Đỏ đẫm
                            TreemapColorMapper.range(from: -2, to: -0.01, color: const Color(0xFFFF8A65)), // Đỏ nhạt
                            TreemapColorMapper.range(from: 0, to: 0, color: const Color(0xFF607D8B)), // Xám
                            TreemapColorMapper.range(from: 0.01, to: 2, color: const Color(0xFF81C784)), // Xanh nhạt
                            TreemapColorMapper.range(from: 2, to: 15, color: const Color(0xFF00E676)), // Xanh lá dạ quang
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // ── SECTOR FLOW — Horizontal Diverging Bar (Bloomberg style) ──
                      Row(children: [
                        const Icon(Icons.waterfall_chart, color: Color(0xFF40C4FF), size: 18),
                        const SizedBox(width: 8),
                        const Text('LUÂN CHUYỂN DÒNG TIỀN NGÀNH',
                          style: TextStyle(color: Color(0xFF40C4FF), fontSize: 13,
                              fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Flow Index', style: TextStyle(color: Colors.white38, fontSize: 9)),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      // Legend
                      Row(children: [
                        Container(width: 12, height: 3, color: const Color(0xFF26C6A6)),
                        const SizedBox(width: 4),
                        const Text('Dòng tiền vào', style: TextStyle(color: Colors.white38, fontSize: 9)),
                        const SizedBox(width: 14),
                        Container(width: 12, height: 3, color: const Color(0xFFEF5350)),
                        const SizedBox(width: 4),
                        const Text('Dòng tiền ra', style: TextStyle(color: Colors.white38, fontSize: 9)),
                      ]),
                      const SizedBox(height: 10),
                      // Custom Diverging Bars
                      ...() {
                        if (sectorList.isEmpty) return [const SizedBox.shrink()];
                        // Sắp xếp theo flow_index giảm dần
                        final sorted = List<dynamic>.from(sectorList)
                          ..sort((a, b) => (b['flow_index'] as num).compareTo(a['flow_index'] as num));
                        final maxAbs = sorted.fold<double>(0.0, (m, d) => (d['flow_index'] as num).abs() > m ? (d['flow_index'] as num).abs().toDouble() : m);
                        return sorted.map<Widget>((sector) {
                          final name   = sector['sector']?.toString().replaceAll('_', ' ') ?? '';
                          final flow   = (sector['flow_index'] as num).toDouble();
                          final status = sector['status'] ?? '';
                          final isPos  = flow >= 0;
                          final barPct = maxAbs > 0 ? (flow.abs() / maxAbs) : 0.0;
                          final barColor = isPos ? const Color(0xFF26C6A6) : const Color(0xFFEF5350);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Label row
                                Row(children: [
                                  SizedBox(width: 100,
                                    child: Text(name, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis)),
                                  Expanded(child: LayoutBuilder(builder: (ctx, cst) {
                                    final fullW = cst.maxWidth;
                                    final barW  = fullW * barPct * 0.85;
                                    return Row(children: [
                                      // Đường zero center
                                      SizedBox(width: fullW * 0.5,
                                        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                                          if (!isPos) AnimatedContainer(
                                            duration: const Duration(milliseconds: 600),
                                            curve: Curves.easeOutCubic,
                                            width: barW,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: barColor.withOpacity(0.85),
                                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(3)),
                                            ),
                                          ),
                                          Container(width: 2, height: 16, color: Colors.white24),
                                        ]),
                                      ),
                                      if (isPos) AnimatedContainer(
                                        duration: const Duration(milliseconds: 600),
                                        curve: Curves.easeOutCubic,
                                        width: barW,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: barColor.withOpacity(0.85),
                                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${isPos ? '+' : ''}${flow.toStringAsFixed(1)}',
                                        style: TextStyle(color: barColor, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ]);
                                  })),
                                ]),
                                if (status.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 100, top: 1),
                                    child: Text(status, style: const TextStyle(color: Colors.white30, fontSize: 9),
                                      overflow: TextOverflow.ellipsis),
                                  ),
                              ],
                            ),
                          );
                        }).toList();
                      }(),
                      
                      const SizedBox(height: 40),
                      
                      // Biểu Đồ Foreign Flow
                      const Align(alignment: Alignment.centerLeft, child: Text('🐋 Lực Nhóm Cá Mập & Khối Ngoại', style: TextStyle(color: Colors.cyanAccent, fontSize: 16, fontWeight: FontWeight.bold))),
                      const SizedBox(height: 10),
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          color: const Color(0xFF101015),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: SfCartesianChart(
                          legend: const Legend(isVisible: true, position: LegendPosition.bottom),
                          primaryXAxis: const CategoryAxis(
                            majorGridLines: MajorGridLines(width: 0),
                            labelStyle: TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                          primaryYAxis: const NumericAxis(
                            majorGridLines: MajorGridLines(width: 0.5, color: Colors.white12),
                            labelStyle: TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                          series: <CartesianSeries<dynamic, String>>[
                            ColumnSeries<dynamic, String>(
                              name: 'Khối Ngoại Mua (Tỷ VNĐ)',
                              dataSource: foreignList,
                              xValueMapper: (data, _) => data['time'],
                              yValueMapper: (data, _) => data['foreign_buy'],
                              color: const Color(0xFF69F0AE).withOpacity(0.7),
                            ),
                            ColumnSeries<dynamic, String>(
                              name: 'Khối Ngoại Bán',
                              dataSource: foreignList,
                              xValueMapper: (data, _) => data['time'],
                              yValueMapper: (data, _) => -data['foreign_sell'],
                              color: const Color(0xFFFF5252).withOpacity(0.7),
                            ),
                            LineSeries<dynamic, String>(
                              name: 'Tự Doanh Mua',
                              dataSource: foreignList,
                              xValueMapper: (data, _) => data['time'],
                              yValueMapper: (data, _) => data['prop_buy'],
                              color: Colors.orangeAccent,
                              width: 3,
                              markerSettings: const MarkerSettings(isVisible: true),
                            ),
                          ],
                        ),
                      ),
                      // ── AI ĐÁNH GIÁ (collapsible, đặt cuối trang) ──────────
                      const SizedBox(height: 28),
                      if (aiEvaluation.isNotEmpty)
                        GestureDetector(
                          onTap: () => setState(() => _aiExpanded = !_aiExpanded),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF13141A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.purpleAccent.withOpacity(0.35)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  const Icon(Icons.smart_toy_rounded, color: Colors.purpleAccent, size: 16),
                                  const SizedBox(width: 8),
                                  const Expanded(child: Text('🤖 AI Đánh Giá Toàn Cảnh',
                                      style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 13))),
                                  Icon(_aiExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                      color: Colors.purpleAccent, size: 18),
                                ]),
                                const SizedBox(height: 8),
                                if (!_aiExpanded) ...[
                                  Text(
                                    aiEvaluation.length > 120
                                        ? '${aiEvaluation.substring(0, 120).replaceAll('**', '')}...'
                                        : aiEvaluation.replaceAll('**', ''),
                                    style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.45),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text('Xem thêm →', style: TextStyle(color: Colors.purpleAccent, fontSize: 11)),
                                ] else ...[
                                  Text(
                                    aiEvaluation.replaceAll('**', ''),
                                    style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text('Thu gọn ↑', style: TextStyle(color: Colors.purpleAccent, fontSize: 11)),
                                ],
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(50.0),
                child: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
              ),
              error: (err, stack) => Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text('Lỗi tải dữ liệu Index: $err', style: const TextStyle(color: Colors.red)),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 50),
          )
        ],
      )),  // closes CustomScrollView, Expanded
    ]),   // closes Column children list
  );    // closes Scaffold
  }
}
