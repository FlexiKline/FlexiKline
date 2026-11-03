// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bubble_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BubbleConfigCWProxy {
  BubbleConfig text(TextAreaConfig text);

  BubbleConfig arrowSize(Size arrowSize);

  BubbleConfig arrowRadius(double arrowRadius);

  BubbleConfig spacing(double spacing);

  BubbleConfig placement(AxisDirection placement);

  BubbleConfig flip(bool flip);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `BubbleConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BubbleConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  BubbleConfig call({
    TextAreaConfig text,
    Size arrowSize,
    double arrowRadius,
    double spacing,
    AxisDirection placement,
    bool flip,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBubbleConfig.copyWith(...)` or call `instanceOfBubbleConfig.copyWith.fieldName(value)` for a single field.
class _$BubbleConfigCWProxyImpl implements _$BubbleConfigCWProxy {
  const _$BubbleConfigCWProxyImpl(this._value);

  final BubbleConfig _value;

  @override
  BubbleConfig text(TextAreaConfig text) => call(text: text);

  @override
  BubbleConfig arrowSize(Size arrowSize) => call(arrowSize: arrowSize);

  @override
  BubbleConfig arrowRadius(double arrowRadius) =>
      call(arrowRadius: arrowRadius);

  @override
  BubbleConfig spacing(double spacing) => call(spacing: spacing);

  @override
  BubbleConfig placement(AxisDirection placement) => call(placement: placement);

  @override
  BubbleConfig flip(bool flip) => call(flip: flip);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `BubbleConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BubbleConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BubbleConfig call({
    Object? text = const $CopyWithPlaceholder(),
    Object? arrowSize = const $CopyWithPlaceholder(),
    Object? arrowRadius = const $CopyWithPlaceholder(),
    Object? spacing = const $CopyWithPlaceholder(),
    Object? placement = const $CopyWithPlaceholder(),
    Object? flip = const $CopyWithPlaceholder(),
  }) {
    return BubbleConfig(
      text: text == const $CopyWithPlaceholder() || text == null
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as TextAreaConfig,
      arrowSize: arrowSize == const $CopyWithPlaceholder() || arrowSize == null
          ? _value.arrowSize
          // ignore: cast_nullable_to_non_nullable
          : arrowSize as Size,
      arrowRadius:
          arrowRadius == const $CopyWithPlaceholder() || arrowRadius == null
          ? _value.arrowRadius
          // ignore: cast_nullable_to_non_nullable
          : arrowRadius as double,
      spacing: spacing == const $CopyWithPlaceholder() || spacing == null
          ? _value.spacing
          // ignore: cast_nullable_to_non_nullable
          : spacing as double,
      placement: placement == const $CopyWithPlaceholder() || placement == null
          ? _value.placement
          // ignore: cast_nullable_to_non_nullable
          : placement as AxisDirection,
      flip: flip == const $CopyWithPlaceholder() || flip == null
          ? _value.flip
          // ignore: cast_nullable_to_non_nullable
          : flip as bool,
    );
  }
}

extension $BubbleConfigCopyWith on BubbleConfig {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBubbleConfig.copyWith(...)` or `instanceOfBubbleConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BubbleConfigCWProxy get copyWith => _$BubbleConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BubbleConfig _$BubbleConfigFromJson(Map<String, dynamic> json) => BubbleConfig(
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
  arrowSize: json['arrowSize'] == null
      ? const Size(10, 5)
      : const SizeConverter().fromJson(
          json['arrowSize'] as Map<String, dynamic>,
        ),
  arrowRadius: (json['arrowRadius'] as num?)?.toDouble() ?? 0,
  spacing: (json['spacing'] as num?)?.toDouble() ?? 4,
  placement: json['placement'] == null
      ? AxisDirection.up
      : const AxisDirectionConverter().fromJson(json['placement'] as String),
  flip: json['flip'] as bool? ?? true,
);

Map<String, dynamic> _$BubbleConfigToJson(BubbleConfig instance) =>
    <String, dynamic>{
      'text': instance.text.toJson(),
      'arrowSize': const SizeConverter().toJson(instance.arrowSize),
      'arrowRadius': instance.arrowRadius,
      'spacing': instance.spacing,
      'placement': const AxisDirectionConverter().toJson(instance.placement),
      'flip': instance.flip,
    };
