class MarketIndex {
  final double value;
  final double change;
  final double percentChange;

  MarketIndex({required this.value, required this.change, required this.percentChange});

  factory MarketIndex.fromJson(Map<String, dynamic> json) {
    return MarketIndex(
      value: (json['VNINDEX'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      percentChange: (json['percent_change'] ?? 0).toDouble(),
    );
  }
}

class HeatmapStock {
  final String symbol;
  final double percentChange;
  final double value;

  HeatmapStock({required this.symbol, required this.percentChange, required this.value});

  factory HeatmapStock.fromJson(Map<String, dynamic> json) {
    return HeatmapStock(
      symbol: json['symbol'] ?? '',
      percentChange: (json['percent_change'] ?? 0).toDouble(),
      value: (json['value'] ?? 0).toDouble(),
    );
  }
}
