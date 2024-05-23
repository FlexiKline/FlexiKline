// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flexi_kline_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$FlexiKlineConfigCWProxy {
  FlexiKlineConfig grid(GridConfig grid);

  FlexiKlineConfig setting(SettingConfig setting);

  FlexiKlineConfig cross(CrossConfig cross);

  FlexiKlineConfig tooltip(TooltipConfig tooltip);

  FlexiKlineConfig indicators(IndicatorsConfig indicators);

  FlexiKlineConfig main(Set<ValueKey<dynamic>> main);

  FlexiKlineConfig sub(Set<ValueKey<dynamic>> sub);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FlexiKlineConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FlexiKlineConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  FlexiKlineConfig call({
    GridConfig? grid,
    SettingConfig? setting,
    CrossConfig? cross,
    TooltipConfig? tooltip,
    IndicatorsConfig? indicators,
    Set<ValueKey<dynamic>>? main,
    Set<ValueKey<dynamic>>? sub,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfFlexiKlineConfig.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfFlexiKlineConfig.copyWith.fieldName(...)`
class _$FlexiKlineConfigCWProxyImpl implements _$FlexiKlineConfigCWProxy {
  const _$FlexiKlineConfigCWProxyImpl(this._value);

  final FlexiKlineConfig _value;

  @override
  FlexiKlineConfig grid(GridConfig grid) => this(grid: grid);

  @override
  FlexiKlineConfig setting(SettingConfig setting) => this(setting: setting);

  @override
  FlexiKlineConfig cross(CrossConfig cross) => this(cross: cross);

  @override
  FlexiKlineConfig tooltip(TooltipConfig tooltip) => this(tooltip: tooltip);

  @override
  FlexiKlineConfig indicators(IndicatorsConfig indicators) =>
      this(indicators: indicators);

  @override
  FlexiKlineConfig main(Set<ValueKey<dynamic>> main) => this(main: main);

  @override
  FlexiKlineConfig sub(Set<ValueKey<dynamic>> sub) => this(sub: sub);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FlexiKlineConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FlexiKlineConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  FlexiKlineConfig call({
    Object? grid = const $CopyWithPlaceholder(),
    Object? setting = const $CopyWithPlaceholder(),
    Object? cross = const $CopyWithPlaceholder(),
    Object? tooltip = const $CopyWithPlaceholder(),
    Object? indicators = const $CopyWithPlaceholder(),
    Object? main = const $CopyWithPlaceholder(),
    Object? sub = const $CopyWithPlaceholder(),
  }) {
    return FlexiKlineConfig(
      grid: grid == const $CopyWithPlaceholder() || grid == null
          ? _value.grid
          // ignore: cast_nullable_to_non_nullable
          : grid as GridConfig,
      setting: setting == const $CopyWithPlaceholder() || setting == null
          ? _value.setting
          // ignore: cast_nullable_to_non_nullable
          : setting as SettingConfig,
      cross: cross == const $CopyWithPlaceholder() || cross == null
          ? _value.cross
          // ignore: cast_nullable_to_non_nullable
          : cross as CrossConfig,
      tooltip: tooltip == const $CopyWithPlaceholder() || tooltip == null
          ? _value.tooltip
          // ignore: cast_nullable_to_non_nullable
          : tooltip as TooltipConfig,
      indicators:
          indicators == const $CopyWithPlaceholder() || indicators == null
              ? _value.indicators
              // ignore: cast_nullable_to_non_nullable
              : indicators as IndicatorsConfig,
      main: main == const $CopyWithPlaceholder() || main == null
          ? _value.main
          // ignore: cast_nullable_to_non_nullable
          : main as Set<ValueKey<dynamic>>,
      sub: sub == const $CopyWithPlaceholder() || sub == null
          ? _value.sub
          // ignore: cast_nullable_to_non_nullable
          : sub as Set<ValueKey<dynamic>>,
    );
  }
}

extension $FlexiKlineConfigCopyWith on FlexiKlineConfig {
  /// Returns a callable class that can be used as follows: `instanceOfFlexiKlineConfig.copyWith(...)` or like so:`instanceOfFlexiKlineConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$FlexiKlineConfigCWProxy get copyWith => _$FlexiKlineConfigCWProxyImpl(this);
}

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
      main: const SetValueKeyConverter().fromJson(json['main'] as List),
      sub: const SetValueKeyConverter().fromJson(json['sub'] as List),
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
