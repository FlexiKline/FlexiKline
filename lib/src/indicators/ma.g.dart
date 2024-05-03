// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ma.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MaParam _$MaParamFromJson(Map<String, dynamic> json) => MaParam(
      label: json['label'] as String,
      count: (json['count'] as num).toInt(),
      color: const ColorConverter().fromJson(json['color'] as String?),
    );

Map<String, dynamic> _$MaParamToJson(MaParam instance) => <String, dynamic>{
      'label': instance.label,
      'count': instance.count,
      'color': const ColorConverter().toJson(instance.color),
    };

MAIndicator _$MAIndicatorFromJson(Map<String, dynamic> json) => MAIndicator(
      key: json['key'] == null
          ? const ValueKey(IndicatorType.ma)
          : const ValueKeyConverter().fromJson(json['key'] as String),
      name: json['name'] as String? ?? 'MA',
      height: (json['height'] as num).toDouble(),
      tipsHeight: (json['tipsHeight'] as num?)?.toDouble() ??
          defaultIndicatorTipsHeight,
      padding: json['padding'] == null
          ? EdgeInsets.zero
          : const EdgeInsetsConverter()
              .fromJson(json['padding'] as Map<String, double>),
      calcParams: (json['calcParams'] as List<dynamic>?)
              ?.map((e) => MaParam.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [
            MaParam(label: 'MA7', count: 7, color: Color(0xFF946F9A)),
            MaParam(label: 'MA30', count: 30, color: Color(0xFFF1BF32))
          ],
    );

Map<String, dynamic> _$MAIndicatorToJson(MAIndicator instance) =>
    <String, dynamic>{
      'key': const ValueKeyConverter().toJson(instance.key),
      'name': instance.name,
      'height': instance.height,
      'tipsHeight': instance.tipsHeight,
      'padding': const EdgeInsetsConverter().toJson(instance.padding),
      'calcParams': instance.calcParams.map((e) => e.toJson()).toList(),
    };
