// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimeIndicator _$TimeIndicatorFromJson(Map<String, dynamic> json) =>
    TimeIndicator(
      key: json['key'] == null
          ? timeKey
          : const ValueKeyConverter().fromJson(json['key'] as String),
      name: json['name'] as String? ?? 'Time',
      height:
          (json['height'] as num?)?.toDouble() ?? defaultTimeIndicatorHeight,
      padding: json['padding'] == null
          ? EdgeInsets.zero
          : const EdgeInsetsConverter()
              .fromJson(json['padding'] as Map<String, dynamic>),
      position: json['position'] == null
          ? DrawPosition.middle
          : const DrawPositionConverter().fromJson(json['position'] as String),
      timeTick: json['timeTick'] == null
          ? const TextAreaConfig(
              style: TextStyle(
                  fontSize: defaulTextSize,
                  color: Colors.black,
                  overflow: TextOverflow.ellipsis,
                  height: defaultTextHeight),
              textWidth: 80,
              textAlign: TextAlign.center)
          : TextAreaConfig.fromJson(json['timeTick'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TimeIndicatorToJson(TimeIndicator instance) =>
    <String, dynamic>{
      'key': const ValueKeyConverter().toJson(instance.key),
      'name': instance.name,
      'height': instance.height,
      'padding': const EdgeInsetsConverter().toJson(instance.padding),
      'timeTick': instance.timeTick.toJson(),
      'position': const DrawPositionConverter().toJson(instance.position),
    };
