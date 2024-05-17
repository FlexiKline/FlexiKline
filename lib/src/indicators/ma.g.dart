// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ma.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MAIndicator _$MAIndicatorFromJson(Map<String, dynamic> json) => MAIndicator(
      key: json['key'] == null
          ? maKey
          : const ValueKeyConverter().fromJson(json['key'] as String),
      name: json['name'] as String? ?? 'MA',
      height: (json['height'] as num).toDouble(),
      padding: json['padding'] == null
          ? defaultMainIndicatorPadding
          : const EdgeInsetsConverter()
              .fromJson(json['padding'] as Map<String, dynamic>),
      calcParams: (json['calcParams'] as List<dynamic>?)
              ?.map((e) => MaParam.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [
            MaParam(
                count: 7,
                tips: TipsConfig(
                    label: 'MA7: ',
                    style: TextStyle(
                        fontSize: defaulTextSize,
                        color: Color(0xFF946F9A),
                        overflow: TextOverflow.ellipsis,
                        height: defaultTipsTextHeight))),
            MaParam(
                count: 30,
                tips: TipsConfig(
                    label: 'MA30: ',
                    style: TextStyle(
                        fontSize: defaulTextSize,
                        color: Color(0xFFF1BF32),
                        overflow: TextOverflow.ellipsis,
                        height: defaultTipsTextHeight)))
          ],
      tipsPadding: json['tipsPadding'] == null
          ? defaultTipsPadding
          : const EdgeInsetsConverter()
              .fromJson(json['tipsPadding'] as Map<String, dynamic>),
      lineWidth:
          (json['lineWidth'] as num?)?.toDouble() ?? defaultIndicatorLineWidth,
    );

Map<String, dynamic> _$MAIndicatorToJson(MAIndicator instance) =>
    <String, dynamic>{
      'key': const ValueKeyConverter().toJson(instance.key),
      'name': instance.name,
      'height': instance.height,
      'padding': const EdgeInsetsConverter().toJson(instance.padding),
      'calcParams': instance.calcParams.map((e) => e.toJson()).toList(),
      'tipsPadding': const EdgeInsetsConverter().toJson(instance.tipsPadding),
      'lineWidth': instance.lineWidth,
    };
