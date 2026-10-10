// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'date_mark_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DateMarkConfigCWProxy {
  DateMarkConfig show(bool show);

  DateMarkConfig spacing(double spacing);

  DateMarkConfig arrowSize(Size arrowSize);

  DateMarkConfig holdDuration(int holdDuration);

  DateMarkConfig position(DateMarkPosition position);

  DateMarkConfig text(TextAreaConfig text);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `DateMarkConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DateMarkConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  DateMarkConfig call({
    bool show,
    double spacing,
    Size arrowSize,
    int holdDuration,
    DateMarkPosition position,
    TextAreaConfig text,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDateMarkConfig.copyWith(...)` or call `instanceOfDateMarkConfig.copyWith.fieldName(value)` for a single field.
class _$DateMarkConfigCWProxyImpl implements _$DateMarkConfigCWProxy {
  const _$DateMarkConfigCWProxyImpl(this._value);

  final DateMarkConfig _value;

  @override
  DateMarkConfig show(bool show) => call(show: show);

  @override
  DateMarkConfig spacing(double spacing) => call(spacing: spacing);

  @override
  DateMarkConfig arrowSize(Size arrowSize) => call(arrowSize: arrowSize);

  @override
  DateMarkConfig holdDuration(int holdDuration) =>
      call(holdDuration: holdDuration);

  @override
  DateMarkConfig position(DateMarkPosition position) =>
      call(position: position);

  @override
  DateMarkConfig text(TextAreaConfig text) => call(text: text);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `DateMarkConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DateMarkConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DateMarkConfig call({
    Object? show = const $CopyWithPlaceholder(),
    Object? spacing = const $CopyWithPlaceholder(),
    Object? arrowSize = const $CopyWithPlaceholder(),
    Object? holdDuration = const $CopyWithPlaceholder(),
    Object? position = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
  }) {
    return DateMarkConfig(
      show: show == const $CopyWithPlaceholder() || show == null
          ? _value.show
          // ignore: cast_nullable_to_non_nullable
          : show as bool,
      spacing: spacing == const $CopyWithPlaceholder() || spacing == null
          ? _value.spacing
          // ignore: cast_nullable_to_non_nullable
          : spacing as double,
      arrowSize: arrowSize == const $CopyWithPlaceholder() || arrowSize == null
          ? _value.arrowSize
          // ignore: cast_nullable_to_non_nullable
          : arrowSize as Size,
      holdDuration:
          holdDuration == const $CopyWithPlaceholder() || holdDuration == null
          ? _value.holdDuration
          // ignore: cast_nullable_to_non_nullable
          : holdDuration as int,
      position: position == const $CopyWithPlaceholder() || position == null
          ? _value.position
          // ignore: cast_nullable_to_non_nullable
          : position as DateMarkPosition,
      text: text == const $CopyWithPlaceholder() || text == null
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as TextAreaConfig,
    );
  }
}

extension $DateMarkConfigCopyWith on DateMarkConfig {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDateMarkConfig.copyWith(...)` or `instanceOfDateMarkConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DateMarkConfigCWProxy get copyWith => _$DateMarkConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DateMarkConfig _$DateMarkConfigFromJson(Map<String, dynamic> json) =>
    DateMarkConfig(
      show: json['show'] as bool? ?? true,
      spacing: (json['spacing'] as num?)?.toDouble() ?? 4,
      arrowSize: json['arrowSize'] == null
          ? const Size(10, 5)
          : const SizeConverter().fromJson(
              json['arrowSize'] as Map<String, dynamic>,
            ),
      holdDuration: (json['holdDuration'] as num?)?.toInt() ?? 2000,
      position: json['position'] == null
          ? DateMarkPosition.auto
          : const DateMarkPositionConverter().fromJson(
              json['position'] as String,
            ),
      text: json['text'] == null
          ? const TextAreaConfig(
              style: TextStyle(
                fontSize: defaultTextSize,
                overflow: TextOverflow.ellipsis,
                height: defaultTextHeight,
              ),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              borderRadius: BorderRadius.all(Radius.circular(4)),
            )
          : TextAreaConfig.fromJson(json['text'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DateMarkConfigToJson(DateMarkConfig instance) =>
    <String, dynamic>{
      'show': instance.show,
      'spacing': instance.spacing,
      'arrowSize': const SizeConverter().toJson(instance.arrowSize),
      'holdDuration': instance.holdDuration,
      'position': const DateMarkPositionConverter().toJson(instance.position),
      'text': instance.text.toJson(),
    };
