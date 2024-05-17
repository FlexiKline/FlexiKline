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
      padding: json['padding'] == null
          ? defaultSubIndicatorPadding
          : const EdgeInsetsConverter()
              .fromJson(json['padding'] as Map<String, dynamic>),
      paintMode: json['paintMode'] == null
          ? PaintMode.combine
          : const PaintModeConverter().fromJson(json['paintMode'] as String),
      volTips: json['volTips'] == null
          ? const TipsConfig(
              label: 'Vol: ',
              precision: 2,
              style: TextStyle(
                  fontSize: defaulTextSize,
                  color: Colors.black,
                  overflow: TextOverflow.ellipsis,
                  height: defaultTipsTextHeight))
          : TipsConfig.fromJson(json['volTips'] as Map<String, dynamic>),
      tipsPadding: json['tipsPadding'] == null
          ? defaultTipsPadding
          : const EdgeInsetsConverter()
              .fromJson(json['tipsPadding'] as Map<String, dynamic>),
      tickCount: (json['tickCount'] as num?)?.toInt() ?? defaultSubTickCount,
      precision: (json['precision'] as num?)?.toInt() ?? 2,
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
      'padding': const EdgeInsetsConverter().toJson(instance.padding),
      'paintMode': const PaintModeConverter().toJson(instance.paintMode),
      'volTips': instance.volTips.toJson(),
      'tipsPadding': const EdgeInsetsConverter().toJson(instance.tipsPadding),
      'tickCount': instance.tickCount,
      'precision': instance.precision,
      'showYAxisTick': instance.showYAxisTick,
      'showCrossMark': instance.showCrossMark,
      'showTips': instance.showTips,
      'useTint': instance.useTint,
    };
