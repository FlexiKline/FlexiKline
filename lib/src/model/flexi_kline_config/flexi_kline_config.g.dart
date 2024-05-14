// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flexi_kline_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FlexiKlineConfig _$FlexiKlineConfigFromJson(Map<String, dynamic> json) =>
    FlexiKlineConfig(
      grid: GridConfig.fromJson(json['grid'] as Map<String, dynamic>),
      setting: SettingConfig.fromJson(json['setting'] as Map<String, dynamic>),
      cross: CrossConfig.fromJson(json['cross'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FlexiKlineConfigToJson(FlexiKlineConfig instance) =>
    <String, dynamic>{
      'grid': instance.grid.toJson(),
      'setting': instance.setting.toJson(),
      'cross': instance.cross.toJson(),
    };
