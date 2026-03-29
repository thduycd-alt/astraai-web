import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'analysis_screen.dart';

/// Màn hình Screener — Tầm soát cổ phiếu theo bộ lọc cơ bản
class ScreenerScreen extends StatefulWidget {
  const ScreenerScreen({super.key});
  @override
  State<ScreenerScreen> createState() => _ScreenerScreenState();
}

class _ScreenerScreenState extends State<ScreenerScreen> {
  // Bộ lọc
  double _minRoe  = 0;
  double _maxPe   = 30;
  double _minYoy  = -50;
  String _sector  = 'Tất cả';

  bool _loading = false;
  List<Map<String, dynamic>> _results = [];
  String? _error;

  // 50 mã phổ biến để screener
  static const _watchlistDefault = [
    'VIC','VHM','VNM','HPG','VCB','BID','CTG','VPB','MBB','TCB',
    'STB','SHB','EIB','ACB','HDB','VIB','MSB','LPB','TPB','OCB',
    'VGI','FPT','CMG','VGT','VJC','ACV','GMD','PVD','GAS','PLX',
    'REE','PC1','EVF','DGC','DCM','DPM','BMP','NTP','CSV','SCS',
    'MSN','MWG','PNJ','DGW','FRT','HAH','VOS','SHS','HCM','VND',
  ];

  static const _sectors = ['Tất cả','Ngân hàng','Chứng khoán','Bất động sản','Thép','Dầu khí','Retail','Công nghệ','Phân bón','Logistics'];

  final _dio = Dio(BaseOptions(
    baseUrl: 'https://astraai-signals-api.onrender.com/api/v1',
    connectTimeout: const Duration(seconds: 120),
    receiveTimeout: const Duration(seconds: 120),
  ));

  Future<void> _runScreener() async {
    setState(() { _loading = true; _error = null; _results = []; });
    final found = <Map<String, dynamic>>[];

    // Chạy tuần tự để tránh OOM, lấy top 20 mã trước
    for (final sym in _watchlistDefault.take(20)) {
      try {
        final res = await _dio.get('/analyze/$sym');
        final data = res.data['data'];
        final metrics = data['layers']['fundamental']['metrics'] as Map;
        final roe  = (metrics['ROE_Percent'] as num?)?.toDouble() ?? 0;
        final pe   = (metrics['PE'] as num?)?.toDouble() ?? 0;
        final yoy  = (metrics['yoy_growth_pct'] as num?)?.toDouble() ?? 0;
        final fv   = (metrics['Fair_Value'] as num?)?.toDouble() ?? 0;
        final price = (data['ticker_info']['price'] as num?)?.toDouble() ?? 0;
        final upside = fv > 0 && price > 0 ? ((fv - price) / price * 100) : 0.0;

        bool pass = roe >= _minRoe && (pe <= _maxPe || pe == 0) && yoy >= _minYoy;
        if (pass) {
          found.add({
            'symbol': sym,
            'company': data['ticker_info']['company_name'] ?? sym,
            'price': price,
            'roe': roe,
            'pe': pe,
            'yoy': yoy,
            'upside': upside,
          });
        }
      } catch (_) { /* bỏ qua mã lỗi */ }
    }

    // Sort theo upside
    found.sort((a, b) => (b['upside'] as double).compareTo(a['upside'] as double));
    setState(() { _results = found; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF13141C),
        title: const Text('Tầm Soát Cổ Phiếu', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_loading)
            const Padding(padding: EdgeInsets.only(right: 16),
              child: Center(child: SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFB2FF59))))),
        ],
      ),
      body: Column(children: [
        // ── Bộ lọc ──────────────────────────────
        Container(
          color: const Color(0xFF13141C),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('BỘ LỌC', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
            const SizedBox(height: 10),
            Row(children: [
              _FilterChip(label: 'ROE ≥ ${_minRoe.toInt()}%', onTap: () => _showSlider(
                context, 'ROE tối thiểu (%)', 0, 40, _minRoe, (v) => setState(() => _minRoe = v))),
              const SizedBox(width: 8),
              _FilterChip(label: 'P/E ≤ ${_maxPe.toInt()}x', onTap: () => _showSlider(
                context, 'P/E tối đa (x)', 5, 60, _maxPe, (v) => setState(() => _maxPe = v))),
              const SizedBox(width: 8),
              _FilterChip(label: 'YoY ≥ ${_minYoy.toInt()}%', onTap: () => _showSlider(
                context, 'Tăng trưởng YoY tối thiểu (%)', -50, 100, _minYoy, (v) => setState(() => _minYoy = v))),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB2FF59),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                icon: const Icon(Icons.search_rounded, size: 18),
                label: const Text('Tầm Soát', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: _loading ? null : _runScreener,
              ),
            ),
          ]),
        ),
        //  ── Kết quả ──────────────────────────────
        Expanded(child: _loading
          ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(color: Color(0xFFB2FF59)),
              SizedBox(height: 16),
              Text('Đang phân tích... (~30s)', style: TextStyle(color: Colors.white54)),
            ]))
          : _results.isEmpty
            ? Center(child: Text(
                _error ?? 'Nhấn "Tầm Soát" để bắt đầu\nlọc theo tiêu chí',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, height: 1.7)))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _results.length,
                itemBuilder: (ctx, i) => _ScreenerRow(
                  data: _results[i],
                  rank: i + 1,
                  onTap: () => Navigator.push(ctx, MaterialPageRoute(
                    builder: (_) => AnalysisScreen(symbol: _results[i]['symbol']))),
                ),
              ),
        ),
      ]),
    );
  }

  void _showSlider(BuildContext ctx, String label, double min, double max, double current, ValueChanged<double> onChanged) {
    showModalBottomSheet(context: ctx, backgroundColor: const Color(0xFF13141C),
      builder: (_) => StatefulBuilder(builder: (ctx, setSt) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Slider(
            value: current.clamp(min, max),
            min: min, max: max, divisions: 30,
            activeColor: const Color(0xFFB2FF59),
            inactiveColor: Colors.white12,
            label: current.toInt().toString(),
            onChanged: (v) { setSt(() => current = v); onChanged(v); },
          ),
          Text('${current.toInt()}', style: const TextStyle(color: Color(0xFFB2FF59), fontSize: 24, fontWeight: FontWeight.bold)),
        ]),
      )),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFB2FF59).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB2FF59).withOpacity(0.4)),
      ),
      child: Text(label, style: const TextStyle(color: Color(0xFFB2FF59), fontSize: 11, fontWeight: FontWeight.w600)),
    ),
  );
}

class _ScreenerRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final int rank;
  final VoidCallback onTap;
  const _ScreenerRow({required this.data, required this.rank, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final upside = (data['upside'] as double);
    final uColor = upside >= 15
        ? const Color(0xFF69F0AE)
        : upside >= 0 ? Colors.amberAccent : const Color(0xFFFF5252);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF13141C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(children: [
          // Rank
          Container(width: 28, height: 28,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
            child: Center(child: Text('$rank', style: const TextStyle(color: Colors.white54, fontSize: 11)))),
          const SizedBox(width: 12),
          // Symbol & Name
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(data['symbol'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 2),
            Text(data['company'] ?? '', style: const TextStyle(color: Colors.white38, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          // Metrics
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${data['price'] > 0 ? (data['price'] / 1000).toStringAsFixed(1) : '--'}k',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Row(children: [
              _Tag('ROE ${(data['roe'] as double).toStringAsFixed(0)}%', const Color(0xFF40C4FF)),
              const SizedBox(width: 4),
              _Tag('PE ${(data['pe'] as double).toStringAsFixed(0)}x', Colors.white38),
            ]),
          ]),
          const SizedBox(width: 10),
          // Upside
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: uColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: uColor.withOpacity(0.4)),
            ),
            child: Text('${upside >= 0 ? '+' : ''}${upside.toStringAsFixed(0)}%',
              style: TextStyle(color: uColor, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ]),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
    child: Text(label, style: TextStyle(color: color, fontSize: 9)),
  );
}
