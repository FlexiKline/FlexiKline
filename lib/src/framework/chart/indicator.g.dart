// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'indicator.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MainPaintObjectIndicatorCWProxy<
  T extends Indicator<IIndicatorKey>
> {
  MainPaintObjectIndicator<T> size(Size size);

  MainPaintObjectIndicator<T> padding(EdgeInsets padding);

  MainPaintObjectIndicator<T> drawBelowTipsArea(bool drawBelowTipsArea);

  MainPaintObjectIndicator<T> children(Set<IIndicatorKey>? children);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `MainPaintObjectIndicator<T>(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MainPaintObjectIndicator<T>(...).copyWith(id: 12, name: "My name")
  /// ```
  MainPaintObjectIndicator<T> call({
    Size size,
    EdgeInsets padding,
    bool drawBelowTipsArea,
    Set<IIndicatorKey>? children,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMainPaintObjectIndicator.copyWith(...)` or call `instanceOfMainPaintObjectIndicator.copyWith.fieldName(value)` for a single field.
class _$MainPaintObjectIndicatorCWProxyImpl<T extends Indicator<IIndicatorKey>>
    implements _$MainPaintObjectIndicatorCWProxy<T> {
  const _$MainPaintObjectIndicatorCWProxyImpl(this._value);

  final MainPaintObjectIndicator<T> _value;

  @override
  MainPaintObjectIndicator<T> size(Size size) => call(size: size);

  @override
  MainPaintObjectIndicator<T> padding(EdgeInsets padding) =>
      call(padding: padding);

  @override
  MainPaintObjectIndicator<T> drawBelowTipsArea(bool drawBelowTipsArea) =>
      call(drawBelowTipsArea: drawBelowTipsArea);

  @override
  MainPaintObjectIndicator<T> children(Set<IIndicatorKey>? children) =>
      call(children: children);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `MainPaintObjectIndicator<T>(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MainPaintObjectIndicator<T>(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  MainPaintObjectIndicator<T> call({
    Object? size = const $CopyWithPlaceholder(),
    Object? padding = const $CopyWithPlaceholder(),
    Object? drawBelowTipsArea = const $CopyWithPlaceholder(),
    Object? children = const $CopyWithPlaceholder(),
  }) {
    return MainPaintObjectIndicator<T>(
      size: size == const $CopyWithPlaceholder() || size == null
          ? _value.size
          // ignore: cast_nullable_to_non_nullable
          : size as Size,
      padding: padding == const $CopyWithPlaceholder() || padding == null
          ? _value.padding
          // ignore: cast_nullable_to_non_nullable
          : padding as EdgeInsets,
      drawBelowTipsArea:
          drawBelowTipsArea == const $CopyWithPlaceholder() ||
              drawBelowTipsArea == null
          ? _value.drawBelowTipsArea
          // ignore: cast_nullable_to_non_nullable
          : drawBelowTipsArea as bool,
      children: children == const $CopyWithPlaceholder()
          ? _value.children
          // ignore: cast_nullable_to_non_nullable
          : children as Set<IIndicatorKey>?,
    );
  }
}

extension $MainPaintObjectIndicatorCopyWith<T extends Indicator<IIndicatorKey>>
    on MainPaintObjectIndicator<T> {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMainPaintObjectIndicator.copyWith(...)` or `instanceOfMainPaintObjectIndicator.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MainPaintObjectIndicatorCWProxy<T> get copyWith =>
      _$MainPaintObjectIndicatorCWProxyImpl<T>(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MainPaintObjectIndicator<T> _$MainPaintObjectIndicatorFromJson<
  T extends Indicator<IIndicatorKey>
>(Map<String, dynamic> json) => MainPaintObjectIndicator<T>(
  size: const SizeConverter().fromJson(json['size'] as Map<String, dynamic>),
  padding: const EdgeInsetsConverter().fromJson(
    json['padding'] as Map<String, dynamic>,
  ),
  drawBelowTipsArea: json['drawBelowTipsArea'] as bool? ?? false,
  children: (json['children'] as List<dynamic>?)
      ?.map((e) => const IIndicatorKeyConvert().fromJson(e as String))
      .toSet(),
)..height = (json['height'] as num).toDouble();

Map<String, dynamic> _$MainPaintObjectIndicatorToJson<
  T extends Indicator<IIndicatorKey>
>(MainPaintObjectIndicator<T> instance) => <String, dynamic>{
  'padding': const EdgeInsetsConverter().toJson(instance.padding),
  'size': const SizeConverter().toJson(instance.size),
  'height': instance.height,
  'drawBelowTipsArea': instance.drawBelowTipsArea,
  'children': instance.children
      .map(const IIndicatorKeyConvert().toJson)
      .toList(),
};
