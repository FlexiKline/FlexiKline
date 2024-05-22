// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'boll.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BOLLIndicator _$BOLLIndicatorFromJson(Map<String, dynamic> json) =>
    BOLLIndicator(
      key: json['key'] == null
          ? bollKey
          : const ValueKeyConverter().fromJson(json['key'] as String),
      name: json['name'] as String? ?? 'BOLL',
      height: (json['height'] as num).toDouble(),
      padding: json['padding'] == null
          ? defaultMainIndicatorPadding
          : const EdgeInsetsConverter()
              .fromJson(json['padding'] as Map<String, dynamic>),
      calcParam: json['calcParam'] == null
          ? const BOLLParam(n: 20, std: 2)
          : BOLLParam.fromJson(json['calcParam'] as Map<String, dynamic>),
      mbTips: json['mbTips'] == null
          ? const TipsConfig(
              label: 'BOLL(20): ',
              style: TextStyle(
                  fontSize: defaulTextSize,
                  color: Color(0xFF886787),
                  overflow: TextOverflow.ellipsis,
                  height: defaultTipsTextHeight))
          : TipsConfig.fromJson(json['mbTips'] as Map<String, dynamic>),
      upTips: json['upTips'] == null
          ? const TipsConfig(
              label: 'UB: ',
              style: TextStyle(
                  fontSize: defaulTextSize,
                  color: Color(0xFFF0B527),
                  overflow: TextOverflow.ellipsis,
                  height: defaultTipsTextHeight))
          : TipsConfig.fromJson(json['upTips'] as Map<String, dynamic>),
      dnTips: json['dnTips'] == null
          ? const TipsConfig(
              label: 'LB: ',
              style: TextStyle(
                  fontSize: defaulTextSize,
                  color: Color(0xFFD85BE0),
                  overflow: TextOverflow.ellipsis,
                  height: defaultTipsTextHeight))
          : TipsConfig.fromJson(json['dnTips'] as Map<String, dynamic>),
      tipsPadding: json['tipsPadding'] == null
          ? defaultTipsPadding
          : const EdgeInsetsConverter()
              .fromJson(json['tipsPadding'] as Map<String, dynamic>),
      lineWidth:
          (json['lineWidth'] as num?)?.toDouble() ?? defaultIndicatorLineWidth,
      isFillBetweenUpAndDn: json['isFillBetweenUpAndDn'] as bool? ?? true,
      fillColor: const ColorConverter().fromJson(json['fillColor'] as String?),
    );

Map<String, dynamic> _$BOLLIndicatorToJson(BOLLIndicator instance) =>
    <String, dynamic>{
      'key': const ValueKeyConverter().toJson(instance.key),
      'name': instance.name,
      'height': instance.height,
      'padding': const EdgeInsetsConverter().toJson(instance.padding),
      'calcParam': instance.calcParam.toJson(),
      'mbTips': instance.mbTips.toJson(),
      'upTips': instance.upTips.toJson(),
      'dnTips': instance.dnTips.toJson(),
      'tipsPadding': const EdgeInsetsConverter().toJson(instance.tipsPadding),
      'lineWidth': instance.lineWidth,
      'isFillBetweenUpAndDn': instance.isFillBetweenUpAndDn,
      'fillColor': const ColorConverter().toJson(instance.fillColor),
    };
