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

  TooltipInfo onTap(VoidCallback? onTap);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `TooltipInfo(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TooltipInfo(...).copyWith(id: 12, name: "My name")
  /// ```
  TooltipInfo call({
    String label,
    TextStyle? labelStyle,
    String value,
    TextStyle? valueStyle,
    VoidCallback? onTap,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTooltipInfo.copyWith(...)` or call `instanceOfTooltipInfo.copyWith.fieldName(value)` for a single field.
class _$TooltipInfoCWProxyImpl implements _$TooltipInfoCWProxy {
  const _$TooltipInfoCWProxyImpl(this._value);

  final TooltipInfo _value;

  @override
  TooltipInfo label(String label) => call(label: label);

  @override
  TooltipInfo labelStyle(TextStyle? labelStyle) => call(labelStyle: labelStyle);

  @override
  TooltipInfo value(String value) => call(value: value);

  @override
  TooltipInfo valueStyle(TextStyle? valueStyle) => call(valueStyle: valueStyle);

  @override
  TooltipInfo onTap(VoidCallback? onTap) => call(onTap: onTap);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `TooltipInfo(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TooltipInfo(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  TooltipInfo call({
    Object? label = const $CopyWithPlaceholder(),
    Object? labelStyle = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
    Object? valueStyle = const $CopyWithPlaceholder(),
    Object? onTap = const $CopyWithPlaceholder(),
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
      onTap: onTap == const $CopyWithPlaceholder()
          ? _value.onTap
          // ignore: cast_nullable_to_non_nullable
          : onTap as VoidCallback?,
    );
  }
}

extension $TooltipInfoCopyWith on TooltipInfo {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTooltipInfo.copyWith(...)` or `instanceOfTooltipInfo.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TooltipInfoCWProxy get copyWith => _$TooltipInfoCWProxyImpl(this);
}
