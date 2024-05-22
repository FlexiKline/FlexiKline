// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kdj.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KDJIndicator _$KDJIndicatorFromJson(Map<String, dynamic> json) => KDJIndicator(
      key: json['key'] == null
          ? const ValueKey(IndicatorType.kdj)
          : const ValueKeyConverter().fromJson(json['key'] as String),
      name: json['name'] as String? ?? 'KDJ',
      height: (json['height'] as num?)?.toDouble() ?? defaultSubIndicatorHeight,
      padding: json['padding'] == null
          ? defaultSubIndicatorPadding
          : const EdgeInsetsConverter()
              .fromJson(json['padding'] as Map<String, dynamic>),
      calcParam: json['calcParam'] == null
          ? const KDJParam(n: 9, m1: 3, m2: 3)
          : KDJParam.fromJson(json['calcParam'] as Map<String, dynamic>),
      ktips: json['ktips'] == null
          ? const TipsConfig(
              label: 'K: ',
              precision: 2,
              style: TextStyle(
                  fontSize: defaulTextSize,
                  color: Color(0xFF7A5C79),
                  overflow: TextOverflow.ellipsis,
                  height: defaultTipsTextHeight))
          : TipsConfig.fromJson(json['ktips'] as Map<String, dynamic>),
      dtips: json['dtips'] == null
          ? const TipsConfig(
              label: 'D: ',
              precision: 2,
              style: TextStyle(
                  fontSize: defaulTextSize,
                  color: Color(0xFFFABD3F),
                  overflow: TextOverflow.ellipsis,
                  height: defaultTipsTextHeight))
          : TipsConfig.fromJson(json['dtips'] as Map<String, dynamic>),
      jtips: json['jtips'] == null
          ? const TipsConfig(
              label: 'D: ',
              precision: 2,
              style: TextStyle(
                  fontSize: defaulTextSize,
                  color: Color(0xFFBB72CA),
                  overflow: TextOverflow.ellipsis,
                  height: defaultTipsTextHeight))
          : TipsConfig.fromJson(json['jtips'] as Map<String, dynamic>),
      tipsPadding: json['tipsPadding'] == null
          ? defaultTipsPadding
          : const EdgeInsetsConverter()
              .fromJson(json['tipsPadding'] as Map<String, dynamic>),
      tickCount: (json['tickCount'] as num?)?.toInt() ?? defaultSubTickCount,
      lineWidth:
          (json['lineWidth'] as num?)?.toDouble() ?? defaultIndicatorLineWidth,
      precision: (json['precision'] as num?)?.toInt() ?? 2,
    );

Map<String, dynamic> _$KDJIndicatorToJson(KDJIndicator instance) =>
    <String, dynamic>{
      'key': const ValueKeyConverter().toJson(instance.key),
      'name': instance.name,
      'height': instance.height,
      'padding': const EdgeInsetsConverter().toJson(instance.padding),
      'calcParam': instance.calcParam.toJson(),
      'ktips': instance.ktips.toJson(),
      'dtips': instance.dtips.toJson(),
      'jtips': instance.jtips.toJson(),
      'tipsPadding': const EdgeInsetsConverter().toJson(instance.tipsPadding),
      'tickCount': instance.tickCount,
      'lineWidth': instance.lineWidth,
      'precision': instance.precision,
    };
