import 'package:flutter/material.dart';
import '../models/analysis_result.dart';

class QualityScoringTable extends StatefulWidget {
  final QualityScoring scoring;

  const QualityScoringTable({Key? key, required this.scoring}) : super(key: key);

  @override
  State<QualityScoringTable> createState() => _QualityScoringTableState();
}

class _QualityScoringTableState extends State<QualityScoringTable> {
  bool _expanded = false;

  Color _scoreColor(double pct) {
    if (pct >= 70) return const Color(0xFF00E676);       // xanh lá
    if (pct >= 50) return const Color(0xFFFFD600);       // vàng
    if (pct >= 25) return const Color(0xFFFF9800);       // cam
    return const Color(0xFFFF3D00);                      // đỏ
  }

  Color _ratingColor(String rating) {
    switch (rating.toUpperCase()) {
      case 'TỐT':
      case 'XUẤT SẮC': return const Color(0xFF00E676);
      case 'KHÁ':      return const Color(0xFF40C4FF);
      case 'TRUNG BÌNH': return const Color(0xFFFFD600);
      default:         return const Color(0xFFFF3D00);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scoring;
    final normalizedPct = s.maxScore > 0 ? s.totalScore / s.maxScore : 0.0;
    final normalizedScore = (normalizedPct * 100).toStringAsFixed(1);
    final ratingColor = _ratingColor(s.qualityRating);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF12121A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── HEADER TOGGLE ────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [ratingColor.withOpacity(0.15), Colors.transparent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  // Icon và tiêu đề
                  Icon(Icons.fact_check_rounded, color: ratingColor, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PHẨM CHẤT DOANH NGHIỆP',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                        Text(
                          'Tiêu chí tầm soát Doanh nghiệp',
                          style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  // Score badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Text(
                            normalizedScore,
                            style: TextStyle(color: ratingColor, fontSize: 28, fontWeight: FontWeight.w900),
                          ),
                          Text(
                            ' / 100',
                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: ratingColor.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          s.qualityRating.toUpperCase(),
                          style: TextStyle(color: ratingColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: Colors.white38, size: 24),
                ],
              ),
            ),
          ),

          // ── PROGRESS BAR ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: normalizedPct.clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: Colors.white.withOpacity(0.07),
                valueColor: AlwaysStoppedAnimation<Color>(ratingColor),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // ── EXPANDED CRITERIA LIST ────────────────────────────────
          if (_expanded) ...[
            const Divider(height: 1, color: Color(0xFF1E1E2C)),
            ...s.criteriaList.asMap().entries.map((entry) {
              final idx = entry.key;
              final c = entry.value;
              final maxPerCriterion = s.criteriaList.isNotEmpty ? s.maxScore / s.criteriaList.length : 1.0;
              final pct = maxPerCriterion > 0 ? (c.score / maxPerCriterion * 100).clamp(0.0, 100.0) : 0.0;
              final sc = _scoreColor(pct);
              final isEven = idx % 2 == 0;

              return Container(
                color: isEven ? Colors.white.withOpacity(0.015) : Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Score circle
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: sc.withOpacity(0.15),
                        border: Border.all(color: sc.withOpacity(0.5), width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          '${pct.round()}',
                          style: TextStyle(color: sc, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${c.id}. ',
                                style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12),
                              ),
                              Expanded(
                                child: Text(
                                  c.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c.reason,
                            style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12, height: 1.45),
                          ),
                          const SizedBox(height: 6),
                          // Mini score bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: (pct / 100).clamp(0.0, 1.0),
                              minHeight: 3,
                              backgroundColor: Colors.white.withOpacity(0.06),
                              valueColor: AlwaysStoppedAnimation<Color>(sc),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 4),
          ],

          // ── FOOTER ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: Colors.white24, size: 16,
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    _expanded ? 'Thu gọn chi tiết' : 'Xem chi tiết Tiêu Chí',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
