// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ma_vol.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MAVolIndicator _$MAVolIndicatorFromJson(Map<String, dynamic> json) =>
    MAVolIndicator(
      key: json['key'] == null
          ? const ValueKey(IndicatorType.maVol)
          : const ValueKeyConverter().fromJson(json['key'] as String),
      name: json['name'] as String? ?? 'MAVOL',
      height: (json['height'] as num).toDouble(),
      tipsHeight: (json['tipsHeight'] as num?)?.toDouble() ?? 0.0,
      padding: json['padding'] == null
          ? EdgeInsets.zero
          : const EdgeInsetsConverter()
              .fromJson(json['padding'] as Map<String, double>),
      calcParams: (json['calcParams'] as List<dynamic>?)
              ?.map((e) => MaParam.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [
            MaParam(label: 'MA5', count: 5, color: Colors.orange),
            MaParam(label: 'MA10', count: 10, color: Colors.blue)
          ],
    );

Map<String, dynamic> _$MAVolIndicatorToJson(MAVolIndicator instance) =>
    <String, dynamic>{
      'key': const ValueKeyConverter().toJson(instance.key),
      'name': instance.name,
      'height': instance.height,
      'tipsHeight': instance.tipsHeight,
      'padding': const EdgeInsetsConverter().toJson(instance.padding),
      'calcParams': instance.calcParams.map((e) => e.toJson()).toList(),
    };
