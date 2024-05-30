// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'candle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CandleIndicator _$CandleIndicatorFromJson(Map<String, dynamic> json) =>
    CandleIndicator(
      key: json['key'] == null
          ? candleKey
          : const ValueKeyConverter().fromJson(json['key'] as String),
      name: json['name'] as String? ?? 'Candle',
      height: (json['height'] as num).toDouble(),
      padding: json['padding'] == null
          ? defaultMainIndicatorPadding
          : const EdgeInsetsConverter()
              .fromJson(json['padding'] as Map<String, dynamic>),
      high: MarkConfig.fromJson(json['high'] as Map<String, dynamic>),
      low: MarkConfig.fromJson(json['low'] as Map<String, dynamic>),
      last: MarkConfig.fromJson(json['last'] as Map<String, dynamic>),
      latest: MarkConfig.fromJson(json['latest'] as Map<String, dynamic>),
      useCandleColorAsLatestBg:
          json['useCandleColorAsLatestBg'] as bool? ?? true,
      showCountDown: json['showCountDown'] as bool? ?? true,
      countDown:
          TextAreaConfig.fromJson(json['countDown'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CandleIndicatorToJson(CandleIndicator instance) =>
    <String, dynamic>{
      'key': const ValueKeyConverter().toJson(instance.key),
      'name': instance.name,
      'height': instance.height,
      'padding': const EdgeInsetsConverter().toJson(instance.padding),
      'high': instance.high.toJson(),
      'low': instance.low.toJson(),
      'last': instance.last.toJson(),
      'latest': instance.latest.toJson(),
      'useCandleColorAsLatestBg': instance.useCandleColorAsLatestBg,
      'showCountDown': instance.showCountDown,
      'countDown': instance.countDown.toJson(),
    };
