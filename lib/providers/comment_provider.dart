import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

// Thêm host URL của Server tại đây (Sửa lại khi deploy)
const String _baseUrl = 'http://127.0.0.1:8000/api/v1/comments';
final dio = Dio();

// Model Class cho Comment
class TradingComment {
  final String userName;
  final String content;
  final String timestamp;

  TradingComment({required this.userName, required this.content, required this.timestamp});

  factory TradingComment.fromJson(Map<String, dynamic> json) {
    return TradingComment(
      userName: json['user_name'] ?? 'Ẩn danh',
      content: json['content'] ?? '',
      timestamp: json['timestamp'] ?? '',
    );
  }
}

// Provider để Fetch danh sách comments theo Symbol
final commentsProvider = FutureProvider.family<List<TradingComment>, String>((ref, symbol) async {
  try {
    final response = await dio.get('$_baseUrl/$symbol');
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((e) => TradingComment.fromJson(e)).toList();
    }
    return [];
  } catch (e) {
    print('Lỗi gọi API Comment: $e');
    return [];
  }
});

class CommentNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  CommentNotifier(this.ref) : super(const AsyncData(null));

  Future<void> postComment(String symbol, String content) async {
    state = const AsyncLoading();
    try {
      await dio.post('$_baseUrl/$symbol', data: {
        "user_name": "Đội Trưởng Duy", // Hardcode cho owner
        "content": content
      });
      state = const AsyncData(null);
      // Nạp lại danh sách comment
      ref.invalidate(commentsProvider(symbol));
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}

final commentActionProvider = StateNotifierProvider<CommentNotifier, AsyncValue<void>>((ref) {
  return CommentNotifier(ref);
});
