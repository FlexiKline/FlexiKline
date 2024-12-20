// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'indicator.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MainPaintObjectIndicatorCWProxy<
    T extends PaintObjectIndicator> {
  MainPaintObjectIndicator<T> size(Size size);

  MainPaintObjectIndicator<T> padding(EdgeInsets padding);

  MainPaintObjectIndicator<T> drawBelowTipsArea(bool drawBelowTipsArea);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MainPaintObjectIndicator<T>(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MainPaintObjectIndicator<T>(...).copyWith(id: 12, name: "My name")
  /// ````
  MainPaintObjectIndicator<T> call({
    Size? size,
    EdgeInsets? padding,
    bool? drawBelowTipsArea,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMainPaintObjectIndicator.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMainPaintObjectIndicator.copyWith.fieldName(...)`
class _$MainPaintObjectIndicatorCWProxyImpl<T extends PaintObjectIndicator>
    implements _$MainPaintObjectIndicatorCWProxy<T> {
  const _$MainPaintObjectIndicatorCWProxyImpl(this._value);

  final MainPaintObjectIndicator<T> _value;

  @override
  MainPaintObjectIndicator<T> size(Size size) => this(size: size);

  @override
  MainPaintObjectIndicator<T> padding(EdgeInsets padding) =>
      this(padding: padding);

  @override
  MainPaintObjectIndicator<T> drawBelowTipsArea(bool drawBelowTipsArea) =>
      this(drawBelowTipsArea: drawBelowTipsArea);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MainPaintObjectIndicator<T>(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MainPaintObjectIndicator<T>(...).copyWith(id: 12, name: "My name")
  /// ````
  MainPaintObjectIndicator<T> call({
    Object? size = const $CopyWithPlaceholder(),
    Object? padding = const $CopyWithPlaceholder(),
    Object? drawBelowTipsArea = const $CopyWithPlaceholder(),
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
      drawBelowTipsArea: drawBelowTipsArea == const $CopyWithPlaceholder() ||
              drawBelowTipsArea == null
          ? _value.drawBelowTipsArea
          // ignore: cast_nullable_to_non_nullable
          : drawBelowTipsArea as bool,
    );
  }
}

extension $MainPaintObjectIndicatorCopyWith<T extends PaintObjectIndicator>
    on MainPaintObjectIndicator<T> {
  /// Returns a callable class that can be used as follows: `instanceOfMainPaintObjectIndicator.copyWith(...)` or like so:`instanceOfMainPaintObjectIndicator.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MainPaintObjectIndicatorCWProxy<T> get copyWith =>
      _$MainPaintObjectIndicatorCWProxyImpl<T>(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MainPaintObjectIndicator<T>
    _$MainPaintObjectIndicatorFromJson<T extends PaintObjectIndicator>(
            Map<String, dynamic> json) =>
        MainPaintObjectIndicator<T>(
          size: const SizeConverter()
              .fromJson(json['size'] as Map<String, dynamic>),
          padding: const EdgeInsetsConverter()
              .fromJson(json['padding'] as Map<String, dynamic>),
          drawBelowTipsArea: json['drawBelowTipsArea'] as bool? ?? false,
        )..height = (json['height'] as num).toDouble();

Map<String, dynamic>
    _$MainPaintObjectIndicatorToJson<T extends PaintObjectIndicator>(
            MainPaintObjectIndicator<T> instance) =>
        <String, dynamic>{
          'height': instance.height,
          'padding': const EdgeInsetsConverter().toJson(instance.padding),
          'size': const SizeConverter().toJson(instance.size),
          'drawBelowTipsArea': instance.drawBelowTipsArea,
        };
