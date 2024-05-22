// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ma_volume.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MAVolumeIndicator _$MAVolumeIndicatorFromJson(Map<String, dynamic> json) =>
    MAVolumeIndicator(
      key: json['key'] == null
          ? maVolKey
          : const ValueKeyConverter().fromJson(json['key'] as String),
      name: json['name'] as String? ?? 'MAVOL',
      height: (json['height'] as num?)?.toDouble() ?? defaultSubIndicatorHeight,
      padding: json['padding'] == null
          ? defaultSubIndicatorPadding
          : const EdgeInsetsConverter()
              .fromJson(json['padding'] as Map<String, dynamic>),
      drawBelowTipsArea: json['drawBelowTipsArea'] as bool? ?? false,
      volumeIndicator: VolumeIndicator.fromJson(
          json['volumeIndicator'] as Map<String, dynamic>),
      volMaIndicator: VolMaIndicator.fromJson(
          json['volMaIndicator'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MAVolumeIndicatorToJson(MAVolumeIndicator instance) =>
    <String, dynamic>{
      'key': const ValueKeyConverter().toJson(instance.key),
      'name': instance.name,
      'height': instance.height,
      'padding': const EdgeInsetsConverter().toJson(instance.padding),
      'drawBelowTipsArea': instance.drawBelowTipsArea,
      'volumeIndicator': instance.volumeIndicator.toJson(),
      'volMaIndicator': instance.volMaIndicator.toJson(),
    };
