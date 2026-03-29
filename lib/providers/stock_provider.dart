import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/analysis_result.dart';

final stockAnalysisProvider = FutureProvider.family<AnalysisResult, String>((ref, symbol) async {
  return apiService.getAnalysis(symbol);
});
