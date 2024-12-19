// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'indicator.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MultiPaintObjectIndicatorCWProxy<
    T extends SinglePaintObjectIndicator> {
  MultiPaintObjectIndicator<T> key(IIndicatorKey key);

  MultiPaintObjectIndicator<T> size(Size size);

  MultiPaintObjectIndicator<T> padding(EdgeInsets padding);

  MultiPaintObjectIndicator<T> drawBelowTipsArea(bool drawBelowTipsArea);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MultiPaintObjectIndicator<T>(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MultiPaintObjectIndicator<T>(...).copyWith(id: 12, name: "My name")
  /// ````
  MultiPaintObjectIndicator<T> call({
    IIndicatorKey? key,
    Size? size,
    EdgeInsets? padding,
    bool? drawBelowTipsArea,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMultiPaintObjectIndicator.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMultiPaintObjectIndicator.copyWith.fieldName(...)`
class _$MultiPaintObjectIndicatorCWProxyImpl<
        T extends SinglePaintObjectIndicator>
    implements _$MultiPaintObjectIndicatorCWProxy<T> {
  const _$MultiPaintObjectIndicatorCWProxyImpl(this._value);

  final MultiPaintObjectIndicator<T> _value;

  @override
  MultiPaintObjectIndicator<T> key(IIndicatorKey key) => this(key: key);

  @override
  MultiPaintObjectIndicator<T> size(Size size) => this(size: size);

  @override
  MultiPaintObjectIndicator<T> padding(EdgeInsets padding) =>
      this(padding: padding);

  @override
  MultiPaintObjectIndicator<T> drawBelowTipsArea(bool drawBelowTipsArea) =>
      this(drawBelowTipsArea: drawBelowTipsArea);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MultiPaintObjectIndicator<T>(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MultiPaintObjectIndicator<T>(...).copyWith(id: 12, name: "My name")
  /// ````
  MultiPaintObjectIndicator<T> call({
    Object? key = const $CopyWithPlaceholder(),
    Object? size = const $CopyWithPlaceholder(),
    Object? padding = const $CopyWithPlaceholder(),
    Object? drawBelowTipsArea = const $CopyWithPlaceholder(),
  }) {
    return MultiPaintObjectIndicator<T>(
      key: key == const $CopyWithPlaceholder() || key == null
          ? _value.key
          // ignore: cast_nullable_to_non_nullable
          : key as IIndicatorKey,
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

extension $MultiPaintObjectIndicatorCopyWith<
    T extends SinglePaintObjectIndicator> on MultiPaintObjectIndicator<T> {
  /// Returns a callable class that can be used as follows: `instanceOfMultiPaintObjectIndicator.copyWith(...)` or like so:`instanceOfMultiPaintObjectIndicator.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MultiPaintObjectIndicatorCWProxy<T> get copyWith =>
      _$MultiPaintObjectIndicatorCWProxyImpl<T>(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MultiPaintObjectIndicator<T>
    _$MultiPaintObjectIndicatorFromJson<T extends SinglePaintObjectIndicator>(
            Map<String, dynamic> json) =>
        MultiPaintObjectIndicator<T>(
          key: const IIndicatorKeyConvert().fromJson(json['key'] as String),
          size: const SizeConverter()
              .fromJson(json['size'] as Map<String, dynamic>),
          padding: const EdgeInsetsConverter()
              .fromJson(json['padding'] as Map<String, dynamic>),
          drawBelowTipsArea: json['drawBelowTipsArea'] as bool? ?? false,
        )..height = (json['height'] as num).toDouble();

Map<String, dynamic>
    _$MultiPaintObjectIndicatorToJson<T extends SinglePaintObjectIndicator>(
            MultiPaintObjectIndicator<T> instance) =>
        <String, dynamic>{
          'key': const IIndicatorKeyConvert().toJson(instance.key),
          'height': instance.height,
          'padding': const EdgeInsetsConverter().toJson(instance.padding),
          'size': const SizeConverter().toJson(instance.size),
          'drawBelowTipsArea': instance.drawBelowTipsArea,
        };
