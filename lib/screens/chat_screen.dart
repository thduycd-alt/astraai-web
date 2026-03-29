import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dio/dio.dart';

// ─── Model ────────────────────────────────────────
class ChatMsg {
  final String role; // 'user' | 'ai'
  final String text;
  final DateTime time;
  ChatMsg(this.role, this.text, this.time);
}

// ─── Screen ───────────────────────────────────────
class ChatScreen extends ConsumerStatefulWidget {
  final String symbol;
  const ChatScreen({super.key, required this.symbol});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller  = TextEditingController();
  final _scroll      = ScrollController();
  final _history     = <ChatMsg>[];
  bool  _loading     = false;

  final _dio = Dio(BaseOptions(
    baseUrl:        'https://astraai-signals-api.onrender.com/api/v1',
    connectTimeout: const Duration(seconds: 90),
    receiveTimeout: const Duration(seconds: 90),
  ));

  @override
  void initState() {
    super.initState();
    _loadHistory();
    // Tin nhăn chào hỏi
    if (_history.isEmpty) {
      _history.add(ChatMsg('ai',
        'Xin chào! Tôi là AstraAI — trợ lý phân tích ${widget.symbol}.\n'
        'Hỏi tôi bất cứ điều gì về cổ phiếu này: kỹ thuật, định giá, dòng tiền...', DateTime.now()));
    }
  }

  void _loadHistory() {
    try {
      final box = Hive.box('app_data');
      final raw = box.get('chat_${widget.symbol}', defaultValue: <dynamic>[]);
      for (final m in raw) {
        _history.add(ChatMsg(m['r'], m['t'], DateTime.fromMillisecondsSinceEpoch(m['ts'])));
      }
    } catch (_) {}
  }

  void _saveHistory() {
    try {
      final box = Hive.box('app_data');
      final raw = _history.map((m) => {'r': m.role, 't': m.text, 'ts': m.time.millisecondsSinceEpoch}).toList();
      box.put('chat_${widget.symbol}', raw);
    } catch (_) {}
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _controller.clear();
    setState(() {
      _history.add(ChatMsg('user', text.trim(), DateTime.now()));
      _loading = true;
    });
    _scrollBottom();

    try {
      final historyPayload = _history
          .where((m) => m.role == 'user' || m.role == 'ai')
          .take(6)
          .map((m) => {'role': m.role == 'ai' ? 'assistant' : 'user', 'content': m.text})
          .toList();

      final res = await _dio.post('/chat/', data: {
        'symbol':  widget.symbol,
        'message': text.trim(),
        'history': historyPayload,
      });

      final reply = res.data['response'] ?? 'Không có phản hồi';
      setState(() { _history.add(ChatMsg('ai', reply, DateTime.now())); });
    } on DioException catch (e) {
      final err = e.type == DioExceptionType.connectionTimeout
          ? 'Server đang khởi động (~60s), thử lại sau!'
          : 'Lỗi kết nối: ${e.message}';
      setState(() { _history.add(ChatMsg('ai', err, DateTime.now())); });
    } catch (e) {
      setState(() { _history.add(ChatMsg('ai', 'Lỗi: $e', DateTime.now())); });
    } finally {
      setState(() => _loading = false);
      _saveHistory();
      _scrollBottom();
    }
  }

  void _scrollBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scroll.hasClients) _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _clearHistory() {
    setState(() => _history
      ..clear()
      ..add(ChatMsg('ai', 'Lịch sử đã xóa. Tôi sẵn sàng phân tích ${widget.symbol}!', DateTime.now())));
    _saveHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF13141C),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(color: Color(0xFF6200EA), shape: BoxShape.circle),
            child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('AstraAI Chatbot', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text('Hỏi về ${widget.symbol}', style: const TextStyle(fontSize: 11, color: Colors.white54)),
          ]),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white38),
            tooltip: 'Xóa lịch sử',
            onPressed: _clearHistory,
          ),
        ],
      ),
      body: Column(children: [
        // Chat messages
        Expanded(child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: _history.length + (_loading ? 1 : 0),
          itemBuilder: (ctx, i) {
            if (_loading && i == _history.length) return const _TypingIndicator();
            return _BubbleTile(msg: _history[i]);
          },
        )),
        // Quick suggestions
        if (_history.length <= 2)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(children: [
              '${widget.symbol} có mua được không?',
              'Định giá hợp lý là bao nhiêu?',
              'Dòng tiền đang như thế nào?',
              'Rủi ro lớn nhất hiện tại?',
            ].map<Widget>((q) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _send(q),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6200EA).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF6200EA).withOpacity(0.4)),
                  ),
                  child: Text(q, style: const TextStyle(color: Color(0xFFB39DDB), fontSize: 12)),
                ),
              ),
            )).toList()),

          ),
        // Input
        Container(
          color: const Color(0xFF13141C),
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 3, minLines: 1,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Hỏi về ${widget.symbol}...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF1E1F2C),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: _send,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: FloatingActionButton.small(
                backgroundColor: const Color(0xFF6200EA),
                onPressed: _loading ? null : () => _send(_controller.text),
                child: _loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 20, color: Colors.white),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─── Bubble ───────────────────────────────────────
class _BubbleTile extends StatelessWidget {
  final ChatMsg msg;
  const _BubbleTile({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28, height: 28,
              decoration: const BoxDecoration(color: Color(0xFF6200EA), shape: BoxShape.circle),
              child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF6200EA) : const Color(0xFF1E1F2C),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
              ),
              child: Text(msg.text,
                style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.5)),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ─── Typing ───────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
  }
  @override
  void dispose() { _ac.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Container(width: 28, height: 28,
        decoration: const BoxDecoration(color: Color(0xFF6200EA), shape: BoxShape.circle),
        child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 16)),
      const SizedBox(width: 8),
      AnimatedBuilder(animation: _ac, builder: (_, __) => Row(
        children: List.generate(3, (i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 7, height: 7,
          decoration: BoxDecoration(
            color: Colors.purpleAccent.withOpacity(0.4 + 0.6 * (i == (_ac.value * 3).floor() % 3 ? 1 : 0)),
            shape: BoxShape.circle,
          ),
        )),
      )),
    ]),
  );
}
