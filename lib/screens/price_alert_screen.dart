import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dio/dio.dart';
import 'analysis_screen.dart';

// ─── Model ─────────────────────────────────────────
class PriceAlert {
  final String id;
  final String symbol;
  final double targetPrice;
  final String condition; // 'above' | 'below'
  final String note;
  bool triggered;
  DateTime createdAt;

  PriceAlert({required this.id, required this.symbol, required this.targetPrice,
    required this.condition, this.note = '', this.triggered = false, required this.createdAt});

  Map toJson() => {
    'id': id, 's': symbol, 'tp': targetPrice, 'c': condition,
    'n': note, 'tr': triggered, 'ca': createdAt.millisecondsSinceEpoch,
  };
  factory PriceAlert.fromJson(Map m) => PriceAlert(
    id: m['id'], symbol: m['s'], targetPrice: m['tp'].toDouble(),
    condition: m['c'], note: m['n'] ?? '', triggered: m['tr'] ?? false,
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['ca']),
  );
}

// ─── Screen ────────────────────────────────────────
class PriceAlertScreen extends StatefulWidget {
  const PriceAlertScreen({super.key});
  @override
  State<PriceAlertScreen> createState() => _PriceAlertScreenState();
}

class _PriceAlertScreenState extends State<PriceAlertScreen> {
  final _alerts = <PriceAlert>[];
  Timer? _checkTimer;

  final _dio = Dio(BaseOptions(
    baseUrl: 'https://astraai-signals-api.onrender.com/api/v1',
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
  ));

  @override
  void initState() {
    super.initState();
    _load();
    _startChecking();
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  void _load() {
    try {
      final raw = Hive.box('app_data').get('price_alerts', defaultValue: []) as List;
      setState(() {
        _alerts.clear();
        _alerts.addAll(raw.map((m) => PriceAlert.fromJson(Map.from(m))));
      });
    } catch (_) {}
  }

  void _save() {
    try {
      Hive.box('app_data').put('price_alerts', _alerts.map((a) => a.toJson()).toList());
    } catch (_) {}
  }

  void _startChecking() {
    _checkTimer = Timer.periodic(const Duration(minutes: 1), (_) => _checkAlerts());
  }

  Future<void> _checkAlerts() async {
    final active = _alerts.where((a) => !a.triggered).toList();
    if (active.isEmpty) return;

    final syms = active.map((a) => a.symbol).toSet().join(',');
    try {
      final r = await _dio.get('/quotes', queryParameters: {'symbols': syms});
      for (final alert in active) {
        final data = r.data[alert.symbol];
        if (data == null) continue;
        final price = (data['price'] as num?)?.toDouble() ?? 0;
        if (price <= 0) continue;

        bool hit = (alert.condition == 'above' && price >= alert.targetPrice) ||
                   (alert.condition == 'below' && price <= alert.targetPrice);
        if (hit) {
          setState(() => alert.triggered = true);
          _showTriggeredAlert(alert, price);
        }
      }
      _save();
    } catch (_) {}
  }

  void _showTriggeredAlert(PriceAlert alert, double price) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: const Color(0xFF13141C),
      duration: const Duration(seconds: 6),
      content: Row(children: [
        const Icon(Icons.notifications_active, color: Color(0xFFFFD740), size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('🚨 Alert kích hoạt: ${alert.symbol}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Text('Giá ${price > 0 ? (price/1000).toStringAsFixed(1) : '--'}k '
            '${alert.condition == 'above' ? '≥' : '≤'} '
            '${(alert.targetPrice/1000).toStringAsFixed(1)}k',
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ])),
      ]),
      action: SnackBarAction(
        label: 'Xem',
        textColor: const Color(0xFFFFD740),
        onPressed: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => AnalysisScreen(symbol: alert.symbol))),
      ),
    ));
  }

  void _addAlert() {
    final symCtrl   = TextEditingController();
    final priceCtrl = TextEditingController();
    final noteCtrl  = TextEditingController();
    String cond     = 'above';

    showDialog(context: context, builder: (_) => StatefulBuilder(builder: (ctx, setSt) => AlertDialog(
      backgroundColor: const Color(0xFF1E1F2C),
      title: const Text('Tạo cảnh báo giá', style: TextStyle(color: Colors.white)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _TF(ctrl: symCtrl, hint: 'Mã CP (VD: SHS)', caps: true),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _CondBtn(label: '≥ Giá tăng đến', active: cond == 'above',
            onTap: () => setSt(() => cond = 'above'))),
          const SizedBox(width: 8),
          Expanded(child: _CondBtn(label: '≤ Giá giảm đến', active: cond == 'below',
            onTap: () => setSt(() => cond = 'below'))),
        ]),
        const SizedBox(height: 10),
        _TF(ctrl: priceCtrl, hint: 'Giá mục tiêu (VD: 18000)', keyboard: TextInputType.number),
        const SizedBox(height: 10),
        _TF(ctrl: noteCtrl, hint: 'Ghi chú (tuỳ chọn)'),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
          child: const Text('Hủy', style: TextStyle(color: Colors.white38))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD740), foregroundColor: Colors.black),
          onPressed: () {
            final sym   = symCtrl.text.trim().toUpperCase();
            final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
            if (sym.isNotEmpty && price > 0) {
              setState(() => _alerts.add(PriceAlert(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                symbol: sym, targetPrice: price, condition: cond,
                note: noteCtrl.text.trim(), createdAt: DateTime.now(),
              )));
              _save();
              Navigator.pop(ctx);
            }
          },
          child: const Text('Lưu Alert', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    )));
  }

  @override
  Widget build(BuildContext context) {
    final active    = _alerts.where((a) => !a.triggered).length;
    final triggered = _alerts.where((a) =>  a.triggered).length;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF13141C),
        title: const Text('Cảnh Báo Giá', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (active > 0) Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              label: Text('$active đang chạy', style: const TextStyle(color: Color(0xFFFFD740), fontSize: 11)),
              backgroundColor: const Color(0xFFFFD740).withOpacity(0.1),
              side: const BorderSide(color: Color(0xFFFFD740), width: 0.5),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFFD740),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_alert),
        label: const Text('Tạo Alert', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _addAlert,
      ),
      body: _alerts.isEmpty
        ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.notifications_none, color: Colors.white24, size: 64),
            SizedBox(height: 16),
            Text('Chưa có cảnh báo\nNhấn + để tạo alert giá', textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, height: 1.7)),
          ]))
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: _alerts.length,
            itemBuilder: (ctx, i) {
              final a      = _alerts[i];
              final color  = a.triggered ? Colors.white24 : (a.condition == 'above' ? const Color(0xFF69F0AE) : const Color(0xFFFF5252));
              return Dismissible(
                key: Key(a.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.delete_outline, color: Colors.red),
                ),
                onDismissed: (_) { setState(() => _alerts.removeAt(i)); _save(); },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13141C),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: a.triggered ? Colors.white12 : color.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    Icon(a.triggered ? Icons.check_circle : Icons.notifications_active,
                      color: a.triggered ? Colors.white24 : const Color(0xFFFFD740), size: 22),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(a.symbol, style: TextStyle(
                        color: a.triggered ? Colors.white38 : Colors.white,
                        fontWeight: FontWeight.bold, fontSize: 15,
                        decoration: a.triggered ? TextDecoration.lineThrough : null)),
                      const SizedBox(height: 3),
                      Text('${a.condition == 'above' ? '≥' : '≤'} ${(a.targetPrice/1000).toStringAsFixed(1)}k  '
                           '${a.note.isNotEmpty ? '• ${a.note}' : ''}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ])),
                    if (a.triggered)
                      const Text('✓ Triggered', style: TextStyle(color: Colors.white30, fontSize: 11))
                  ]),
                ),
              );
            },
          ),
    );
  }
}

class _TF extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final bool caps;
  final TextInputType keyboard;
  const _TF({required this.ctrl, required this.hint, this.caps = false, this.keyboard = TextInputType.text});
  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl, keyboardType: keyboard,
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

class _CondBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _CondBtn({required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFFFD740).withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: active ? const Color(0xFFFFD740) : Colors.white24),
      ),
      child: Center(child: Text(label, style: TextStyle(
        color: active ? const Color(0xFFFFD740) : Colors.white54, fontSize: 11))),
    ),
  );
}
