// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mark_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MarkConfigCWProxy {
  MarkConfig show(bool show);

  MarkConfig spacing(double spacing);

  MarkConfig line(LineConfig line);

  MarkConfig text(TextAreaConfig text);

  MarkConfig hitTestMargin(double hitTestMargin);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `MarkConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MarkConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  MarkConfig call({
    bool show,
    double spacing,
    LineConfig line,
    TextAreaConfig text,
    double hitTestMargin,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMarkConfig.copyWith(...)` or call `instanceOfMarkConfig.copyWith.fieldName(value)` for a single field.
class _$MarkConfigCWProxyImpl implements _$MarkConfigCWProxy {
  const _$MarkConfigCWProxyImpl(this._value);

  final MarkConfig _value;

  @override
  MarkConfig show(bool show) => call(show: show);

  @override
  MarkConfig spacing(double spacing) => call(spacing: spacing);

  @override
  MarkConfig line(LineConfig line) => call(line: line);

  @override
  MarkConfig text(TextAreaConfig text) => call(text: text);

  @override
  MarkConfig hitTestMargin(double hitTestMargin) =>
      call(hitTestMargin: hitTestMargin);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `MarkConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MarkConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  MarkConfig call({
    Object? show = const $CopyWithPlaceholder(),
    Object? spacing = const $CopyWithPlaceholder(),
    Object? line = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
    Object? hitTestMargin = const $CopyWithPlaceholder(),
  }) {
    return MarkConfig(
      show: show == const $CopyWithPlaceholder() || show == null
          ? _value.show
          // ignore: cast_nullable_to_non_nullable
          : show as bool,
      spacing: spacing == const $CopyWithPlaceholder() || spacing == null
          ? _value.spacing
          // ignore: cast_nullable_to_non_nullable
          : spacing as double,
      line: line == const $CopyWithPlaceholder() || line == null
          ? _value.line
          // ignore: cast_nullable_to_non_nullable
          : line as LineConfig,
      text: text == const $CopyWithPlaceholder() || text == null
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as TextAreaConfig,
      hitTestMargin:
          hitTestMargin == const $CopyWithPlaceholder() || hitTestMargin == null
          ? _value.hitTestMargin
          // ignore: cast_nullable_to_non_nullable
          : hitTestMargin as double,
    );
  }
}

extension $MarkConfigCopyWith on MarkConfig {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMarkConfig.copyWith(...)` or `instanceOfMarkConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MarkConfigCWProxy get copyWith => _$MarkConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MarkConfig _$MarkConfigFromJson(Map<String, dynamic> json) => MarkConfig(
  show: json['show'] as bool? ?? true,
  spacing: (json['spacing'] as num?)?.toDouble() ?? 0,
  line: json['line'] == null
      ? const LineConfig()
      : LineConfig.fromJson(json['line'] as Map<String, dynamic>),
  text: json['text'] == null
      ? const TextAreaConfig(
          style: TextStyle(
            fontSize: defaultTextSize,
            overflow: TextOverflow.ellipsis,
            height: defaultTextHeight,
          ),
        )
      : TextAreaConfig.fromJson(json['text'] as Map<String, dynamic>),
  hitTestMargin: (json['hitTestMargin'] as num?)?.toDouble() ?? 0,
);

Map<String, dynamic> _$MarkConfigToJson(MarkConfig instance) =>
    <String, dynamic>{
      'show': instance.show,
      'spacing': instance.spacing,
      'line': instance.line.toJson(),
      'text': instance.text.toJson(),
      'hitTestMargin': instance.hitTestMargin,
    };
