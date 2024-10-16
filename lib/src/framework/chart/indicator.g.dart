// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'indicator.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MultiPaintObjectIndicatorCWProxy<
    T extends SinglePaintObjectIndicator> {
  MultiPaintObjectIndicator<T> key(ValueKey<dynamic> key);

  MultiPaintObjectIndicator<T> name(String name);

  MultiPaintObjectIndicator<T> height(double height);

  MultiPaintObjectIndicator<T> padding(EdgeInsets padding);

  MultiPaintObjectIndicator<T> drawBelowTipsArea(bool drawBelowTipsArea);

  MultiPaintObjectIndicator<T> children(Iterable<T> children);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MultiPaintObjectIndicator<T>(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MultiPaintObjectIndicator<T>(...).copyWith(id: 12, name: "My name")
  /// ````
  MultiPaintObjectIndicator<T> call({
    ValueKey<dynamic>? key,
    String? name,
    double? height,
    EdgeInsets? padding,
    bool? drawBelowTipsArea,
    Iterable<T>? children,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMultiPaintObjectIndicator.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMultiPaintObjectIndicator.copyWith.fieldName(...)`
class _$MultiPaintObjectIndicatorCWProxyImpl<
        T extends SinglePaintObjectIndicator>
    implements _$MultiPaintObjectIndicatorCWProxy<T> {
  const _$MultiPaintObjectIndicatorCWProxyImpl(this._value);

  final MultiPaintObjectIndicator<T> _value;

  @override
  MultiPaintObjectIndicator<T> key(ValueKey<dynamic> key) => this(key: key);

  @override
  MultiPaintObjectIndicator<T> name(String name) => this(name: name);

  @override
  MultiPaintObjectIndicator<T> height(double height) => this(height: height);

  @override
  MultiPaintObjectIndicator<T> padding(EdgeInsets padding) =>
      this(padding: padding);

  @override
  MultiPaintObjectIndicator<T> drawBelowTipsArea(bool drawBelowTipsArea) =>
      this(drawBelowTipsArea: drawBelowTipsArea);

  @override
  MultiPaintObjectIndicator<T> children(Iterable<T> children) =>
      this(children: children);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MultiPaintObjectIndicator<T>(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MultiPaintObjectIndicator<T>(...).copyWith(id: 12, name: "My name")
  /// ````
  MultiPaintObjectIndicator<T> call({
    Object? key = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? height = const $CopyWithPlaceholder(),
    Object? padding = const $CopyWithPlaceholder(),
    Object? drawBelowTipsArea = const $CopyWithPlaceholder(),
    Object? children = const $CopyWithPlaceholder(),
  }) {
    return MultiPaintObjectIndicator<T>(
      key: key == const $CopyWithPlaceholder() || key == null
          ? _value.key
          // ignore: cast_nullable_to_non_nullable
          : key as ValueKey<dynamic>,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      height: height == const $CopyWithPlaceholder() || height == null
          ? _value.height
          // ignore: cast_nullable_to_non_nullable
          : height as double,
      padding: padding == const $CopyWithPlaceholder() || padding == null
          ? _value.padding
          // ignore: cast_nullable_to_non_nullable
          : padding as EdgeInsets,
      drawBelowTipsArea: drawBelowTipsArea == const $CopyWithPlaceholder() ||
              drawBelowTipsArea == null
          ? _value.drawBelowTipsArea
          // ignore: cast_nullable_to_non_nullable
          : drawBelowTipsArea as bool,
      children: children == const $CopyWithPlaceholder() || children == null
          ? _value.children
          // ignore: cast_nullable_to_non_nullable
          : children as Iterable<T>,
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
          key: const ValueKeyConverter().fromJson(json['key'] as String),
          name: json['name'] as String,
          height: (json['height'] as num).toDouble(),
          padding: const EdgeInsetsConverter()
              .fromJson(json['padding'] as Map<String, dynamic>),
          drawBelowTipsArea: json['drawBelowTipsArea'] as bool? ?? false,
        );

Map<String, dynamic>
    _$MultiPaintObjectIndicatorToJson<T extends SinglePaintObjectIndicator>(
            MultiPaintObjectIndicator<T> instance) =>
        <String, dynamic>{
          'key': const ValueKeyConverter().toJson(instance.key),
          'name': instance.name,
          'height': instance.height,
          'padding': const EdgeInsetsConverter().toJson(instance.padding),
          'drawBelowTipsArea': instance.drawBelowTipsArea,
        };
