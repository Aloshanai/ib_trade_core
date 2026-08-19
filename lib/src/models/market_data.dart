/// Historical bar period duration options.
enum BarPeriod {
  oneDay('1d'),
  oneWeek('1w'),
  oneMonth('1m'),
  oneYear('1y');

  final String code;
  const BarPeriod(this.code);
}

/// Historical bar interval size options.
enum BarSize {
  oneMin('1min'),
  twoMin('2min'),
  fiveMin('5min'),
  fifteenMin('15min'),
  oneHour('1h'),
  oneDay('1d');

  final String code;
  const BarSize(this.code);
}

/// Market data request field identifiers for snapshot fields.
enum MarketDataField {
  last('31'),
  bid('84'),
  ask('86'),
  bidSize('85'),
  askSize('88'),
  volume('7295'),
  high('70'),
  low('71'),
  close('7288');

  final String code;
  const MarketDataField(this.code);
}

/// Market data snapshot container.
class MarketSnapshot {
  final int conid;
  final String symbol;
  final double lastPrice;
  final double bidPrice;
  final double askPrice;
  final double bidSize;
  final double askSize;
  final double volume;
  final double high;
  final double low;
  final double closePrice;
  final double change;
  final double changePercent;
  final Map<String, dynamic> raw;

  MarketSnapshot({
    required this.conid,
    required this.symbol,
    required this.lastPrice,
    required this.bidPrice,
    required this.askPrice,
    required this.bidSize,
    required this.askSize,
    required this.volume,
    required this.high,
    required this.low,
    required this.closePrice,
    required this.change,
    required this.changePercent,
    required this.raw,
  });

  factory MarketSnapshot.fromJson(Map<String, dynamic> json) {
    double d(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) {
        if (val.startsWith('C') || val.startsWith('H') || val.startsWith('L')) {
          return double.tryParse(val.substring(1)) ?? 0.0;
        }
        return double.tryParse(val) ?? 0.0;
      }
      return 0.0;
    }

    return MarketSnapshot(
      conid: json['conid'] is int
          ? json['conid'] as int
          : int.tryParse(json['conid']?.toString() ?? '0') ?? 0,
      symbol: (json['55'] ?? json['symbol'] ?? json['ticker'] ?? '').toString(),
      lastPrice: d(json['31'] ?? json['last'] ?? json['lastPrice']),
      bidPrice: d(json['84'] ?? json['bid'] ?? json['bidPrice']),
      askPrice: d(json['86'] ?? json['ask'] ?? json['askPrice']),
      bidSize: d(json['85'] ?? json['bidSize']),
      askSize: d(json['88'] ?? json['askSize']),
      volume: d(json['7295'] ?? json['volume']),
      high: d(json['70'] ?? json['high']),
      low: d(json['71'] ?? json['low']),
      closePrice: d(json['7288'] ?? json['close'] ?? json['closePrice']),
      change: d(json['7282'] ?? json['change']),
      changePercent: d(json['7283'] ?? json['changePercent']),
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;
}

/// Individual OHLCV historical candlestick bar.
class HistoricalBar {
  final int timestamp;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  HistoricalBar({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory HistoricalBar.fromJson(Map<String, dynamic> json) {
    double d(dynamic val) {
      if (val is num) return val.toDouble();
      return double.tryParse(val?.toString() ?? '0.0') ?? 0.0;
    }

    int t(dynamic val) {
      if (val is int) return val;
      return int.tryParse(val?.toString() ?? '0') ?? 0;
    }

    return HistoricalBar(
      timestamp: t(json['t'] ?? json['timestamp'] ?? json['time']),
      open: d(json['o'] ?? json['open']),
      high: d(json['h'] ?? json['high']),
      low: d(json['l'] ?? json['low']),
      close: d(json['c'] ?? json['close']),
      volume: d(json['v'] ?? json['volume']),
    );
  }

  Map<String, dynamic> toJson() => {
        't': timestamp,
        'o': open,
        'h': high,
        'l': low,
        'c': close,
        'v': volume,
      };
}

/// Historical bar data series payload.
class HistoricalDataSeries {
  final int conid;
  final String symbol;
  final String period;
  final String barSize;
  final List<HistoricalBar> bars;

  HistoricalDataSeries({
    required this.conid,
    required this.symbol,
    required this.period,
    required this.barSize,
    required this.bars,
  });

  factory HistoricalDataSeries.fromJson(Map<String, dynamic> json) {
    final rawBars = json['data'] ?? json['bars'] ?? json['candles'];
    final parsedBars = <HistoricalBar>[];
    if (rawBars is List) {
      for (final b in rawBars) {
        if (b is Map<String, dynamic>) {
          parsedBars.add(HistoricalBar.fromJson(b));
        }
      }
    }

    return HistoricalDataSeries(
      conid: json['conid'] is int
          ? json['conid'] as int
          : int.tryParse(json['conid']?.toString() ?? '0') ?? 0,
      symbol: (json['symbol'] ?? json['ticker'] ?? '').toString(),
      period: (json['period'] ?? '').toString(),
      barSize: (json['barSize'] ?? json['bar_size'] ?? '').toString(),
      bars: parsedBars,
    );
  }

  Map<String, dynamic> toJson() => {
        'conid': conid,
        'symbol': symbol,
        'period': period,
        'barSize': barSize,
        'bars': bars.map((b) => b.toJson()).toList(),
      };
}
