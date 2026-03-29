import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/analysis_result.dart';

/// Bảng Định Giá Tầm Soát Premium
/// Hiển thị Fair Value, Vùng An Toàn, và thanh giá trực quan.
class ValuationPanel extends StatelessWidget {
  final ValuationMetrics metrics;
  const ValuationPanel({super.key, required this.metrics});

  String _fmt(double v) {
    if (v <= 0) return 'N/A';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final mos = metrics.mosZones;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF13141C),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFB2FF59).withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: const Color(0xFFB2FF59).withOpacity(0.05), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFB2FF59).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.calculate_rounded, color: Color(0xFFB2FF59), size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('ĐỊNH GIÁ THEO PHƯƠNG PHÁP TẦM SOÁT',
                    style: TextStyle(color: Color(0xFFB2FF59), fontWeight: FontWeight.w900,
                        fontSize: 11, letterSpacing: 0.8)),
              ),
              if (mos != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _zoneColor(mos.action).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _zoneColor(mos.action).withOpacity(0.5)),
                  ),
                  child: Text(mos.action,
                      style: TextStyle(color: _zoneColor(mos.action),
                          fontSize: 11, fontWeight: FontWeight.bold)),
                ),
            ]),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 14),

          // ── Top Metrics Row ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              _MetricChip(label: 'EPS Fwd', value: _fmt(metrics.eps), sub: 'VNĐ/CP', color: const Color(0xFF69F0AE)),
              const SizedBox(width: 10),
              _MetricChip(label: 'P/E Chọn', value: metrics.pe.toStringAsFixed(1), sub: 'x (Ngành ${metrics.industryPe.toStringAsFixed(1)}x)', color: const Color(0xFF40C4FF)),
              const SizedBox(width: 10),
              _MetricChip(label: 'Upside', value: '${metrics.upside >= 0 ? '+' : ''}${metrics.upside.toStringAsFixed(1)}%',
                  sub: metrics.upside >= 0 ? 'Tiềm năng tăng' : 'Đang đắt hơn FV',
                  color: metrics.upside >= 15 ? const Color(0xFF69F0AE) : (metrics.upside < 0 ? const Color(0xFFFF5252) : Colors.amberAccent)),
            ]),
          ),
          const SizedBox(height: 14),

          // ── 5-Zone Price Bar ─────────────────────────────────────────────
          if (mos != null) _MoSBar(mos: mos, currentPrice: metrics.fairValue / (1 + metrics.upside / 100)),
          const SizedBox(height: 14),
          Divider(height: 1, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 14),

          // ── Zone Summary Table ───────────────────────────────────────────
          if (mos != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: [
                _ZoneRow(icon: Icons.rocket_launch_rounded, color: const Color(0xFF69F0AE),
                    label: 'Mua Mạnh (MoS -25%)', value: _fmt(mos.buyStrong)),
                _ZoneRow(icon: Icons.trending_up_rounded, color: const Color(0xFF40C4FF),
                    label: 'Tích Lũy (MoS -15%)', value: _fmt(mos.buyZone)),
                _ZoneRow(icon: Icons.radio_button_checked, color: Colors.amberAccent,
                    label: 'Fair Value (EPS × P/E)', value: _fmt(mos.fairValue), isFairValue: true),
                _ZoneRow(icon: Icons.logout_rounded, color: Colors.orangeAccent,
                    label: 'Chốt Lời (+15%)', value: _fmt(mos.tpZone)),
                _ZoneRow(icon: Icons.warning_amber_rounded, color: const Color(0xFFFF5252),
                    label: 'Thoát Mạnh (+30%)', value: _fmt(mos.tpStrong)),
              ]),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _zoneColor(mos.action).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _zoneColor(mos.action).withOpacity(0.3)),
                ),
                child: Row(children: [
                  Icon(Icons.location_pin, color: _zoneColor(mos.action), size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Vị trí hiện tại: ${mos.currentZoneLabel}',
                      style: TextStyle(color: _zoneColor(mos.action),
                          fontSize: 12, fontWeight: FontWeight.w600))),
                ]),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── P/E Evaluation ───────────────────────────────────────────────
          if (metrics.peEvaluation.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                const Icon(Icons.balance_rounded, color: Colors.white38, size: 14),
                const SizedBox(width: 6),
                Text('Định giá: ${metrics.peEvaluation}',
                    style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ]),
            ),
          if (metrics.yoyGrowthPct != 0) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Icon(metrics.yoyGrowthPct >= 0 ? Icons.trending_up : Icons.trending_down,
                    color: metrics.yoyGrowthPct >= 0 ? const Color(0xFF69F0AE) : const Color(0xFFFF5252),
                    size: 14),
                const SizedBox(width: 6),
                Text('Tăng trưởng LNST YoY: ${metrics.yoyGrowthPct >= 0 ? '+' : ''}${metrics.yoyGrowthPct.toStringAsFixed(1)}%',
                    style: TextStyle(
                        color: metrics.yoyGrowthPct >= 0 ? const Color(0xFF69F0AE) : const Color(0xFFFF5252),
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          ],

          // ── AI Reasoning ─────────────────────────────────────────────────
          if (metrics.aiReasoning.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.white.withOpacity(0.05)),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.psychology_rounded, color: Colors.purpleAccent, size: 14),
                  SizedBox(width: 6),
                  Text('LUẬN CHỨNG ĐỊNH GIÁ AI (TẦM SOÁT)',
                      style: TextStyle(color: Colors.purpleAccent, fontSize: 11,
                          fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ]),
                const SizedBox(height: 8),
                Text(metrics.aiReasoning,
                    style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.6)),
                if (metrics.aiTrailingAssessment.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _AISubField(title: 'Chất lượng EPS Trailing', text: metrics.aiTrailingAssessment),
                ],
                if (metrics.aiGrowthProjection.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _AISubField(title: 'Dự phóng Tăng trưởng', text: metrics.aiGrowthProjection),
                ],
                if (metrics.aiPeReasoning.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _AISubField(title: 'Luận chứng P/E', text: metrics.aiPeReasoning),
                ],
              ]),
            ),
          ],
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Color _zoneColor(String action) {
    if (action.contains('MUA MẠNH') || action.contains('TÍCH LŨY')) return const Color(0xFF69F0AE);
    if (action.contains('GIỮ') || action.contains('NẮM')) return Colors.amberAccent;
    if (action.contains('CHỐT')) return Colors.orangeAccent;
    return const Color(0xFFFF5252);
  }
}

class _MetricChip extends StatelessWidget {
  final String label, value, sub;
  final Color color;
  const _MetricChip({required this.label, required this.value, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(color: Colors.white30, fontSize: 8), textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _ZoneRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  final bool isFairValue;
  const _ZoneRow({required this.icon, required this.color, required this.label, required this.value, this.isFairValue = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 10),
      Expanded(child: Text(label,
          style: TextStyle(color: Colors.white.withOpacity(isFairValue ? 0.9 : 0.6),
              fontSize: 12, fontWeight: isFairValue ? FontWeight.w800 : FontWeight.normal))),
      Text(value,
          style: TextStyle(color: color, fontSize: 13,
              fontWeight: isFairValue ? FontWeight.w900 : FontWeight.bold)),
    ]),
  );
}

class _MoSBar extends StatelessWidget {
  final MoSZones mos;
  final double currentPrice;
  const _MoSBar({required this.mos, required this.currentPrice});

  @override
  Widget build(BuildContext context) {
    final min = mos.buyStrong * 0.9;
    final max = mos.tpStrong  * 1.1;
    final range = max - min;

    double pct(double value) => range > 0 ? math.min(1.0, math.max(0.0, (value - min) / range)) : 0.5;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('VÙNG GIÁ & BIÊN AN TOÀN',
            style: TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 0.8)),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (ctx, cst) {
          final w = cst.maxWidth;
          return SizedBox(height: 36, child: Stack(children: [
            // Background gradient bar
            Positioned.fill(child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(colors: [
                  Color(0xFF69F0AE), Color(0xFF40C4FF),
                  Color(0xFFFFD740), Color(0xFFFF6D00), Color(0xFFFF5252),
                ]),
              ),
            )),
            // Price tick marks
            ...[mos.buyStrong, mos.buyZone, mos.fairValue, mos.tpZone, mos.tpStrong].map((v) =>
              Positioned(left: pct(v) * w - 1, top: 0, bottom: 0,
                child: Container(width: 2, color: Colors.black26))
            ),
            // Current price indicator
            Positioned(left: math.max(0, math.min(w - 20, pct(currentPrice) * w - 10)),
              top: 4, child: Column(children: [
                Container(width: 2, height: 28, color: Colors.white),
                Container(width: 2, height: 0),
              ])
            ),
          ]));
        }),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${(mos.buyStrong/1000).toStringAsFixed(0)}k',
              style: const TextStyle(color: Color(0xFF69F0AE), fontSize: 9)),
          Text('FV: ${(mos.fairValue/1000).toStringAsFixed(0)}k',
              style: const TextStyle(color: Colors.amberAccent, fontSize: 9)),
          Text('${(mos.tpStrong/1000).toStringAsFixed(0)}k',
              style: const TextStyle(color: Color(0xFFFF5252), fontSize: 9)),
        ]),
      ]),
    );
  }
}

class _AISubField extends StatelessWidget {
  final String title, text;
  const _AISubField({required this.title, required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.03),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.white.withOpacity(0.06)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title.toUpperCase(),
          style: const TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 0.5)),
      const SizedBox(height: 4),
      Text(text, style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.5)),
    ]),
  );
}
