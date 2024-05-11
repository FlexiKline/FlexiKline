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
      tipsHeight: (json['tipsHeight'] as num?)?.toDouble() ?? 0.0,
      padding: json['padding'] == null
          ? defaultIndicatorPadding
          : const EdgeInsetsConverter()
              .fromJson(json['padding'] as Map<String, dynamic>),
      isShowLatestPrice: json['isShowLatestPrice'] as bool? ?? true,
      isShowCountDownTime: json['isShowCountDownTime'] as bool? ?? true,
      isShowLastestPriceWhenMoveOffDrawArea:
          json['isShowLastestPriceWhenMoveOffDrawArea'] as bool? ?? true,
      latestPriceTextStyle:
          _$JsonConverterFromJson<Map<String, dynamic>, TextStyle>(
              json['latestPriceTextStyle'],
              const TextStyleConverter().fromJson),
      countDownTimeTextStyle:
          _$JsonConverterFromJson<Map<String, dynamic>, TextStyle>(
              json['countDownTimeTextStyle'],
              const TextStyleConverter().fromJson),
      timeTickTextStyle:
          _$JsonConverterFromJson<Map<String, dynamic>, TextStyle>(
              json['timeTickTextStyle'], const TextStyleConverter().fromJson),
      timeTickTextWidth: (json['timeTickTextWidth'] as num?)?.toDouble() ?? 80,
      yAxisTickTextStyle:
          _$JsonConverterFromJson<Map<String, dynamic>, TextStyle>(
              json['yAxisTickTextStyle'], const TextStyleConverter().fromJson),
      yAxisTickRectPadding:
          _$JsonConverterFromJson<Map<String, dynamic>, EdgeInsets>(
              json['yAxisTickRectPadding'],
              const EdgeInsetsConverter().fromJson),
      latestPriceRectBackgroundColor: const ColorConverter()
          .fromJson(json['latestPriceRectBackgroundColor'] as String?),
      latestPriceRectBorderRadius:
          (json['latestPriceRectBorderRadius'] as num?)?.toDouble() ?? 2,
      latestPriceRectBorderWidth:
          (json['latestPriceRectBorderWidth'] as num?)?.toDouble() ?? 0.5,
      latestPriceRectRightMinMargin:
          (json['latestPriceRectRightMinMargin'] as num?)?.toDouble() ?? 1,
      latestPriceRectRightMaxMargin:
          (json['latestPriceRectRightMaxMargin'] as num?)?.toDouble() ?? 60,
      latestPriceRectBorderColor: const ColorConverter()
          .fromJson(json['latestPriceRectBorderColor'] as String?),
      latestPriceRectPadding: json['latestPriceRectPadding'] == null
          ? const EdgeInsets.symmetric(horizontal: 2, vertical: 2)
          : const EdgeInsetsConverter()
              .fromJson(json['latestPriceRectPadding'] as Map<String, dynamic>),
      latestPriceMarkLineColor: const ColorConverter()
          .fromJson(json['latestPriceMarkLineColor'] as String?),
      latestPriceMarkLineWidth:
          (json['latestPriceMarkLineWidth'] as num?)?.toDouble(),
      latestPriceMarkLineDashes:
          (json['latestPriceMarkLineDashes'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList(),
      isShowMaxminPriceMark: json['isShowMaxminPriceMark'] as bool? ?? true,
      maxminPriceTextStyle:
          _$JsonConverterFromJson<Map<String, dynamic>, TextStyle>(
              json['maxminPriceTextStyle'],
              const TextStyleConverter().fromJson),
      maxminPriceMargin: (json['maxminPriceMargin'] as num?)?.toDouble() ?? 1,
      maxminPriceLineLength:
          (json['maxminPriceLineLength'] as num?)?.toDouble() ?? 20,
      maxminPriceLineWidth: (json['maxminPriceLineWidth'] as num?)?.toDouble(),
      maxminPriceLineColor: const ColorConverter()
          .fromJson(json['maxminPriceLineColor'] as String?),
    );

Map<String, dynamic> _$CandleIndicatorToJson(CandleIndicator instance) =>
    <String, dynamic>{
      'key': const ValueKeyConverter().toJson(instance.key),
      'name': instance.name,
      'height': instance.height,
      'tipsHeight': instance.tipsHeight,
      'padding': const EdgeInsetsConverter().toJson(instance.padding),
      'isShowLatestPrice': instance.isShowLatestPrice,
      'isShowCountDownTime': instance.isShowCountDownTime,
      'isShowLastestPriceWhenMoveOffDrawArea':
          instance.isShowLastestPriceWhenMoveOffDrawArea,
      'latestPriceTextStyle':
          _$JsonConverterToJson<Map<String, dynamic>, TextStyle>(
              instance.latestPriceTextStyle, const TextStyleConverter().toJson),
      'countDownTimeTextStyle':
          _$JsonConverterToJson<Map<String, dynamic>, TextStyle>(
              instance.countDownTimeTextStyle,
              const TextStyleConverter().toJson),
      'timeTickTextStyle':
          _$JsonConverterToJson<Map<String, dynamic>, TextStyle>(
              instance.timeTickTextStyle, const TextStyleConverter().toJson),
      'timeTickTextWidth': instance.timeTickTextWidth,
      'yAxisTickTextStyle':
          _$JsonConverterToJson<Map<String, dynamic>, TextStyle>(
              instance.yAxisTickTextStyle, const TextStyleConverter().toJson),
      'yAxisTickRectPadding':
          _$JsonConverterToJson<Map<String, dynamic>, EdgeInsets>(
              instance.yAxisTickRectPadding,
              const EdgeInsetsConverter().toJson),
      'latestPriceRectBackgroundColor': _$JsonConverterToJson<String?, Color>(
          instance.latestPriceRectBackgroundColor,
          const ColorConverter().toJson),
      'latestPriceRectBorderRadius': instance.latestPriceRectBorderRadius,
      'latestPriceRectBorderWidth': instance.latestPriceRectBorderWidth,
      'latestPriceRectRightMinMargin': instance.latestPriceRectRightMinMargin,
      'latestPriceRectRightMaxMargin': instance.latestPriceRectRightMaxMargin,
      'latestPriceRectBorderColor': _$JsonConverterToJson<String?, Color>(
          instance.latestPriceRectBorderColor, const ColorConverter().toJson),
      'latestPriceRectPadding':
          const EdgeInsetsConverter().toJson(instance.latestPriceRectPadding),
      'latestPriceMarkLineColor': _$JsonConverterToJson<String?, Color>(
          instance.latestPriceMarkLineColor, const ColorConverter().toJson),
      'latestPriceMarkLineWidth': instance.latestPriceMarkLineWidth,
      'latestPriceMarkLineDashes': instance.latestPriceMarkLineDashes,
      'isShowMaxminPriceMark': instance.isShowMaxminPriceMark,
      'maxminPriceTextStyle':
          _$JsonConverterToJson<Map<String, dynamic>, TextStyle>(
              instance.maxminPriceTextStyle, const TextStyleConverter().toJson),
      'maxminPriceMargin': instance.maxminPriceMargin,
      'maxminPriceLineLength': instance.maxminPriceLineLength,
      'maxminPriceLineWidth': instance.maxminPriceLineWidth,
      'maxminPriceLineColor': _$JsonConverterToJson<String?, Color>(
          instance.maxminPriceLineColor, const ColorConverter().toJson),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
