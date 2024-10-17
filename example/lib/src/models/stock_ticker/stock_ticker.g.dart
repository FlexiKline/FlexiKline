// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_ticker.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StockTickerImpl _$$StockTickerImplFromJson(Map<String, dynamic> json) =>
    _$StockTickerImpl(
      ticker: json['ticker'] as String,
      name: json['name'] as String,
      market: json['market'] as String,
      locale: json['locale'] as String,
      type: json['type'] as String,
      active: json['active'] as bool,
      cik: json['cik'] as String?,
      primaryExchange: json['primary_exchange'] as String,
      currencyName: json['currency_name'] as String,
      lastUpdatedUtc: DateTime.parse(json['last_updated_utc'] as String),
      compositeFigi: json['composite_figi'] as String?,
      shareClassFigistring: json['share_class_figistring'] as String?,
    );

Map<String, dynamic> _$$StockTickerImplToJson(_$StockTickerImpl instance) =>
    <String, dynamic>{
      'ticker': instance.ticker,
      'name': instance.name,
      'market': instance.market,
      'locale': instance.locale,
      'type': instance.type,
      'active': instance.active,
      'cik': instance.cik,
      'primary_exchange': instance.primaryExchange,
      'currency_name': instance.currencyName,
      'last_updated_utc': instance.lastUpdatedUtc.toIso8601String(),
      'composite_figi': instance.compositeFigi,
      'share_class_figistring': instance.shareClassFigistring,
    };
