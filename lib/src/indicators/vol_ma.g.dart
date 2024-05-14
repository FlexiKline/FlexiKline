// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vol_ma.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VolMaIndicator _$VolMaIndicatorFromJson(Map<String, dynamic> json) =>
    VolMaIndicator(
      key: json['key'] == null
          ? volMaKey
          : const ValueKeyConverter().fromJson(json['key'] as String),
      name: json['name'] as String? ?? 'VOLMA',
      height: (json['height'] as num?)?.toDouble() ?? defaultSubIndicatorHeight,
      tipsHeight: (json['tipsHeight'] as num?)?.toDouble() ??
          defaultIndicatorTipsHeight,
      padding: json['padding'] == null
          ? defaultIndicatorPadding
          : const EdgeInsetsConverter()
              .fromJson(json['padding'] as Map<String, dynamic>),
      calcParams: (json['calcParams'] as List<dynamic>?)
              ?.map((e) => MaParam.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [
            MaParam(label: 'MA5', count: 5, color: Colors.orange),
            MaParam(label: 'MA10', count: 10, color: Colors.blue)
          ],
    );

Map<String, dynamic> _$VolMaIndicatorToJson(VolMaIndicator instance) =>
    <String, dynamic>{
      'key': const ValueKeyConverter().toJson(instance.key),
      'name': instance.name,
      'height': instance.height,
      'tipsHeight': instance.tipsHeight,
      'padding': const EdgeInsetsConverter().toJson(instance.padding),
      'calcParams': instance.calcParams.map((e) => e.toJson()).toList(),
    };
