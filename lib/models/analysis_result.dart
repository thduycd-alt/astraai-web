// Models cho AstraAI Signals

class FinancialEvent {
  final String event;
  final String date;
  final int daysUntil;
  final String impact; // "high", "medium", "low"
  final String label;

  FinancialEvent({
    required this.event,
    required this.date,
    required this.daysUntil,
    required this.impact,
    required this.label,
  });

  factory FinancialEvent.fromJson(Map<String, dynamic> json) {
    return FinancialEvent(
      event: json['event'] ?? '',
      date: json['date'] ?? '',
      daysUntil: (json['days_until'] ?? 0).toInt(),
      impact: json['impact'] ?? 'medium',
      label: json['label'] ?? '',
    );
  }
}

class FinancialCalendar {
  final String symbol;
  final List<FinancialEvent> upcomingEvents;
  final String? alert;
  final bool hasEvents;

  FinancialCalendar({
    required this.symbol,
    required this.upcomingEvents,
    this.alert,
    required this.hasEvents,
  });

  factory FinancialCalendar.fromJson(Map<String, dynamic> json) {
    final eventList = (json['upcoming_events'] as List<dynamic>? ?? [])
        .map((e) => FinancialEvent.fromJson(e as Map<String, dynamic>))
        .toList();
    return FinancialCalendar(
      symbol: json['symbol'] ?? '',
      upcomingEvents: eventList,
      alert: json['alert'],
      hasEvents: json['has_events'] ?? false,
    );
  }
}

class RawChartData {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  RawChartData({required this.time, required this.open, required this.high, required this.low, required this.close, required this.volume});

  factory RawChartData.fromJson(Map<String, dynamic> json) {
    return RawChartData(
      time: DateTime.tryParse(json['time'].toString()) ?? DateTime.now(),
      open: (json['open'] ?? 0).toDouble(),
      high: (json['high'] ?? 0).toDouble(),
      low: (json['low'] ?? 0).toDouble(),
      close: (json['close'] ?? 0).toDouble(),
      volume: (json['volume'] ?? 0).toDouble(),
    );
  }
}

class TickerInfo {
  final String symbol;
  final String companyName;
  final double price;
  final double change;
  final double pctChange;
  final double volume;
  final double valueBil;
  final double foreignBuyBil;
  final double foreignSellBil;

  TickerInfo({
    required this.symbol, required this.companyName, required this.price, required this.change, required this.pctChange,
    required this.volume, required this.valueBil, required this.foreignBuyBil, required this.foreignSellBil,
  });

  factory TickerInfo.fromJson(Map<String, dynamic> json) {
    return TickerInfo(
      symbol: json['symbol'] ?? '',
      companyName: json['company_name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      pctChange: (json['pct_change'] ?? 0).toDouble(),
      volume: (json['volume'] ?? 0).toDouble(),
      valueBil: (json['value_bil'] ?? 0).toDouble(),
      foreignBuyBil: (json['foreign_buy_bil'] ?? 0).toDouble(),
      foreignSellBil: (json['foreign_sell_bil'] ?? 0).toDouble(),
    );
  }
}

class LayerInfo {
  final String title;
  final String content;
  final String colorHex;
  final int score;

  LayerInfo({
    required this.title,
    required this.content,
    required this.colorHex,
    required this.score,
  });

  factory LayerInfo.fromJson(Map<String, dynamic> json) {
    return LayerInfo(
      title: json['layer_title'] ?? 'Tầng Phân Tích',
      content: json['expert_text'] ?? 'Đang tải giải nghĩa AI...',
      colorHex: json['color_hex'] ?? '#448AFF',
      score: (json['score'] ?? 0).toInt(),
    );
  }
}

class V4Metrics {
  final int compressionScore;
  final String whaleStyle;
  final List<double> huntingZones;

  V4Metrics({required this.compressionScore, required this.whaleStyle, required this.huntingZones});

  factory V4Metrics.fromJson(Map<String, dynamic> json) {
    return V4Metrics(
      compressionScore: (json['compression_score'] ?? 50).toInt(),
      whaleStyle: json['whale_style'] ?? 'Đang phân tích dòng tiền...',
      huntingZones: (json['hunting_zones'] as List<dynamic>? ?? [])
          .where((e) => e != null)
          .map((e) => (e as num).toDouble())
          .toList(),
    );
  }
}

class MoSZones {
  final double buyStrong;
  final double buyZone;
  final double fairValue;
  final double tpZone;
  final double tpStrong;
  final String currentZoneLabel;
  final String action;

  MoSZones({
    required this.buyStrong, required this.buyZone, required this.fairValue,
    required this.tpZone,    required this.tpStrong,
    required this.currentZoneLabel, required this.action,
  });

  factory MoSZones.fromJson(Map<String, dynamic> json) {
    return MoSZones(
      buyStrong:         (json['buy_strong']  ?? 0).toDouble(),
      buyZone:           (json['buy_zone']    ?? 0).toDouble(),
      fairValue:         (json['fair_value']  ?? 0).toDouble(),
      tpZone:            (json['tp_zone']     ?? 0).toDouble(),
      tpStrong:          (json['tp_strong']   ?? 0).toDouble(),
      currentZoneLabel:  json['current_zone_label'] ?? '',
      action:            json['action']             ?? '',
    );
  }
}

class ValuationMetrics {
  final double fairValue;
  final double upside;
  final double referencePrice;
  final double eps;
  final double pe;
  final String aiReasoning;
  // New extended fields
  final MoSZones? mosZones;
  final String peEvaluation;
  final double industryPe;
  final double trailingEps;
  final double yoyGrowthPct;
  final String aiTrailingAssessment;
  final String aiGrowthProjection;
  final String aiPeReasoning;

  ValuationMetrics({
    required this.fairValue,
    required this.upside,
    required this.referencePrice,
    required this.eps,
    required this.pe,
    required this.aiReasoning,
    this.mosZones,
    this.peEvaluation = '',
    this.industryPe   = 0,
    this.trailingEps  = 0,
    this.yoyGrowthPct = 0,
    this.aiTrailingAssessment = '',
    this.aiGrowthProjection   = '',
    this.aiPeReasoning        = '',
  });

  factory ValuationMetrics.fromJson(Map<String, dynamic> json) {
    MoSZones? zones;
    if (json['mos_zones'] != null && json['mos_zones'] is Map<String, dynamic>) {
      zones = MoSZones.fromJson(json['mos_zones'] as Map<String, dynamic>);
    }
    return ValuationMetrics(
      fairValue:      (json['Fair_Value']      ?? 0).toDouble(),
      upside:         (json['Upside']          ?? 0).toDouble(),
      referencePrice: (json['Reference_Price'] ?? 0).toDouble(),
      eps:            (json['EPS']             ?? 0).toDouble(),
      pe:             (json['PE']              ?? 0).toDouble(),
      aiReasoning:    json['AI_Reasoning']     ?? '',
      mosZones:       zones,
      peEvaluation:   json['pe_evaluation']   ?? '',
      industryPe:     (json['industry_pe']    ?? 0).toDouble(),
      trailingEps:    (json['trailing_eps']   ?? 0).toDouble(),
      yoyGrowthPct:   (json['yoy_growth_pct']  ?? 0).toDouble(),
      aiTrailingAssessment: json['ai_trailing_assessment'] ?? '',
      aiGrowthProjection:   json['ai_growth_projection']  ?? '',
      aiPeReasoning:        json['ai_pe_reasoning']       ?? '',
    );
  }
}

class AnalysisResult {
  final String symbol;
  final double finalScore;
  final String recommendation;
  final List<LayerInfo> layerList;
  final List<RawChartData> chartData;
  final TickerInfo? tickerInfo;
  final V4Metrics? v4Metrics;
  final ValuationMetrics? valuationMetrics;
  final FinancialCalendar? financialCalendar;

  AnalysisResult({
    required this.symbol,
    required this.finalScore,
    required this.recommendation,
    required this.layerList,
    required this.chartData,
    this.tickerInfo,
    this.v4Metrics,
    this.valuationMetrics,
    this.financialCalendar,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final finalAnalysis = data['final_analysis'] ?? {};
    final layersMap = data['layers'] ?? {};
    final chartList = data['chart_data'] as List<dynamic>? ?? [];
    final tInfoMap = data['ticker_info'];
    
    List<LayerInfo> parsedLayers = [];
    final orderedKeys = ['technical', 'smart_money', 'fundamental', 'macro', 'news_rumor', 'intraday'];
    
    for (String key in orderedKeys) {
      if (layersMap[key] != null && layersMap[key] is Map<String, dynamic>) {
        parsedLayers.add(LayerInfo.fromJson(layersMap[key]));
      }
    }
    
    List<RawChartData> parsedChart = chartList.map((e) => RawChartData.fromJson(e)).toList();
    TickerInfo? parsedTicker;
    if (tInfoMap != null && tInfoMap is Map<String, dynamic>) {
      parsedTicker = TickerInfo.fromJson(tInfoMap);
    }
    
    V4Metrics? parsedV4;
    if (finalAnalysis['v4_metrics'] != null) {
      parsedV4 = V4Metrics.fromJson(finalAnalysis['v4_metrics']);
    }

    ValuationMetrics? parsedValuation;
    if (layersMap.containsKey('fundamental') && layersMap['fundamental'] is Map) {
      final fundMap = layersMap['fundamental'];
      if (fundMap.containsKey('metrics') && fundMap['metrics'] is Map) {
        parsedValuation = ValuationMetrics.fromJson(fundMap['metrics']);
      }
    }

    FinancialCalendar? parsedCalendar;
    final calendarMap = data['financial_calendar'];
    if (calendarMap != null && calendarMap is Map<String, dynamic>) {
      parsedCalendar = FinancialCalendar.fromJson(calendarMap);
    }

    return AnalysisResult(
      symbol: json['symbol'] ?? 'UNKNOWN',
      finalScore: (finalAnalysis['final_score'] ?? 0).toDouble(),
      recommendation: finalAnalysis['recommendation'] ?? 'Đang tính toán...',
      layerList: parsedLayers,
      chartData: parsedChart,
      tickerInfo: parsedTicker,
      v4Metrics: parsedV4,
      valuationMetrics: parsedValuation,
      financialCalendar: parsedCalendar,
    );
  }
}

