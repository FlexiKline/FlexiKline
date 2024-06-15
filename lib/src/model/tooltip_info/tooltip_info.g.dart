// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tooltip_info.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TooltipInfoCWProxy {
  TooltipInfo label(String label);

  TooltipInfo labelStyle(TextStyle? labelStyle);

  TooltipInfo value(String value);

  TooltipInfo valueStyle(TextStyle? valueStyle);

  TooltipInfo riseOrFall(int riseOrFall);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TooltipInfo(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TooltipInfo(...).copyWith(id: 12, name: "My name")
  /// ````
  TooltipInfo call({
    String? label,
    TextStyle? labelStyle,
    String? value,
    TextStyle? valueStyle,
    int? riseOrFall,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTooltipInfo.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTooltipInfo.copyWith.fieldName(...)`
class _$TooltipInfoCWProxyImpl implements _$TooltipInfoCWProxy {
  const _$TooltipInfoCWProxyImpl(this._value);

  final TooltipInfo _value;

  @override
  TooltipInfo label(String label) => this(label: label);

  @override
  TooltipInfo labelStyle(TextStyle? labelStyle) => this(labelStyle: labelStyle);

  @override
  TooltipInfo value(String value) => this(value: value);

  @override
  TooltipInfo valueStyle(TextStyle? valueStyle) => this(valueStyle: valueStyle);

  @override
  TooltipInfo riseOrFall(int riseOrFall) => this(riseOrFall: riseOrFall);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TooltipInfo(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TooltipInfo(...).copyWith(id: 12, name: "My name")
  /// ````
  TooltipInfo call({
    Object? label = const $CopyWithPlaceholder(),
    Object? labelStyle = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
    Object? valueStyle = const $CopyWithPlaceholder(),
    Object? riseOrFall = const $CopyWithPlaceholder(),
  }) {
    return TooltipInfo(
      label: label == const $CopyWithPlaceholder() || label == null
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      labelStyle: labelStyle == const $CopyWithPlaceholder()
          ? _value.labelStyle
          // ignore: cast_nullable_to_non_nullable
          : labelStyle as TextStyle?,
      value: value == const $CopyWithPlaceholder() || value == null
          ? _value.value
          // ignore: cast_nullable_to_non_nullable
          : value as String,
      valueStyle: valueStyle == const $CopyWithPlaceholder()
          ? _value.valueStyle
          // ignore: cast_nullable_to_non_nullable
          : valueStyle as TextStyle?,
      riseOrFall:
          riseOrFall == const $CopyWithPlaceholder() || riseOrFall == null
              ? _value.riseOrFall
              // ignore: cast_nullable_to_non_nullable
              : riseOrFall as int,
    );
  }
}

extension $TooltipInfoCopyWith on TooltipInfo {
  /// Returns a callable class that can be used as follows: `instanceOfTooltipInfo.copyWith(...)` or like so:`instanceOfTooltipInfo.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TooltipInfoCWProxy get copyWith => _$TooltipInfoCWProxyImpl(this);
}
