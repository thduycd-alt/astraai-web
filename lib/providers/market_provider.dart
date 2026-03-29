import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

final marketOverviewProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return apiService.getMarketOverview();
});

final sectorRotationProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return apiService.getSectorRotation();
});
