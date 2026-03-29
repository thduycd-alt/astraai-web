import 'dart:async';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../models/analysis_result.dart';
import '../services/api_service.dart';

/// Biểu đồ chuẩn terminal FireAnt:
/// - Header OHLCV hover info
/// - Candle + Volume panel riêng biệt
/// - MA5 / MA10 / MA20 overlay
/// - Grid mờ chuyên nghiệp
/// - Price axis bên phải, Time axis dưới cùng
/// - Crosshair + Trackball đầy đủ
class IntradayChart extends StatefulWidget {
  final String symbol;
  final List<RawChartData> initialChartData;
  final V4Metrics? v4Metrics;
  const IntradayChart({super.key, required this.symbol, required this.initialChartData, this.v4Metrics});

  @override
  State<IntradayChart> createState() => _IntradayChartState();
}

class _IntradayChartState extends State<IntradayChart> {
  late List<RawChartData> chartData;
  Timer? _pollingTimer;
  String _selectedTimeframe = '1D';
  bool _isLoading = false;
  String _chartType = 'Candle'; // 'Candle' | 'Line'

  // OHLCV hover info
  double? _hoverOpen, _hoverHigh, _hoverLow, _hoverClose, _hoverVolume;

  final List<Map<String, String>> _timeframes = [
    {'label': '1M',  'value': '1m'},
    {'label': '5M',  'value': '5m'},
    {'label': '15M', 'value': '15m'},
    {'label': '30M', 'value': '30m'},
    {'label': '1H',  'value': '1H'},
    {'label': '1D',  'value': '1D'},
  ];

  @override
  void initState() {
    super.initState();
    chartData = widget.initialChartData;
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDataForTimeframe(String tf) async {
    setState(() { _selectedTimeframe = tf; _isLoading = true; });
    if (tf == '1D') {
      setState(() { chartData = widget.initialChartData; _isLoading = false; });
      return;
    }
    try {
      final nd = await apiService.getIntradayChart(widget.symbol, tf);
      if (mounted) setState(() { chartData = nd; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (_selectedTimeframe == '1D') return;
      try {
        final nd = await apiService.getIntradayChart(widget.symbol, _selectedTimeframe);
        if (nd.isNotEmpty && mounted) setState(() => chartData = nd);
      } catch (_) {}
    });
  }

  String _fmtX(DateTime t) {
    if (_selectedTimeframe == '1D') {
      return '${t.day.toString().padLeft(2,'0')}/${t.month.toString().padLeft(2,'0')}';
    }
    return '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
  }

  String _fmtPrice(double v) {
    if (v >= 1000) return '${(v/1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(2);
  }

  String _fmtVol(double v) {
    if (v >= 1000000) return '${(v/1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${(v/1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  // Lấy nến cuối cùng làm giá trị mặc định cho header
  RawChartData? get _latestBar => chartData.isNotEmpty ? chartData.last : null;

  @override
  Widget build(BuildContext context) {
    final latest = _latestBar;
    final displayO = _hoverOpen   ?? latest?.open   ?? 0;
    final displayH = _hoverHigh   ?? latest?.high   ?? 0;
    final displayL = _hoverLow    ?? latest?.low    ?? 0;
    final displayC = _hoverClose  ?? latest?.close  ?? 0;
    final displayV = _hoverVolume ?? latest?.volume ?? 0;

    // Màu nến cuối
    final bool isBull = displayC >= displayO;
    final Color candleColor = isBull ? const Color(0xFF26C6A6) : const Color(0xFFEF5350);

    double maxVol = 1;
    for (var d in chartData) { if (d.volume > maxVol) maxVol = d.volume; }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0D12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.07), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // ── TOP TOOLBAR ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(children: [
              // Symbol
              Text(widget.symbol,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
              const SizedBox(width: 12),

              // Timeframe pills
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _timeframes.map((tf) {
                      final sel = _selectedTimeframe == tf['value'];
                      return GestureDetector(
                        onTap: () => _fetchDataForTimeframe(tf['value']!),
                        child: Container(
                          margin: const EdgeInsets.only(right: 5),
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: sel ? const Color(0xFF1D6FE8) : Colors.transparent,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: sel ? const Color(0xFF1D6FE8) : Colors.white24),
                          ),
                          child: Text(tf['label']!,
                            style: TextStyle(
                              color: sel ? Colors.white : Colors.white54,
                              fontSize: 10, fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                            )),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Chart type toggle
              GestureDetector(
                onTap: () => setState(() => _chartType = _chartType == 'Candle' ? 'Line' : 'Candle'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_chartType == 'Candle' ? Icons.candlestick_chart : Icons.show_chart,
                        color: const Color(0xFF40C4FF), size: 13),
                    const SizedBox(width: 4),
                    Text(_chartType, style: const TextStyle(color: Color(0xFF40C4FF), fontSize: 10)),
                  ]),
                ),
              ),
            ]),
          ),

          // ── OHLCV INFO BAR (FireAnt style) ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: Wrap(spacing: 14, children: [
              _OHLCVLabel('O', _fmtPrice(displayO), candleColor),
              _OHLCVLabel('H', _fmtPrice(displayH), const Color(0xFF26C6A6)),
              _OHLCVLabel('L', _fmtPrice(displayL), const Color(0xFFEF5350)),
              _OHLCVLabel('C', _fmtPrice(displayC), candleColor),
              _OHLCVLabel('Vol', _fmtVol(displayV), Colors.white54),
              if (displayO > 0)
                _OHLCVLabel(
                  isBull ? '▲' : '▼',
                  '${((displayC - displayO)/displayO*100).toStringAsFixed(2)}%',
                  candleColor,
                ),
            ]),
          ),

          Divider(height: 1, color: Colors.white.withOpacity(0.06)),

          // ── PRICE CHART ──────────────────────────────────────────────────────
          if (_isLoading)
            const SizedBox(
              height: 280,
              child: Center(child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF1D6FE8))),
            )
          else
            SizedBox(
              height: 280,
              child: SfCartesianChart(
                margin: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                plotAreaBorderWidth: 0,
                backgroundColor: Colors.transparent,
                legend: const Legend(isVisible: false),

                // Crosshair
                crosshairBehavior: CrosshairBehavior(
                  enable: true,
                  lineType: CrosshairLineType.both,
                  lineColor: Colors.white30,
                  lineWidth: 1,
                  lineDashArray: [4, 4],
                  activationMode: ActivationMode.singleTap,
                ),

                // Trackball với OHLCV callback
                trackballBehavior: TrackballBehavior(
                  enable: true,
                  activationMode: ActivationMode.singleTap,
                  tooltipSettings: const InteractiveTooltip(enable: false), // custom header
                  tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
                  markerSettings: const TrackballMarkerSettings(
                    markerVisibility: TrackballVisibilityMode.visible,
                    height: 7, width: 7,
                    color: Colors.white,
                    borderWidth: 1.5,
                  ),
                ),

                // Zoom / Pan
                zoomPanBehavior: ZoomPanBehavior(
                  enablePinching: true, enablePanning: true, zoomMode: ZoomMode.x,
                ),

                // X Axis
                primaryXAxis: CategoryAxis(
                  labelStyle: const TextStyle(color: Colors.white38, fontSize: 9),
                  axisLine: const AxisLine(width: 0),
                  majorGridLines: const MajorGridLines(width: 0.4, color: Color(0xFF1E2130), dashArray: [4,4]),
                  majorTickLines: const MajorTickLines(size: 0),
                  autoScrollingDelta: 60,
                  autoScrollingMode: AutoScrollingMode.end,
                ),

                // Y Axis (Price) — right side
                primaryYAxis: NumericAxis(
                  name: 'priceAxis',
                  opposedPosition: true,
                  axisLine: const AxisLine(width: 0),
                  majorTickLines: const MajorTickLines(size: 0),
                  majorGridLines: const MajorGridLines(width: 0.4, color: Color(0xFF1E2130), dashArray: [4,4]),
                  labelStyle: const TextStyle(color: Colors.white54, fontSize: 10),
                  numberFormat: null,
                  // AI Hunting Zone band
                  plotBands: widget.v4Metrics != null && widget.v4Metrics!.huntingZones.length >= 2
                    ? <PlotBand>[
                        PlotBand(
                          start: widget.v4Metrics!.huntingZones[0],
                          end: widget.v4Metrics!.huntingZones[1],
                          color: const Color(0xFFE040FB).withOpacity(0.10),
                          borderColor: const Color(0xFFE040FB).withOpacity(0.4),
                          borderWidth: 1,
                          text: '⚡ AI Zone',
                          textStyle: const TextStyle(color: Color(0xFFE040FB), fontSize: 9),
                          horizontalTextAlignment: TextAnchor.start,
                        )
                      ]
                    : <PlotBand>[],
                ),

                // MA indicators
                indicators: <TechnicalIndicator<RawChartData, String>>[
                  EmaIndicator<RawChartData, String>(
                    seriesName: 'candle', period: 5,
                    signalLineColor: const Color(0xFFFFD740), signalLineWidth: 1.0,
                  ),
                  EmaIndicator<RawChartData, String>(
                    seriesName: 'candle', period: 10,
                    signalLineColor: const Color(0xFFE040FB), signalLineWidth: 1.0,
                  ),
                  EmaIndicator<RawChartData, String>(
                    seriesName: 'candle', period: 20,
                    signalLineColor: const Color(0xFF40C4FF), signalLineWidth: 1.2,
                  ),
                ],

                series: <CartesianSeries<RawChartData, String>>[
                  if (_chartType == 'Candle')
                    CandleSeries<RawChartData, String>(
                      dataSource: chartData,
                      yAxisName: 'priceAxis',
                      name: 'candle',
                      xValueMapper: (d, _) => _fmtX(d.time),
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
                        if (i < chartData.length) {
                          final d = chartData[i];
                          setState(() {
                            _hoverOpen   = d.open;
                            _hoverHigh   = d.high;
                            _hoverLow    = d.low;
                            _hoverClose  = d.close;
                            _hoverVolume = d.volume;
                          });
                        }
                      },
                    )
                  else
                    AreaSeries<RawChartData, String>(
                      dataSource: chartData,
                      yAxisName: 'priceAxis',
                      name: 'candle',
                      xValueMapper: (d, _) => _fmtX(d.time),
                      yValueMapper: (d, _) => d.close,
                      color: const Color(0xFF1D6FE8).withOpacity(0.12),
                      borderColor: const Color(0xFF1D6FE8),
                      borderWidth: 1.5,
                    ),
                ],
              ),
            ),

          Divider(height: 1, color: Colors.white.withOpacity(0.06)),

          // ── VOLUME PANEL (separate, like FireAnt) ───────────────────────────
          SizedBox(
            height: 60,
            child: SfCartesianChart(
              margin: const EdgeInsets.fromLTRB(0, 2, 0, 2),
              plotAreaBorderWidth: 0,
              backgroundColor: Colors.transparent,
              legend: const Legend(isVisible: false),
              primaryXAxis: CategoryAxis(
                isVisible: false,
                autoScrollingDelta: 60,
                autoScrollingMode: AutoScrollingMode.end,
              ),
              primaryYAxis: NumericAxis(
                opposedPosition: true,
                isVisible: false,
                minimum: 0,
                maximum: maxVol * 1.2,
              ),
              series: <CartesianSeries<RawChartData, String>>[
                ColumnSeries<RawChartData, String>(
                  dataSource: chartData,
                  xValueMapper: (d, _) => _fmtX(d.time),
                  yValueMapper: (d, _) => d.volume,
                  pointColorMapper: (d, _) =>
                    d.close >= d.open
                      ? const Color(0xFF26C6A6).withOpacity(0.55)
                      : const Color(0xFFEF5350).withOpacity(0.55),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(1.5)),
                  width: 0.7,
                  spacing: 0.15,
                ),
              ],
            ),
          ),

          // ── MA LEGEND ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
            child: Row(children: [
              _MALegend('MA5', const Color(0xFFFFD740)),
              const SizedBox(width: 14),
              _MALegend('MA10', const Color(0xFFE040FB)),
              const SizedBox(width: 14),
              _MALegend('MA20', const Color(0xFF40C4FF)),
              const Spacer(),
              // Volume label nhỏ
              Text('Vol: ${_fmtVol(displayV)}',
                  style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────
class _OHLCVLabel extends StatelessWidget {
  final String key0, value;
  final Color color;
  const _OHLCVLabel(this.key0, this.value, this.color);

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Text('$key0 ', style: const TextStyle(color: Colors.white38, fontSize: 10)),
    Text(value, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
  ]);
}

class _MALegend extends StatelessWidget {
  final String label;
  final Color color;
  const _MALegend(this.label, this.color);

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 14, height: 2, color: color),
    const SizedBox(width: 4),
    Text(label, style: TextStyle(color: color, fontSize: 9)),
  ]);
}
