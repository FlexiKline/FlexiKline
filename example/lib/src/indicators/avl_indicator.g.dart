// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'avl_indicator.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AVLIndicator _$AVLIndicatorFromJson(Map<String, dynamic> json) => AVLIndicator(
      key: json['key'] == null
          ? const ValueKey('AVL')
          : const ValueKeyConverter().fromJson(json['key'] as String),
      name: json['name'] as String? ?? 'AVL',
      zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num).toDouble(),
      padding: const EdgeInsetsConverter()
          .fromJson(json['padding'] as Map<String, dynamic>),
      line: LineConfig.fromJson(json['line'] as Map<String, dynamic>),
      tips: TipsConfig.fromJson(json['tips'] as Map<String, dynamic>),
      tipsPadding: const EdgeInsetsConverter()
          .fromJson(json['tipsPadding'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AVLIndicatorToJson(AVLIndicator instance) =>
    <String, dynamic>{
      'key': const ValueKeyConverter().toJson(instance.key),
      'name': instance.name,
      'height': instance.height,
      'padding': const EdgeInsetsConverter().toJson(instance.padding),
      'zIndex': instance.zIndex,
      'line': instance.line.toJson(),
      'tips': instance.tips.toJson(),
      'tipsPadding': const EdgeInsetsConverter().toJson(instance.tipsPadding),
    };
