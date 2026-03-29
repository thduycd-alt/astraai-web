import 'package:flutter/material.dart';

class LayerCard extends StatelessWidget {
  final String title;
  final String content;
  final Color statusColor;

  const LayerCard({
    super.key,
    required this.title,
    required this.content,
    this.statusColor = Colors.blueAccent,
  });

  String _getSummary() {
    if (content.isEmpty) return 'Đang xử lý dữ liệu...';
    // Lấy câu đầu tiên để làm Tóm tắt
    final sentences = content.split('. ');
    if (sentences.isNotEmpty && sentences[0].length > 10) {
      String first = sentences[0];
      if (!first.endsWith('.')) first += '.';
      return first;
    }
    return content.length > 70 ? '${content.substring(0, 70)}...' : content;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF13141C), // Deep modern dark
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          collapsedIconColor: Colors.white30,
          iconColor: statusColor,
          childrenPadding: EdgeInsets.zero,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: statusColor,
              letterSpacing: 0.3,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _getSummary(),
              style: TextStyle(
                fontSize: 14, 
                color: Colors.white.withOpacity(0.55), 
                height: 1.5,
                fontWeight: FontWeight.w400
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2), // Tonal separation
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 16, color: statusColor.withOpacity(0.8)),
                      const SizedBox(width: 8),
                      Text('AI Dịch Nghĩa', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 15, 
                      color: Colors.white.withOpacity(0.9), 
                      height: 1.7,
                      letterSpacing: 0.2
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
