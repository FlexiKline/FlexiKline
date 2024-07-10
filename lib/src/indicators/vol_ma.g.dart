// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vol_ma.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$VolMaIndicatorCWProxy {
  VolMaIndicator key(ValueKey<dynamic> key);

  VolMaIndicator name(String name);

  VolMaIndicator zIndex(int zIndex);

  VolMaIndicator height(double height);

  VolMaIndicator padding(EdgeInsets padding);

  VolMaIndicator calcParams(List<MaParam> calcParams);

  VolMaIndicator tipsPadding(EdgeInsets tipsPadding);

  VolMaIndicator lineWidth(double lineWidth);

  VolMaIndicator precision(int precision);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `VolMaIndicator(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// VolMaIndicator(...).copyWith(id: 12, name: "My name")
  /// ````
  VolMaIndicator call({
    ValueKey<dynamic>? key,
    String? name,
    int? zIndex,
    double? height,
    EdgeInsets? padding,
    List<MaParam>? calcParams,
    EdgeInsets? tipsPadding,
    double? lineWidth,
    int? precision,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfVolMaIndicator.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfVolMaIndicator.copyWith.fieldName(...)`
class _$VolMaIndicatorCWProxyImpl implements _$VolMaIndicatorCWProxy {
  const _$VolMaIndicatorCWProxyImpl(this._value);

  final VolMaIndicator _value;

  @override
  VolMaIndicator key(ValueKey<dynamic> key) => this(key: key);

  @override
  VolMaIndicator name(String name) => this(name: name);

  @override
  VolMaIndicator zIndex(int zIndex) => this(zIndex: zIndex);

  @override
  VolMaIndicator height(double height) => this(height: height);

  @override
  VolMaIndicator padding(EdgeInsets padding) => this(padding: padding);

  @override
  VolMaIndicator calcParams(List<MaParam> calcParams) =>
      this(calcParams: calcParams);

  @override
  VolMaIndicator tipsPadding(EdgeInsets tipsPadding) =>
      this(tipsPadding: tipsPadding);

  @override
  VolMaIndicator lineWidth(double lineWidth) => this(lineWidth: lineWidth);

  @override
  VolMaIndicator precision(int precision) => this(precision: precision);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `VolMaIndicator(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// VolMaIndicator(...).copyWith(id: 12, name: "My name")
  /// ````
  VolMaIndicator call({
    Object? key = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? zIndex = const $CopyWithPlaceholder(),
    Object? height = const $CopyWithPlaceholder(),
    Object? padding = const $CopyWithPlaceholder(),
    Object? calcParams = const $CopyWithPlaceholder(),
    Object? tipsPadding = const $CopyWithPlaceholder(),
    Object? lineWidth = const $CopyWithPlaceholder(),
    Object? precision = const $CopyWithPlaceholder(),
  }) {
    return VolMaIndicator(
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
      precision: precision == const $CopyWithPlaceholder() || precision == null
          ? _value.precision
          // ignore: cast_nullable_to_non_nullable
          : precision as int,
    );
  }
}

extension $VolMaIndicatorCopyWith on VolMaIndicator {
  /// Returns a callable class that can be used as follows: `instanceOfVolMaIndicator.copyWith(...)` or like so:`instanceOfVolMaIndicator.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$VolMaIndicatorCWProxy get copyWith => _$VolMaIndicatorCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VolMaIndicator _$VolMaIndicatorFromJson(Map<String, dynamic> json) =>
    VolMaIndicator(
      key: json['key'] == null
          ? volMaKey
          : const ValueKeyConverter().fromJson(json['key'] as String),
      name: json['name'] as String? ?? 'VOLMA',
      zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toDouble() ?? defaultSubIndicatorHeight,
      padding: json['padding'] == null
          ? defaultSubIndicatorPadding
          : const EdgeInsetsConverter()
              .fromJson(json['padding'] as Map<String, dynamic>),
      calcParams: (json['calcParams'] as List<dynamic>)
          .map((e) => MaParam.fromJson(e as Map<String, dynamic>))
          .toList(),
      tipsPadding: const EdgeInsetsConverter()
          .fromJson(json['tipsPadding'] as Map<String, dynamic>),
      lineWidth: (json['lineWidth'] as num).toDouble(),
      precision: (json['precision'] as num).toInt(),
    );

Map<String, dynamic> _$VolMaIndicatorToJson(VolMaIndicator instance) =>
    <String, dynamic>{
      'key': const ValueKeyConverter().toJson(instance.key),
      'name': instance.name,
      'height': instance.height,
      'padding': const EdgeInsetsConverter().toJson(instance.padding),
      'zIndex': instance.zIndex,
      'calcParams': instance.calcParams.map((e) => e.toJson()).toList(),
      'tipsPadding': const EdgeInsetsConverter().toJson(instance.tipsPadding),
      'lineWidth': instance.lineWidth,
      'precision': instance.precision,
    };
