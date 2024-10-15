// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'overlay.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Point _$PointFromJson(Map<String, dynamic> json) => Point(
      index: (json['index'] as num?)?.toInt() ?? -1,
      ts: (json['ts'] as num?)?.toInt() ?? -1,
      value: json['value'] == null
          ? BagNum.zero
          : const BagNumConverter().fromJson(json['value']),
      patch: (json['patch'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$PointToJson(Point instance) => <String, dynamic>{
      'index': instance.index,
      'ts': instance.ts,
      'value': const BagNumConverter().toJson(instance.value),
      'patch': instance.patch,
    };

Overlay _$OverlayFromJson(Map<String, dynamic> json) => Overlay(
      key: json['key'] as String,
      type: const IDrawTypeConverter()
          .fromJson(json['type'] as Map<String, dynamic>),
      zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
      lock: json['lock'] as bool? ?? false,
      mode: json['mode'] == null
          ? MagnetMode.normal
          : const MagnetModeConverter().fromJson(json['mode'] as String),
      line: LineConfig.fromJson(json['line'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$OverlayToJson(Overlay instance) => <String, dynamic>{
      'key': instance.key,
      'type': const IDrawTypeConverter().toJson(instance.type),
      'zIndex': instance.zIndex,
      'lock': instance.lock,
      'mode': const MagnetModeConverter().toJson(instance.mode),
      'line': instance.line.toJson(),
    };
