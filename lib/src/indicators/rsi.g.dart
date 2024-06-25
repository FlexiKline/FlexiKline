// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rsi.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RSIIndicatorCWProxy {
  RSIIndicator key(ValueKey<dynamic> key);

  RSIIndicator name(String name);

  RSIIndicator zIndex(int zIndex);

  RSIIndicator height(double height);

  RSIIndicator padding(EdgeInsets padding);

  RSIIndicator calcParams(List<RsiParam> calcParams);

  RSIIndicator tipsPadding(EdgeInsets tipsPadding);

  RSIIndicator tickCount(int tickCount);

  RSIIndicator lineWidth(double lineWidth);

  RSIIndicator precision(int precision);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RSIIndicator(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RSIIndicator(...).copyWith(id: 12, name: "My name")
  /// ````
  RSIIndicator call({
    ValueKey<dynamic>? key,
    String? name,
    int? zIndex,
    double? height,
    EdgeInsets? padding,
    List<RsiParam>? calcParams,
    EdgeInsets? tipsPadding,
    int? tickCount,
    double? lineWidth,
    int? precision,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRSIIndicator.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRSIIndicator.copyWith.fieldName(...)`
class _$RSIIndicatorCWProxyImpl implements _$RSIIndicatorCWProxy {
  const _$RSIIndicatorCWProxyImpl(this._value);

  final RSIIndicator _value;

  @override
  RSIIndicator key(ValueKey<dynamic> key) => this(key: key);

  @override
  RSIIndicator name(String name) => this(name: name);

  @override
  RSIIndicator zIndex(int zIndex) => this(zIndex: zIndex);

  @override
  RSIIndicator height(double height) => this(height: height);

  @override
  RSIIndicator padding(EdgeInsets padding) => this(padding: padding);

  @override
  RSIIndicator calcParams(List<RsiParam> calcParams) =>
      this(calcParams: calcParams);

  @override
  RSIIndicator tipsPadding(EdgeInsets tipsPadding) =>
      this(tipsPadding: tipsPadding);

  @override
  RSIIndicator tickCount(int tickCount) => this(tickCount: tickCount);

  @override
  RSIIndicator lineWidth(double lineWidth) => this(lineWidth: lineWidth);

  @override
  RSIIndicator precision(int precision) => this(precision: precision);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RSIIndicator(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RSIIndicator(...).copyWith(id: 12, name: "My name")
  /// ````
  RSIIndicator call({
    Object? key = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? zIndex = const $CopyWithPlaceholder(),
    Object? height = const $CopyWithPlaceholder(),
    Object? padding = const $CopyWithPlaceholder(),
    Object? calcParams = const $CopyWithPlaceholder(),
    Object? tipsPadding = const $CopyWithPlaceholder(),
    Object? tickCount = const $CopyWithPlaceholder(),
    Object? lineWidth = const $CopyWithPlaceholder(),
    Object? precision = const $CopyWithPlaceholder(),
  }) {
    return RSIIndicator(
      key: key == const $CopyWithPlaceholder() || key == null
          ? _value.key
          // ignore: cast_nullable_to_non_nullable
          : key as ValueKey<dynamic>,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      zIndex: zIndex == const $CopyWithPlaceholder() || zIndex == null
          ? _value.zIndex
          // ignore: cast_nullable_to_non_nullable
          : zIndex as int,
      height: height == const $CopyWithPlaceholder() || height == null
          ? _value.height
          // ignore: cast_nullable_to_non_nullable
          : height as double,
      padding: padding == const $CopyWithPlaceholder() || padding == null
          ? _value.padding
          // ignore: cast_nullable_to_non_nullable
          : padding as EdgeInsets,
      calcParams:
          calcParams == const $CopyWithPlaceholder() || calcParams == null
              ? _value.calcParams
              // ignore: cast_nullable_to_non_nullable
              : calcParams as List<RsiParam>,
      tipsPadding:
          tipsPadding == const $CopyWithPlaceholder() || tipsPadding == null
              ? _value.tipsPadding
              // ignore: cast_nullable_to_non_nullable
              : tipsPadding as EdgeInsets,
      tickCount: tickCount == const $CopyWithPlaceholder() || tickCount == null
          ? _value.tickCount
          // ignore: cast_nullable_to_non_nullable
          : tickCount as int,
      lineWidth: lineWidth == const $CopyWithPlaceholder() || lineWidth == null
          ? _value.lineWidth
          // ignore: cast_nullable_to_non_nullable
          : lineWidth as double,
      precision: precision == const $CopyWithPlaceholder() || precision == null
          ? _value.precision
          // ignore: cast_nullable_to_non_nullable
          : precision as int,
    );
  }
}

extension $RSIIndicatorCopyWith on RSIIndicator {
  /// Returns a callable class that can be used as follows: `instanceOfRSIIndicator.copyWith(...)` or like so:`instanceOfRSIIndicator.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RSIIndicatorCWProxy get copyWith => _$RSIIndicatorCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RSIIndicator _$RSIIndicatorFromJson(Map<String, dynamic> json) => RSIIndicator(
      key: json['key'] == null
          ? rsiKey
          : const ValueKeyConverter().fromJson(json['key'] as String),
      name: json['name'] as String? ?? 'RSI',
      zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toDouble() ?? defaultSubIndicatorHeight,
      padding: json['padding'] == null
          ? defaultSubIndicatorPadding
          : const EdgeInsetsConverter()
              .fromJson(json['padding'] as Map<String, dynamic>),
      calcParams: (json['calcParams'] as List<dynamic>)
          .map((e) => RsiParam.fromJson(e as Map<String, dynamic>))
          .toList(),
      tipsPadding: const EdgeInsetsConverter()
          .fromJson(json['tipsPadding'] as Map<String, dynamic>),
      tickCount: (json['tickCount'] as num?)?.toInt() ?? defaultSubTickCount,
      lineWidth: (json['lineWidth'] as num).toDouble(),
      precision: (json['precision'] as num?)?.toInt() ?? 2,
    );

Map<String, dynamic> _$RSIIndicatorToJson(RSIIndicator instance) =>
    <String, dynamic>{
      'key': const ValueKeyConverter().toJson(instance.key),
      'name': instance.name,
      'height': instance.height,
      'padding': const EdgeInsetsConverter().toJson(instance.padding),
      'zIndex': instance.zIndex,
      'calcParams': instance.calcParams.map((e) => e.toJson()).toList(),
      'tipsPadding': const EdgeInsetsConverter().toJson(instance.tipsPadding),
      'tickCount': instance.tickCount,
      'lineWidth': instance.lineWidth,
      'precision': instance.precision,
    };
