// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'volume.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VolumeIndicator _$VolumeIndicatorFromJson(Map<String, dynamic> json) =>
    VolumeIndicator(
      key: json['key'] == null
          ? volumeKey
          : const ValueKeyConverter().fromJson(json['key'] as String),
      name: json['name'] as String? ?? 'VOL',
      height: (json['height'] as num?)?.toDouble() ?? defaultSubIndicatorHeight,
      tipsHeight: (json['tipsHeight'] as num?)?.toDouble() ?? 0.0,
      padding: json['padding'] == null
          ? EdgeInsets.zero
          : const EdgeInsetsConverter()
              .fromJson(json['padding'] as Map<String, dynamic>),
      paintMode: json['paintMode'] == null
          ? PaintMode.combine
          : const PaintModeConverter().fromJson(json['paintMode'] as String),
      tickCount: (json['tickCount'] as num?)?.toInt(),
      tipsTextColor:
          const ColorConverter().fromJson(json['tipsTextColor'] as String?),
      showYAxisTick: json['showYAxisTick'] as bool? ?? true,
      showCrossMark: json['showCrossMark'] as bool? ?? true,
      showTips: json['showTips'] as bool? ?? true,
      useTint: json['useTint'] as bool? ?? false,
    );

Map<String, dynamic> _$VolumeIndicatorToJson(VolumeIndicator instance) =>
    <String, dynamic>{
      'key': const ValueKeyConverter().toJson(instance.key),
      'name': instance.name,
      'height': instance.height,
      'tipsHeight': instance.tipsHeight,
      'padding': const EdgeInsetsConverter().toJson(instance.padding),
      'paintMode': const PaintModeConverter().toJson(instance.paintMode),
      'tickCount': instance.tickCount,
      'tipsTextColor': _$JsonConverterToJson<String?, Color>(
          instance.tipsTextColor, const ColorConverter().toJson),
      'showYAxisTick': instance.showYAxisTick,
      'showCrossMark': instance.showCrossMark,
      'showTips': instance.showTips,
      'useTint': instance.useTint,
    };

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
