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

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MarkConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MarkConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  MarkConfig call({
    bool? show,
    double? spacing,
    LineConfig? line,
    TextAreaConfig? text,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMarkConfig.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMarkConfig.copyWith.fieldName(...)`
class _$MarkConfigCWProxyImpl implements _$MarkConfigCWProxy {
  const _$MarkConfigCWProxyImpl(this._value);

  final MarkConfig _value;

  @override
  MarkConfig show(bool show) => this(show: show);

  @override
  MarkConfig spacing(double spacing) => this(spacing: spacing);

  @override
  MarkConfig line(LineConfig line) => this(line: line);

  @override
  MarkConfig text(TextAreaConfig text) => this(text: text);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MarkConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MarkConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  MarkConfig call({
    Object? show = const $CopyWithPlaceholder(),
    Object? spacing = const $CopyWithPlaceholder(),
    Object? line = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
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
    );
  }
}

extension $MarkConfigCopyWith on MarkConfig {
  /// Returns a callable class that can be used as follows: `instanceOfMarkConfig.copyWith(...)` or like so:`instanceOfMarkConfig.copyWith.fieldName(...)`.
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
                  fontSize: defaulTextSize,
                  color: Colors.black,
                  overflow: TextOverflow.ellipsis,
                  height: defaultTextHeight))
          : TextAreaConfig.fromJson(json['text'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MarkConfigToJson(MarkConfig instance) =>
    <String, dynamic>{
      'show': instance.show,
      'spacing': instance.spacing,
      'line': instance.line.toJson(),
      'text': instance.text.toJson(),
    };
