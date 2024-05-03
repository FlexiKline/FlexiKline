// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'macd.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MACDParam _$MACDParamFromJson(Map<String, dynamic> json) => MACDParam(
      s: (json['s'] as num).toInt(),
      l: (json['l'] as num).toInt(),
      m: (json['m'] as num).toInt(),
    );

Map<String, dynamic> _$MACDParamToJson(MACDParam instance) => <String, dynamic>{
      's': instance.s,
      'l': instance.l,
      'm': instance.m,
    };

MACDIndicator _$MACDIndicatorFromJson(Map<String, dynamic> json) =>
    MACDIndicator(
      key: json['key'] == null
          ? const ValueKey(IndicatorType.macd)
          : const ValueKeyConverter().fromJson(json['key'] as String),
      name: json['name'] as String? ?? 'MACD',
      height: (json['height'] as num?)?.toDouble() ?? defaultSubIndicatorHeight,
      tipsHeight: (json['tipsHeight'] as num?)?.toDouble() ??
          defaultIndicatorTipsHeight,
      padding: json['padding'] == null
          ? defaultIndicatorPadding
          : const EdgeInsetsConverter()
              .fromJson(json['padding'] as Map<String, double>),
      calcParam: json['calcParam'] == null
          ? const MACDParam(s: 12, l: 26, m: 9)
          : MACDParam.fromJson(json['calcParam'] as Map<String, dynamic>),
      difColor: json['difColor'] == null
          ? const Color(0xFFDFBF47)
          : const ColorConverter().fromJson(json['difColor'] as String?),
      deaColor: json['deaColor'] == null
          ? const Color(0xFF795583)
          : const ColorConverter().fromJson(json['deaColor'] as String?),
      macdColor: const ColorConverter().fromJson(json['macdColor'] as String?),
      tickCount: (json['tickCount'] as num?)?.toInt(),
      precision: (json['precision'] as num?)?.toInt() ?? 2,
    );

Map<String, dynamic> _$MACDIndicatorToJson(MACDIndicator instance) =>
    <String, dynamic>{
      'key': const ValueKeyConverter().toJson(instance.key),
      'name': instance.name,
      'height': instance.height,
      'tipsHeight': instance.tipsHeight,
      'padding': const EdgeInsetsConverter().toJson(instance.padding),
      'calcParam': instance.calcParam.toJson(),
      'difColor': const ColorConverter().toJson(instance.difColor),
      'deaColor': const ColorConverter().toJson(instance.deaColor),
      'macdColor': _$JsonConverterToJson<String?, Color>(
          instance.macdColor, const ColorConverter().toJson),
      'tickCount': instance.tickCount,
      'precision': instance.precision,
    };

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
