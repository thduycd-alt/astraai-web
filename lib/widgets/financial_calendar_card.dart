import 'package:flutter/material.dart';
import '../models/analysis_result.dart';

/// Tầng 8: Lịch Sự Kiện Tài Chính
/// Hiển thị ĐHCĐ, Chốt quyền cổ tức, Công bố BCTC với countdown đếm ngược.
class FinancialCalendarCard extends StatelessWidget {
  final FinancialCalendar calendar;

  const FinancialCalendarCard({super.key, required this.calendar});

  @override
  Widget build(BuildContext context) {
    if (!calendar.hasEvents) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF13141C),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD740).withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD740).withOpacity(0.06),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD740).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.event_note_rounded,
                      color: Color(0xFFFFD740), size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'TẦNG 8 · LỊCH SỰ KIỆN TÀI CHÍNH',
                    style: TextStyle(
                      color: Color(0xFFFFD740),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                // Badge số sự kiện
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD740).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${calendar.upcomingEvents.length} sự kiện',
                    style: const TextStyle(
                        color: Color(0xFFFFD740),
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // ── AI Alert Banner ──────────────────────────────────────────────────
          if (calendar.alert != null) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.orangeAccent.withOpacity(0.4), width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notifications_active_rounded,
                        color: Colors.orangeAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        calendar.alert!,
                        style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 12,
                            height: 1.5,
                            fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),
          Divider(height: 1, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 8),

          // ── Danh sách sự kiện ───────────────────────────────────────────────
          ...calendar.upcomingEvents.map((ev) => _EventRow(event: ev)),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final FinancialEvent event;
  const _EventRow({required this.event});

  Color get _impactColor {
    switch (event.impact) {
      case 'high':
        return const Color(0xFFFF5252);
      case 'medium':
        return const Color(0xFFFFD740);
      default:
        return const Color(0xFF69F0AE);
    }
  }

  IconData get _icon {
    final name = event.event.toLowerCase();
    if (name.contains('đhcđ') || name.contains('đại hội')) {
      return Icons.groups_rounded;
    } else if (name.contains('cổ tức') || name.contains('chốt quyền')) {
      return Icons.payments_rounded;
    } else if (name.contains('bctc') || name.contains('báo cáo')) {
      return Icons.analytics_rounded;
    }
    return Icons.event_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final days = event.daysUntil;
    final isToday = days == 0;
    final isPast = days < 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // ── Icon ngành sự kiện ─────────────────────────────
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _impactColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, color: _impactColor, size: 18),
          ),
          const SizedBox(width: 12),

          // ── Tên sự kiện + ngày ─────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.event,
                  style: TextStyle(
                    color: isPast
                        ? Colors.white38
                        : Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.date,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.35), fontSize: 11),
                ),
              ],
            ),
          ),

          // ── Countdown pill ─────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isToday
                  ? const Color(0xFF00E676).withOpacity(0.15)
                  : isPast
                      ? Colors.white.withOpacity(0.04)
                      : _impactColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isToday
                    ? const Color(0xFF00E676).withOpacity(0.5)
                    : isPast
                        ? Colors.white12
                        : _impactColor.withOpacity(0.4),
              ),
            ),
            child: Text(
              isToday
                  ? '🔴 HÔM NAY'
                  : isPast
                      ? '${days.abs()}N trước'
                      : 'T${days}N',
              style: TextStyle(
                color: isToday
                    ? const Color(0xFF00E676)
                    : isPast
                        ? Colors.white38
                        : _impactColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
