import 'package:dio/dio.dart';
import '../models/analysis_result.dart';

class ApiService {
  final Dio _dio = Dio();
  // Đã cắm thẳng lõi AI lên Đám mây vĩnh viễn (Render.com)
  // App Mobile trên mọi điện thoại có thể truy cập ở bất cứ đâu trên thế giới
  final String baseUrl = "https://astraai-signals-api.onrender.com/api/v1";

  Future<AnalysisResult> getAnalysis(String symbol) async {
    try {
      final response = await _dio.get('$baseUrl/analyze/$symbol');
      if (response.statusCode == 200) {
        return AnalysisResult.fromJson(response.data);
      }
      throw Exception("Lỗi truy xuất dữ liệu");
    } catch (e) {
      throw Exception("API Error: $e");
    }
  }

  Future<Map<String, dynamic>> getMarketOverview() async {
    try {
      final response = await _dio.get('$baseUrl/market/overview');
      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception("Lỗi truy xuất Market Overview");
    } catch (e) {
      throw Exception("API Error: $e");
    }
  }

  Future<Map<String, dynamic>> getSectorRotation() async {
    try {
      final response = await _dio.get('$baseUrl/market/rotation');
      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception("Lỗi truy xuất Sector Rotation");
    } catch (e) {
      throw Exception("API Error: $e");
    }
  }

  Future<Map<String, dynamic>> getWatchlistQuotes(List<String> symbols) async {
    if (symbols.isEmpty) return {};
    try {
      final symString = symbols.join(',');
      final response = await _dio.get('$baseUrl/market/quotes?symbols=$symString');
      if (response.statusCode == 200) {
        return response.data;
      }
      return {};
    } catch (e) {
      print("Quotes Fetch Error: $e");
      return {};
    }
  }

  Future<List<RawChartData>> getIntradayChart(String symbol, String timeframe) async {
    try {
      final response = await _dio.get('$baseUrl/intraday/$symbol?timeframe=$timeframe');
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => RawChartData.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("Intraday Fetch Error: $e");
      return [];
    }
  }

  Future<List<RawChartData>> getIndexCandles(String index, int days) async {
    try {
      final response = await _dio.get(
        '$baseUrl/market/index-candles?index=$index&days=$days',
      );
      if (response.statusCode == 200) {
        final List<dynamic> candles = response.data['candles'] ?? [];
        return candles.map((j) => RawChartData.fromJson(j)).toList();
      }
      return [];
    } catch (e) {
      print("IndexCandles Fetch Error: $e");
      return [];
    }
  }
}

final apiService = ApiService();
