// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ema.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$EMAIndicatorCWProxy {
  EMAIndicator key(ValueKey<dynamic> key);

  EMAIndicator name(String name);

  EMAIndicator zIndex(int zIndex);

  EMAIndicator height(double height);

  EMAIndicator padding(EdgeInsets padding);

  EMAIndicator calcParams(List<MaParam> calcParams);

  EMAIndicator tipsPadding(EdgeInsets tipsPadding);

  EMAIndicator lineWidth(double lineWidth);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `EMAIndicator(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// EMAIndicator(...).copyWith(id: 12, name: "My name")
  /// ````
  EMAIndicator call({
    ValueKey<dynamic>? key,
    String? name,
    int? zIndex,
    double? height,
    EdgeInsets? padding,
    List<MaParam>? calcParams,
    EdgeInsets? tipsPadding,
    double? lineWidth,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfEMAIndicator.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfEMAIndicator.copyWith.fieldName(...)`
class _$EMAIndicatorCWProxyImpl implements _$EMAIndicatorCWProxy {
  const _$EMAIndicatorCWProxyImpl(this._value);

  final EMAIndicator _value;

  @override
  EMAIndicator key(ValueKey<dynamic> key) => this(key: key);

  @override
  EMAIndicator name(String name) => this(name: name);

  @override
  EMAIndicator zIndex(int zIndex) => this(zIndex: zIndex);

  @override
  EMAIndicator height(double height) => this(height: height);

  @override
  EMAIndicator padding(EdgeInsets padding) => this(padding: padding);

  @override
  EMAIndicator calcParams(List<MaParam> calcParams) =>
      this(calcParams: calcParams);

  @override
  EMAIndicator tipsPadding(EdgeInsets tipsPadding) =>
      this(tipsPadding: tipsPadding);

  @override
  EMAIndicator lineWidth(double lineWidth) => this(lineWidth: lineWidth);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `EMAIndicator(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// EMAIndicator(...).copyWith(id: 12, name: "My name")
  /// ````
  EMAIndicator call({
    Object? key = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? zIndex = const $CopyWithPlaceholder(),
    Object? height = const $CopyWithPlaceholder(),
    Object? padding = const $CopyWithPlaceholder(),
    Object? calcParams = const $CopyWithPlaceholder(),
    Object? tipsPadding = const $CopyWithPlaceholder(),
    Object? lineWidth = const $CopyWithPlaceholder(),
  }) {
    return EMAIndicator(
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
              : calcParams as List<MaParam>,
      tipsPadding:
          tipsPadding == const $CopyWithPlaceholder() || tipsPadding == null
              ? _value.tipsPadding
              // ignore: cast_nullable_to_non_nullable
              : tipsPadding as EdgeInsets,
      lineWidth: lineWidth == const $CopyWithPlaceholder() || lineWidth == null
          ? _value.lineWidth
          // ignore: cast_nullable_to_non_nullable
          : lineWidth as double,
    );
  }
}

extension $EMAIndicatorCopyWith on EMAIndicator {
  /// Returns a callable class that can be used as follows: `instanceOfEMAIndicator.copyWith(...)` or like so:`instanceOfEMAIndicator.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$EMAIndicatorCWProxy get copyWith => _$EMAIndicatorCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EMAIndicator _$EMAIndicatorFromJson(Map<String, dynamic> json) => EMAIndicator(
      key: json['key'] == null
          ? emaKey
          : const ValueKeyConverter().fromJson(json['key'] as String),
      name: json['name'] as String? ?? 'EMA',
      zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num).toDouble(),
      padding: json['padding'] == null
          ? defaultMainIndicatorPadding
          : const EdgeInsetsConverter()
              .fromJson(json['padding'] as Map<String, dynamic>),
      calcParams: (json['calcParams'] as List<dynamic>)
          .map((e) => MaParam.fromJson(e as Map<String, dynamic>))
          .toList(),
      tipsPadding: const EdgeInsetsConverter()
          .fromJson(json['tipsPadding'] as Map<String, dynamic>),
      lineWidth: (json['lineWidth'] as num).toDouble(),
    );

Map<String, dynamic> _$EMAIndicatorToJson(EMAIndicator instance) =>
    <String, dynamic>{
      'key': const ValueKeyConverter().toJson(instance.key),
      'name': instance.name,
      'height': instance.height,
      'padding': const EdgeInsetsConverter().toJson(instance.padding),
      'zIndex': instance.zIndex,
      'calcParams': instance.calcParams.map((e) => e.toJson()).toList(),
      'tipsPadding': const EdgeInsetsConverter().toJson(instance.tipsPadding),
      'lineWidth': instance.lineWidth,
    };
