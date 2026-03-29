import 'dart:async';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../models/analysis_result.dart';
import '../services/api_service.dart';

/// Biểu đồ nến chỉ số thị trường: VNINDEX / HNXINDEX / UPCOMINDEX
/// FireAnt style — OHLCV header + candle + volume panel
class IndexCandleChart extends StatefulWidget {
  const IndexCandleChart({super.key});

  @override
  State<IndexCandleChart> createState() => _IndexCandleChartState();
}

class _IndexCandleChartState extends State<IndexCandleChart> {
  String _selectedIndex = 'VNINDEX';
  String _selectedTf    = '1D';
  bool _isLoading       = false;
  List<RawChartData> _data = [];

  // OHLCV hover
  double? _hO, _hH, _hL, _hC, _hV;

  static const _indices = ['VNINDEX', 'HNXIndex', 'UPCOM', 'VN30'];
  static const _tfOptions = ['1M', '3M', '6M', '1Y'];
  static const _tfDays = {'1M': 30, '3M': 60, '6M': 120, '1Y': 120};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await apiService.getIndexCandles(
        _selectedIndex, _tfDays[_selectedTf] ?? 60,
      );
      if (mounted) setState(() { _data = res; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _fmt(double v) {
    if (v >= 1000) return v.toStringAsFixed(2);
    return v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final latest = _data.isNotEmpty ? _data.last : null;
    final dO = _hO ?? latest?.open   ?? 0;
    final dH = _hH ?? latest?.high   ?? 0;
    final dL = _hL ?? latest?.low    ?? 0;
    final dC = _hC ?? latest?.close  ?? 0;
    final dV = _hV ?? latest?.volume ?? 0;
    final isBull  = dC >= dO;
    final clr     = isBull ? const Color(0xFF26C6A6) : const Color(0xFFEF5350);

    double maxVol = 1;
    for (var d in _data) { if (d.volume > maxVol) maxVol = d.volume; }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0D12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Toolbar ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(children: [
              // Index selector
              _SegmentPicker(
                options: _indices,
                selected: _selectedIndex,
                onTap: (v) { setState(() => _selectedIndex = v); _load(); },
                activeColor: const Color(0xFFFFD740),
              ),
              const Spacer(),
              // Timeframe selector
              _SegmentPicker(
                options: _tfOptions,
                selected: _selectedTf,
                onTap: (v) { setState(() => _selectedTf = v); _load(); },
                activeColor: const Color(0xFF1D6FE8),
              ),
            ]),
          ),

          // ── OHLCV Bar ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: Wrap(spacing: 14, children: [
              _OHLCVLabel('O', _fmt(dO), clr),
              _OHLCVLabel('H', _fmt(dH), const Color(0xFF26C6A6)),
              _OHLCVLabel('L', _fmt(dL), const Color(0xFFEF5350)),
              _OHLCVLabel('C', _fmt(dC), clr),
              if (dO > 0) _OHLCVLabel(
                isBull ? '▲' : '▼',
                '${((dC - dO) / dO * 100).toStringAsFixed(2)}%',
                clr,
              ),
            ]),
          ),

          Divider(height: 1, color: Colors.white.withOpacity(0.06)),

          // ── Price Chart ──────────────────────────────────────────────────
          if (_isLoading)
            const SizedBox(height: 260,
              child: Center(child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF1D6FE8))))
          else if (_data.isEmpty)
            const SizedBox(height: 260,
              child: Center(child: Text('Không có dữ liệu chỉ số', style: TextStyle(color: Colors.white38))))
          else
            SizedBox(
              height: 260,
              child: SfCartesianChart(
                margin: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                plotAreaBorderWidth: 0,
                backgroundColor: Colors.transparent,
                crosshairBehavior: CrosshairBehavior(
                  enable: true,
                  lineType: CrosshairLineType.both,
                  lineColor: Colors.white24,
                  lineWidth: 1,
                  lineDashArray: [4, 4],
                  activationMode: ActivationMode.singleTap,
                ),
                zoomPanBehavior: ZoomPanBehavior(
                  enablePinching: true, enablePanning: true, zoomMode: ZoomMode.x,
                ),
                primaryXAxis: CategoryAxis(
                  labelStyle: const TextStyle(color: Colors.white38, fontSize: 9),
                  axisLine: const AxisLine(width: 0),
                  majorGridLines: const MajorGridLines(width: 0.4, color: Color(0xFF1E2130), dashArray: [4,4]),
                  majorTickLines: const MajorTickLines(size: 0),
                  autoScrollingDelta: 60,
                  autoScrollingMode: AutoScrollingMode.end,
                ),
                primaryYAxis: NumericAxis(
                  name: 'priceAxis',
                  opposedPosition: true,
                  axisLine: const AxisLine(width: 0),
                  majorTickLines: const MajorTickLines(size: 0),
                  majorGridLines: const MajorGridLines(width: 0.4, color: Color(0xFF1E2130), dashArray: [4,4]),
                  labelStyle: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
                indicators: <TechnicalIndicator<RawChartData, String>>[
                  EmaIndicator<RawChartData, String>(
                    seriesName: 'index', period: 20,
                    signalLineColor: const Color(0xFF40C4FF), signalLineWidth: 1.2,
                  ),
                  EmaIndicator<RawChartData, String>(
                    seriesName: 'index', period: 50,
                    signalLineColor: const Color(0xFFFFD740), signalLineWidth: 1.2,
                  ),
                ],
                series: <CartesianSeries<RawChartData, String>>[
                  CandleSeries<RawChartData, String>(
                    dataSource: _data,
                    name: 'index',
                    xValueMapper:   (d, _) => d.time.toString().substring(0, 10),
                    lowValueMapper:   (d, _) => d.low,
                    highValueMapper:  (d, _) => d.high,
                    openValueMapper:  (d, _) => d.open,
                    closeValueMapper: (d, _) => d.close,
                    bearColor: const Color(0xFFEF5350),
                    bullColor: const Color(0xFF26C6A6),
                    enableSolidCandles: true,
                    borderWidth: 0.5,
                    onPointTap: (args) {
                      final i = args.pointIndex ?? 0;
                      if (i < _data.length) {
                        final d = _data[i];
                        setState(() { _hO=d.open; _hH=d.high; _hL=d.low; _hC=d.close; _hV=d.volume; });
                      }
                    },
                  ),
                ],
              ),
            ),

          Divider(height: 1, color: Colors.white.withOpacity(0.06)),

          // ── Volume ────────────────────────────────────────────────────────
          SizedBox(
            height: 50,
            child: SfCartesianChart(
              margin: const EdgeInsets.fromLTRB(0, 2, 0, 2),
              plotAreaBorderWidth: 0,
              backgroundColor: Colors.transparent,
              primaryXAxis: CategoryAxis(isVisible: false,
                autoScrollingDelta: 60, autoScrollingMode: AutoScrollingMode.end),
              primaryYAxis: NumericAxis(isVisible: false, minimum: 0, maximum: maxVol * 1.2),
              series: <CartesianSeries<RawChartData, String>>[
                ColumnSeries<RawChartData, String>(
                  dataSource: _data,
                  xValueMapper: (d, _) => d.time.toString().substring(0, 10),
                  yValueMapper: (d, _) => d.volume,
                  pointColorMapper: (d, _) => d.close >= d.open
                    ? const Color(0xFF26C6A6).withOpacity(0.5)
                    : const Color(0xFFEF5350).withOpacity(0.5),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(1.5)),
                  width: 0.7,
                ),
              ],
            ),
          ),

          // ── MA legend ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
            child: Row(children: [
              _MALabel('MA20', const Color(0xFF40C4FF)),
              const SizedBox(width: 14),
              _MALabel('MA50', const Color(0xFFFFD740)),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ──────────────────────────────────────────────────────────
class _SegmentPicker extends StatelessWidget {
  final List<String> options;
  final String selected;
  final void Function(String) onTap;
  final Color activeColor;
  const _SegmentPicker({required this.options, required this.selected, required this.onTap, required this.activeColor});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: options.map((o) {
    final sel = o == selected;
    return GestureDetector(
      onTap: () => onTap(o),
      child: Container(
        margin: const EdgeInsets.only(right: 5),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: sel ? activeColor.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: sel ? activeColor : Colors.white24),
        ),
        child: Text(o, style: TextStyle(color: sel ? activeColor : Colors.white38,
            fontSize: 10, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }).toList());
}

class _OHLCVLabel extends StatelessWidget {
  final String k, v; final Color c;
  const _OHLCVLabel(this.k, this.v, this.c);
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Text('$k ', style: const TextStyle(color: Colors.white38, fontSize: 10)),
    Text(v, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)),
  ]);
}

class _MALabel extends StatelessWidget {
  final String label; final Color color;
  const _MALabel(this.label, this.color);
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 14, height: 2, color: color),
    const SizedBox(width: 4),
    Text(label, style: TextStyle(color: color, fontSize: 9)),
  ]);
}
