// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gesture_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GestureConfigCWProxy {
  GestureConfig supportLongPressOnTouchDevice(
      bool supportLongPressOnTouchDevice);

  GestureConfig isInertialPan(bool isInertialPan);

  GestureConfig tolerance(ToleranceConfig? tolerance);

  GestureConfig loadMoreWhenNoEnoughDistance(
      double? loadMoreWhenNoEnoughDistance);

  GestureConfig loadMoreWhenNoEnoughCandles(int loadMoreWhenNoEnoughCandles);

  GestureConfig scalePosition(ScalePosition scalePosition);

  GestureConfig scaleSpeed(double scaleSpeed);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GestureConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GestureConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  GestureConfig call({
    bool? supportLongPressOnTouchDevice,
    bool? isInertialPan,
    ToleranceConfig? tolerance,
    double? loadMoreWhenNoEnoughDistance,
    int? loadMoreWhenNoEnoughCandles,
    ScalePosition? scalePosition,
    double? scaleSpeed,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfGestureConfig.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfGestureConfig.copyWith.fieldName(...)`
class _$GestureConfigCWProxyImpl implements _$GestureConfigCWProxy {
  const _$GestureConfigCWProxyImpl(this._value);

  final GestureConfig _value;

  @override
  GestureConfig supportLongPressOnTouchDevice(
          bool supportLongPressOnTouchDevice) =>
      this(supportLongPressOnTouchDevice: supportLongPressOnTouchDevice);

  @override
  GestureConfig isInertialPan(bool isInertialPan) =>
      this(isInertialPan: isInertialPan);

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
  GestureConfig scalePosition(ScalePosition scalePosition) =>
      this(scalePosition: scalePosition);

  @override
  GestureConfig scaleSpeed(double scaleSpeed) => this(scaleSpeed: scaleSpeed);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GestureConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GestureConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  GestureConfig call({
    Object? supportLongPressOnTouchDevice = const $CopyWithPlaceholder(),
    Object? isInertialPan = const $CopyWithPlaceholder(),
    Object? tolerance = const $CopyWithPlaceholder(),
    Object? loadMoreWhenNoEnoughDistance = const $CopyWithPlaceholder(),
    Object? loadMoreWhenNoEnoughCandles = const $CopyWithPlaceholder(),
    Object? scalePosition = const $CopyWithPlaceholder(),
    Object? scaleSpeed = const $CopyWithPlaceholder(),
  }) {
    return GestureConfig(
      supportLongPressOnTouchDevice:
          supportLongPressOnTouchDevice == const $CopyWithPlaceholder() ||
                  supportLongPressOnTouchDevice == null
              ? _value.supportLongPressOnTouchDevice
              // ignore: cast_nullable_to_non_nullable
              : supportLongPressOnTouchDevice as bool,
      isInertialPan:
          isInertialPan == const $CopyWithPlaceholder() || isInertialPan == null
              ? _value.isInertialPan
              // ignore: cast_nullable_to_non_nullable
              : isInertialPan as bool,
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
      scalePosition:
          scalePosition == const $CopyWithPlaceholder() || scalePosition == null
              ? _value.scalePosition
              // ignore: cast_nullable_to_non_nullable
              : scalePosition as ScalePosition,
      scaleSpeed:
          scaleSpeed == const $CopyWithPlaceholder() || scaleSpeed == null
              ? _value.scaleSpeed
              // ignore: cast_nullable_to_non_nullable
              : scaleSpeed as double,
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
      supportLongPressOnTouchDevice:
          json['supportLongPressOnTouchDevice'] as bool? ?? true,
      isInertialPan: json['isInertialPan'] as bool? ?? true,
      tolerance: json['tolerance'] == null
          ? null
          : ToleranceConfig.fromJson(json['tolerance'] as Map<String, dynamic>),
      loadMoreWhenNoEnoughDistance:
          (json['loadMoreWhenNoEnoughDistance'] as num?)?.toDouble(),
      loadMoreWhenNoEnoughCandles:
          (json['loadMoreWhenNoEnoughCandles'] as num?)?.toInt() ?? 60,
      scalePosition: json['scalePosition'] == null
          ? ScalePosition.auto
          : const ScalePositionConverter()
              .fromJson(json['scalePosition'] as String),
      scaleSpeed: (json['scaleSpeed'] as num?)?.toDouble() ?? 10,
    );

Map<String, dynamic> _$GestureConfigToJson(GestureConfig instance) {
  final val = <String, dynamic>{
    'supportLongPressOnTouchDevice': instance.supportLongPressOnTouchDevice,
    'isInertialPan': instance.isInertialPan,
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
  val['scalePosition'] =
      const ScalePositionConverter().toJson(instance.scalePosition);
  val['scaleSpeed'] = instance.scaleSpeed;
  return val;
}
