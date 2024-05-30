// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'macd.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MACDIndicator _$MACDIndicatorFromJson(Map<String, dynamic> json) =>
    MACDIndicator(
      key: json['key'] == null
          ? macdKey
          : const ValueKeyConverter().fromJson(json['key'] as String),
      name: json['name'] as String? ?? 'MACD',
      height: (json['height'] as num?)?.toDouble() ?? defaultSubIndicatorHeight,
      padding: json['padding'] == null
          ? defaultSubIndicatorPadding
          : const EdgeInsetsConverter()
              .fromJson(json['padding'] as Map<String, dynamic>),
      calcParam: json['calcParam'] == null
          ? const MACDParam(s: 12, l: 26, m: 9)
          : MACDParam.fromJson(json['calcParam'] as Map<String, dynamic>),
      difTips: TipsConfig.fromJson(json['difTips'] as Map<String, dynamic>),
      deaTips: TipsConfig.fromJson(json['deaTips'] as Map<String, dynamic>),
      macdTips: TipsConfig.fromJson(json['macdTips'] as Map<String, dynamic>),
      tipsPadding: const EdgeInsetsConverter()
          .fromJson(json['tipsPadding'] as Map<String, dynamic>),
      tickCount: (json['tickCount'] as num?)?.toInt() ?? defaultSubTickCount,
      lineWidth: (json['lineWidth'] as num).toDouble(),
      precision: (json['precision'] as num?)?.toInt() ?? 2,
    );

Map<String, dynamic> _$MACDIndicatorToJson(MACDIndicator instance) =>
    <String, dynamic>{
      'key': const ValueKeyConverter().toJson(instance.key),
      'name': instance.name,
      'height': instance.height,
      'padding': const EdgeInsetsConverter().toJson(instance.padding),
      'calcParam': instance.calcParam.toJson(),
      'difTips': instance.difTips.toJson(),
      'deaTips': instance.deaTips.toJson(),
      'macdTips': instance.macdTips.toJson(),
      'tipsPadding': const EdgeInsetsConverter().toJson(instance.tipsPadding),
      'tickCount': instance.tickCount,
      'lineWidth': instance.lineWidth,
      'precision': instance.precision,
    };
