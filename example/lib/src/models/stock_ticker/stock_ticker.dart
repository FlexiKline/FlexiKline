import 'package:freezed_annotation/freezed_annotation.dart';

part 'stock_ticker.freezed.dart';
part 'stock_ticker.g.dart';

@freezed
class StockTicker with _$StockTicker {
  factory StockTicker({
    required String ticker,
    required String name,
    required String market,
    required String locale,
    required String type,
    required bool active,
    String? cik,
    @JsonKey(name: 'primary_exchange') required String primaryExchange,
    @JsonKey(name: 'currency_name') required String currencyName,
    @JsonKey(name: 'last_updated_utc') required DateTime lastUpdatedUtc,
    @JsonKey(name: 'composite_figi') String? compositeFigi,
    @JsonKey(name: 'share_class_figistring') String? shareClassFigistring,
  }) = _StockTicker;

  factory StockTicker.fromJson(Map<String, dynamic> json) =>
      _$StockTickerFromJson(json);
}
