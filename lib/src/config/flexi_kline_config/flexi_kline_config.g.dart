// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flexi_kline_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FlexiKlineConfig _$FlexiKlineConfigFromJson(Map<String, dynamic> json) =>
    FlexiKlineConfig(
      key: json['key'] as String,
      grid: GridConfig.fromJson(json['grid'] as Map<String, dynamic>),
      setting: SettingConfig.fromJson(json['setting'] as Map<String, dynamic>),
      gesture: GestureConfig.fromJson(json['gesture'] as Map<String, dynamic>),
      cross: CrossConfig.fromJson(json['cross'] as Map<String, dynamic>),
      draw: DrawConfig.fromJson(json['draw'] as Map<String, dynamic>),
      mainIndicator: MainPaintObjectIndicator<PaintObjectIndicator>.fromJson(
          json['mainIndicator'] as Map<String, dynamic>),
      sub: json['sub'] == null
          ? const <IIndicatorKey>{}
          : const SetIndicatorKeyConverter().fromJson(json['sub'] as List),
    );

Map<String, dynamic> _$FlexiKlineConfigToJson(FlexiKlineConfig instance) =>
    <String, dynamic>{
      'key': instance.key,
      'grid': instance.grid.toJson(),
      'setting': instance.setting.toJson(),
      'gesture': instance.gesture.toJson(),
      'cross': instance.cross.toJson(),
      'draw': instance.draw.toJson(),
      'mainIndicator': instance.mainIndicator.toJson(),
      'sub': const SetIndicatorKeyConverter().toJson(instance.sub),
    };
