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
      tickTextStyle: _$JsonConverterFromJson<Map<String, dynamic>, TextStyle>(
          json['tickTextStyle'], const TextStyleConverter().fromJson),
      tickPadding: _$JsonConverterFromJson<Map<String, dynamic>, EdgeInsets>(
          json['tickPadding'], const EdgeInsetsConverter().fromJson),
      latestPriceBackground: const ColorConverter()
          .fromJson(json['latestPriceBackground'] as String?),
      latestPriceRectRadius:
          _$JsonConverterFromJson<Map<String, dynamic>, BorderRadius>(
              json['latestPriceRectRadius'],
              const BorderRadiusConverter().fromJson),
      latestPriceBorder:
          _$JsonConverterFromJson<Map<String, dynamic>, BorderSide>(
              json['latestPriceBorder'], const BorderSideConvert().fromJson),
      latestPriceRectPadding:
          _$JsonConverterFromJson<Map<String, dynamic>, EdgeInsets>(
              json['latestPriceRectPadding'],
              const EdgeInsetsConverter().fromJson),
      latestPriceRectRightMinMargin:
          (json['latestPriceRectRightMinMargin'] as num?)?.toDouble() ?? 1,
      latestPriceRectRightMaxMargin:
          (json['latestPriceRectRightMaxMargin'] as num?)?.toDouble() ?? 60,
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
      maxminMarkLineLength:
          (json['maxminMarkLineLength'] as num?)?.toDouble() ?? 20,
      maxminMarkLineWidth: (json['maxminMarkLineWidth'] as num?)?.toDouble(),
      maxminMarkLineColor: const ColorConverter()
          .fromJson(json['maxminMarkLineColor'] as String?),
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
      'tickTextStyle': _$JsonConverterToJson<Map<String, dynamic>, TextStyle>(
          instance.tickTextStyle, const TextStyleConverter().toJson),
      'tickPadding': _$JsonConverterToJson<Map<String, dynamic>, EdgeInsets>(
          instance.tickPadding, const EdgeInsetsConverter().toJson),
      'latestPriceBackground': _$JsonConverterToJson<String?, Color>(
          instance.latestPriceBackground, const ColorConverter().toJson),
      'latestPriceRectRadius':
          _$JsonConverterToJson<Map<String, dynamic>, BorderRadius>(
              instance.latestPriceRectRadius,
              const BorderRadiusConverter().toJson),
      'latestPriceBorder':
          _$JsonConverterToJson<Map<String, dynamic>, BorderSide>(
              instance.latestPriceBorder, const BorderSideConvert().toJson),
      'latestPriceRectPadding':
          _$JsonConverterToJson<Map<String, dynamic>, EdgeInsets>(
              instance.latestPriceRectPadding,
              const EdgeInsetsConverter().toJson),
      'latestPriceRectRightMinMargin': instance.latestPriceRectRightMinMargin,
      'latestPriceRectRightMaxMargin': instance.latestPriceRectRightMaxMargin,
      'latestPriceMarkLineColor': _$JsonConverterToJson<String?, Color>(
          instance.latestPriceMarkLineColor, const ColorConverter().toJson),
      'latestPriceMarkLineWidth': instance.latestPriceMarkLineWidth,
      'latestPriceMarkLineDashes': instance.latestPriceMarkLineDashes,
      'isShowMaxminPriceMark': instance.isShowMaxminPriceMark,
      'maxminPriceTextStyle':
          _$JsonConverterToJson<Map<String, dynamic>, TextStyle>(
              instance.maxminPriceTextStyle, const TextStyleConverter().toJson),
      'maxminPriceMargin': instance.maxminPriceMargin,
      'maxminMarkLineLength': instance.maxminMarkLineLength,
      'maxminMarkLineWidth': instance.maxminMarkLineWidth,
      'maxminMarkLineColor': _$JsonConverterToJson<String?, Color>(
          instance.maxminMarkLineColor, const ColorConverter().toJson),
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
