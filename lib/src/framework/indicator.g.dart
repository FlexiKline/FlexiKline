// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'indicator.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MultiPaintObjectIndicator<T>
    _$MultiPaintObjectIndicatorFromJson<T extends SinglePaintObjectIndicator>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) =>
        MultiPaintObjectIndicator<T>(
          key: const ValueKeyConverter().fromJson(json['key'] as String),
          name: json['name'] as String,
          height: (json['height'] as num).toDouble(),
          tipsHeight: (json['tipsHeight'] as num?)?.toDouble() ?? 0.0,
          padding: json['padding'] == null
              ? EdgeInsets.zero
              : const EdgeInsetsConverter()
                  .fromJson(json['padding'] as Map<String, double>),
          drawChartAlawaysBelowTipsArea:
              json['drawChartAlawaysBelowTipsArea'] as bool? ?? false,
          children:
              (json['children'] as List<dynamic>?)?.map(fromJsonT) ?? const [],
        );

Map<String, dynamic>
    _$MultiPaintObjectIndicatorToJson<T extends SinglePaintObjectIndicator>(
  MultiPaintObjectIndicator<T> instance,
  Object? Function(T value) toJsonT,
) =>
        <String, dynamic>{
          'key': const ValueKeyConverter().toJson(instance.key),
          'name': instance.name,
          'height': instance.height,
          'tipsHeight': instance.tipsHeight,
          'padding': const EdgeInsetsConverter().toJson(instance.padding),
          'children': instance.children.map(toJsonT).toList(),
          'drawChartAlawaysBelowTipsArea':
              instance.drawChartAlawaysBelowTipsArea,
        };
