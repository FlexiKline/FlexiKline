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
      tooltip: TooltipConfig.fromJson(json['tooltip'] as Map<String, dynamic>),
      indicators:
          IndicatorsConfig.fromJson(json['indicators'] as Map<String, dynamic>),
      main: const SetValueKeyConverter().fromJson(json['main'] as List<String>),
      sub: const SetValueKeyConverter().fromJson(json['sub'] as List<String>),
    );

Map<String, dynamic> _$FlexiKlineConfigToJson(FlexiKlineConfig instance) =>
    <String, dynamic>{
      'grid': instance.grid.toJson(),
      'setting': instance.setting.toJson(),
      'cross': instance.cross.toJson(),
      'tooltip': instance.tooltip.toJson(),
      'indicators': instance.indicators.toJson(),
      'main': const SetValueKeyConverter().toJson(instance.main),
      'sub': const SetValueKeyConverter().toJson(instance.sub),
    };
