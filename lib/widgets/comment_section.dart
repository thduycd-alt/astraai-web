import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/comment_provider.dart';

class CommentSection extends ConsumerStatefulWidget {
  final String symbol;
  const CommentSection({super.key, required this.symbol});

  @override
  ConsumerState<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<CommentSection> {
  final TextEditingController _controller = TextEditingController();

  void _submitComment() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    ref.read(commentActionProvider.notifier).postComment(widget.symbol, text);
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsProvider(widget.symbol));
    final actionState = ref.watch(commentActionProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF13141C),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
               const Icon(Icons.forum_rounded, color: Colors.blueAccent),
               const SizedBox(width: 8),
               const Text('NHẬN ĐỊNH CÁ NHÂN / GHI CHÚ', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.white.withOpacity(0.05)),
          
          // List Comments
          commentsAsync.when(
            data: (comments) {
              if (comments.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: Text('Chưa có Ghi chú/Bình luận nào cho mã này.', style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic))),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.05), height: 1),
                itemBuilder: (context, index) {
                  final c = comments[index];
                  final isOwner = c.userName == "Đội Trưởng Duy";
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: isOwner ? Colors.orangeAccent.withOpacity(0.2) : Colors.white12,
                          child: Icon(Icons.person, color: isOwner ? Colors.orangeAccent : Colors.white54),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(c.userName, style: TextStyle(color: isOwner ? Colors.orangeAccent : Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  if (isOwner)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 4),
                                      child: Icon(Icons.verified, color: Colors.blue, size: 14),
                                    ),
                                  const Spacer(),
                                  Text(c.timestamp, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(c.content, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
            error: (e, st) => Padding(padding: const EdgeInsets.all(20), child: Text('Lỗi tải comment: $e', style: const TextStyle(color: Colors.red))),
          ),

          // Input Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0E),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05)))
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Nhập ghi chú hoặc bình luận riêng...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _submitComment(),
                  ),
                ),
                if (actionState.isLoading)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                else
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.blueAccent),
                    onPressed: _submitComment,
                  )
              ],
            ),
          )
        ],
      ),
    );
  }
}
