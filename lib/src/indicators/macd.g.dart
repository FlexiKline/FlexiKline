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
          ? macdKey
          : const ValueKeyConverter().fromJson(json['key'] as String),
      name: json['name'] as String? ?? 'MACD',
      height: (json['height'] as num?)?.toDouble() ?? defaultSubIndicatorHeight,
      tipsHeight: (json['tipsHeight'] as num?)?.toDouble() ??
          defaultIndicatorTipsHeight,
      padding: json['padding'] == null
          ? defaultIndicatorPadding
          : const EdgeInsetsConverter()
              .fromJson(json['padding'] as Map<String, dynamic>),
      calcParam: json['calcParam'] == null
          ? const MACDParam(s: 12, l: 26, m: 9)
          : MACDParam.fromJson(json['calcParam'] as Map<String, dynamic>),
      difTips: json['difTips'] == null
          ? const TipsConfig(
              label: 'DIF: ',
              precision: 2,
              style: TextStyle(
                  fontSize: defaulTextSize,
                  color: Color(0xFFDFBF47),
                  overflow: TextOverflow.ellipsis,
                  height: defaultTipsTextHeight))
          : TipsConfig.fromJson(json['difTips'] as Map<String, dynamic>),
      deaTips: json['deaTips'] == null
          ? const TipsConfig(
              label: 'DEA: ',
              precision: 2,
              style: TextStyle(
                  fontSize: defaulTextSize,
                  color: Color(0xFF795583),
                  overflow: TextOverflow.ellipsis,
                  height: defaultTipsTextHeight))
          : TipsConfig.fromJson(json['deaTips'] as Map<String, dynamic>),
      macdTips: json['macdTips'] == null
          ? const TipsConfig(
              label: 'MACD: ',
              precision: 2,
              style: TextStyle(
                  fontSize: defaulTextSize,
                  color: Colors.black,
                  overflow: TextOverflow.ellipsis,
                  height: defaultTipsTextHeight))
          : TipsConfig.fromJson(json['macdTips'] as Map<String, dynamic>),
      tipsPadding: json['tipsPadding'] == null
          ? defaultTipsPadding
          : const EdgeInsetsConverter()
              .fromJson(json['tipsPadding'] as Map<String, dynamic>),
      tickCount: (json['tickCount'] as num?)?.toInt() ?? defaultSubTickCount,
      lineWidth:
          (json['lineWidth'] as num?)?.toDouble() ?? defaultIndicatorLineWidth,
    );

Map<String, dynamic> _$MACDIndicatorToJson(MACDIndicator instance) =>
    <String, dynamic>{
      'key': const ValueKeyConverter().toJson(instance.key),
      'name': instance.name,
      'height': instance.height,
      'tipsHeight': instance.tipsHeight,
      'padding': const EdgeInsetsConverter().toJson(instance.padding),
      'calcParam': instance.calcParam.toJson(),
      'difTips': instance.difTips.toJson(),
      'deaTips': instance.deaTips.toJson(),
      'macdTips': instance.macdTips.toJson(),
      'tipsPadding': const EdgeInsetsConverter().toJson(instance.tipsPadding),
      'tickCount': instance.tickCount,
      'lineWidth': instance.lineWidth,
    };
