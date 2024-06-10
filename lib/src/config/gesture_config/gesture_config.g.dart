// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gesture_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GestureConfigCWProxy {
  GestureConfig tolerance(ToleranceConfig? tolerance);

  GestureConfig loadMoreWhenNoEnoughDistance(
      double? loadMoreWhenNoEnoughDistance);

  GestureConfig loadMoreWhenNoEnoughCandles(int loadMoreWhenNoEnoughCandles);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GestureConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GestureConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  GestureConfig call({
    ToleranceConfig? tolerance,
    double? loadMoreWhenNoEnoughDistance,
    int? loadMoreWhenNoEnoughCandles,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfGestureConfig.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfGestureConfig.copyWith.fieldName(...)`
class _$GestureConfigCWProxyImpl implements _$GestureConfigCWProxy {
  const _$GestureConfigCWProxyImpl(this._value);

  final GestureConfig _value;

  @override
  GestureConfig tolerance(ToleranceConfig? tolerance) =>
      this(tolerance: tolerance);

  @override
  GestureConfig loadMoreWhenNoEnoughDistance(
          double? loadMoreWhenNoEnoughDistance) =>
      this(loadMoreWhenNoEnoughDistance: loadMoreWhenNoEnoughDistance);

  @override
  GestureConfig loadMoreWhenNoEnoughCandles(int loadMoreWhenNoEnoughCandles) =>
      this(loadMoreWhenNoEnoughCandles: loadMoreWhenNoEnoughCandles);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GestureConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GestureConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  GestureConfig call({
    Object? tolerance = const $CopyWithPlaceholder(),
    Object? loadMoreWhenNoEnoughDistance = const $CopyWithPlaceholder(),
    Object? loadMoreWhenNoEnoughCandles = const $CopyWithPlaceholder(),
  }) {
    return GestureConfig(
      tolerance: tolerance == const $CopyWithPlaceholder()
          ? _value.tolerance
          // ignore: cast_nullable_to_non_nullable
          : tolerance as ToleranceConfig?,
      loadMoreWhenNoEnoughDistance:
          loadMoreWhenNoEnoughDistance == const $CopyWithPlaceholder()
              ? _value.loadMoreWhenNoEnoughDistance
              // ignore: cast_nullable_to_non_nullable
              : loadMoreWhenNoEnoughDistance as double?,
      loadMoreWhenNoEnoughCandles:
          loadMoreWhenNoEnoughCandles == const $CopyWithPlaceholder() ||
                  loadMoreWhenNoEnoughCandles == null
              ? _value.loadMoreWhenNoEnoughCandles
              // ignore: cast_nullable_to_non_nullable
              : loadMoreWhenNoEnoughCandles as int,
    );
  }
}

extension $GestureConfigCopyWith on GestureConfig {
  /// Returns a callable class that can be used as follows: `instanceOfGestureConfig.copyWith(...)` or like so:`instanceOfGestureConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GestureConfigCWProxy get copyWith => _$GestureConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GestureConfig _$GestureConfigFromJson(Map<String, dynamic> json) =>
    GestureConfig(
      tolerance: json['tolerance'] == null
          ? null
          : ToleranceConfig.fromJson(json['tolerance'] as Map<String, dynamic>),
      loadMoreWhenNoEnoughDistance:
          (json['loadMoreWhenNoEnoughDistance'] as num?)?.toDouble(),
      loadMoreWhenNoEnoughCandles:
          (json['loadMoreWhenNoEnoughCandles'] as num?)?.toInt() ?? 60,
    );

Map<String, dynamic> _$GestureConfigToJson(GestureConfig instance) {
  final val = <String, dynamic>{
    'tolerance': instance.tolerance.toJson(),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(
      'loadMoreWhenNoEnoughDistance', instance.loadMoreWhenNoEnoughDistance);
  val['loadMoreWhenNoEnoughCandles'] = instance.loadMoreWhenNoEnoughCandles;
  return val;
}
