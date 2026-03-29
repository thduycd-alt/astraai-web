import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dio/dio.dart';
import 'dart:async';

// ─── Model ─────────────────────────────────────────
class PortfolioPosition {
  String symbol;
  double buyPrice;
  double quantity;
  double currentPrice;
  DateTime buyDate;

  PortfolioPosition({
    required this.symbol,
    required this.buyPrice,
    required this.quantity,
    this.currentPrice = 0,
    required this.buyDate,
  });

  double get cost   => buyPrice * quantity;
  double get value  => (currentPrice > 0 ? currentPrice : buyPrice) * quantity;
  double get pnl    => value - cost;
  double get pnlPct => cost > 0 ? (pnl / cost) * 100 : 0;

  Map toJson() => {
    's': symbol, 'bp': buyPrice, 'q': quantity,
    'cp': currentPrice, 'bd': buyDate.millisecondsSinceEpoch
  };
  factory PortfolioPosition.fromJson(Map m) => PortfolioPosition(
    symbol: m['s'], buyPrice: m['bp'].toDouble(),
    quantity: m['q'].toDouble(), currentPrice: (m['cp'] ?? 0).toDouble(),
    buyDate: DateTime.fromMillisecondsSinceEpoch(m['bd']),
  );
}

// ─── Screen ────────────────────────────────────────
class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});
  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final _positions = <PortfolioPosition>[];
  Timer? _refreshTimer;

  final _dio = Dio(BaseOptions(
    baseUrl: 'https://astraai-signals-api.onrender.com/api/v1',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  @override
  void initState() {
    super.initState();
    _load();
    _startRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) => _refreshPrices());
    _refreshPrices();
  }

  void _load() {
    try {
      final box = Hive.box('app_data');
      final raw = box.get('portfolio', defaultValue: []) as List;
      setState(() {
        _positions.clear();
        _positions.addAll(raw.map((m) => PortfolioPosition.fromJson(Map.from(m))));
      });
    } catch (_) {}
  }

  void _save() {
    try {
      final box = Hive.box('app_data');
      box.put('portfolio', _positions.map((p) => p.toJson()).toList());
    } catch (_) {}
  }

  Future<void> _refreshPrices() async {
    for (final pos in _positions) {
      try {
        final r = await _dio.get('/quotes', queryParameters: {'symbols': pos.symbol});
        final data = r.data[pos.symbol];
        if (data != null) {
          setState(() => pos.currentPrice = (data['price'] as num?)?.toDouble() ?? pos.currentPrice);
        }
      } catch (_) {}
    }
    _save();
  }

  void _addPosition() {
    final symCtrl   = TextEditingController();
    final priceCtrl = TextEditingController();
    final qtyCtrl   = TextEditingController();

    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1E1F2C),
      title: const Text('Thêm vị thế', style: TextStyle(color: Colors.white)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _Input(ctrl: symCtrl, hint: 'Mã CP (VD: SHS)', caps: true),
        const SizedBox(height: 10),
        _Input(ctrl: priceCtrl, hint: 'Giá mua (VD: 17000)', keyboard: TextInputType.number),
        const SizedBox(height: 10),
        _Input(ctrl: qtyCtrl,   hint: 'Số lượng (VD: 1000)',  keyboard: TextInputType.number),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
          child: const Text('Hủy', style: TextStyle(color: Colors.white38))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF69F0AE), foregroundColor: Colors.black),
          onPressed: () {
            final sym = symCtrl.text.trim().toUpperCase();
            final bp  = double.tryParse(priceCtrl.text.trim()) ?? 0;
            final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0;
            if (sym.isNotEmpty && bp > 0 && qty > 0) {
              setState(() => _positions.add(PortfolioPosition(symbol: sym, buyPrice: bp, quantity: qty, buyDate: DateTime.now())));
              _save();
              Navigator.pop(context);
              _refreshPrices();
            }
          },
          child: const Text('Thêm', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ));
  }

  void _removePosition(int i) {
    setState(() => _positions.removeAt(i));
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final totalCost  = _positions.fold(0.0, (s, p) => s + p.cost);
    final totalValue = _positions.fold(0.0, (s, p) => s + p.value);
    final totalPnl   = totalValue - totalCost;
    final totalPct   = totalCost > 0 ? (totalPnl / totalCost * 100) : 0.0;
    final pColor     = totalPnl >= 0 ? const Color(0xFF69F0AE) : const Color(0xFFFF5252);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF13141C),
        title: const Text('Danh Mục', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
            onPressed: _refreshPrices, tooltip: 'Cập nhật giá'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF69F0AE),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Thêm CP', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _addPosition,
      ),
      body: _positions.isEmpty
        ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.account_balance_wallet_outlined, color: Colors.white24, size: 64),
            SizedBox(height: 16),
            Text('Danh mục trống\nNhấn + để thêm cổ phiếu', textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, height: 1.7)),
          ]))
        : Column(children: [
            // ── NAV Summary ─────────────────────────
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [pColor.withOpacity(0.15), Colors.transparent],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: pColor.withOpacity(0.3)),
              ),
              child: Column(children: [
                const Text('GIÁ TRỊ DANH MỤC', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text('${_fmt(totalValue)} đ', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(totalPnl >= 0 ? Icons.arrow_upward : Icons.arrow_downward, color: pColor, size: 16),
                  const SizedBox(width: 4),
                  Text('${totalPct >= 0 ? '+' : ''}${totalPct.toStringAsFixed(2)}%  '
                       '(${totalPnl >= 0 ? '+' : ''}${_fmt(totalPnl)} đ)',
                    style: TextStyle(color: pColor, fontWeight: FontWeight.bold, fontSize: 14)),
                ]),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _SummaryTile(label: 'Vốn gốc', value: _fmt(totalCost)),
                  _SummaryTile(label: 'Số mã', value: '${_positions.length}'),
                ]),
              ]),
            ),
            // ── Position List ─────────────────────────
            Expanded(child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              itemCount: _positions.length,
              itemBuilder: (ctx, i) {
                final p = _positions[i];
                final pc = p.pnl >= 0 ? const Color(0xFF69F0AE) : const Color(0xFFFF5252);
                return Dismissible(
                  key: Key('${p.symbol}_$i'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5252).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete_outline, color: Color(0xFFFF5252)),
                  ),
                  onDismissed: (_) => _removePosition(i),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF13141C),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(children: [
                      // Symbol
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: pc.withOpacity(0.12), shape: BoxShape.circle),
                        child: Center(child: Text(p.symbol.substring(0, p.symbol.length > 3 ? 3 : p.symbol.length),
                          style: TextStyle(color: pc, fontWeight: FontWeight.bold, fontSize: 11))),
                      ),
                      const SizedBox(width: 12),
                      // Info
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.symbol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('${_fmt(p.quantity.toInt())} CP × ${_fmt(p.buyPrice.toInt())}đ',
                          style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      ])),
                      // P&L
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('${_fmt(p.value.toInt())}đ',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('${p.pnl >= 0 ? '+' : ''}${p.pnlPct.toStringAsFixed(1)}%',
                          style: TextStyle(color: pc, fontWeight: FontWeight.bold, fontSize: 13)),
                      ]),
                    ]),
                  ),
                );
              },
            )),
          ]),
    );
  }

  String _fmt(num v) {
    if (v.abs() >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}T';
    if (v.abs() >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    return v.toStringAsFixed(0);
  }
}

class _Input extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final bool caps;
  final TextInputType keyboard;
  const _Input({required this.ctrl, required this.hint, this.caps = false,
    this.keyboard = TextInputType.text});
  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    keyboardType: keyboard,
    textCapitalization: caps ? TextCapitalization.characters : TextCapitalization.none,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      hintText: hint, hintStyle: const TextStyle(color: Colors.white38),
      filled: true, fillColor: const Color(0xFF13141C),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );
}

class _SummaryTile extends StatelessWidget {
  final String label, value;
  const _SummaryTile({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
    const SizedBox(height: 2),
    Text(value, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
  ]);
}
