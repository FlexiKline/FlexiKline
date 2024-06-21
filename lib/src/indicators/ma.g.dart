// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ma.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MAIndicatorCWProxy {
  MAIndicator key(ValueKey<dynamic> key);

  MAIndicator name(String name);

  MAIndicator zIndex(int zIndex);

  MAIndicator height(double height);

  MAIndicator padding(EdgeInsets padding);

  MAIndicator calcParams(List<MaParam> calcParams);

  MAIndicator tipsPadding(EdgeInsets tipsPadding);

  MAIndicator lineWidth(double lineWidth);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MAIndicator(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MAIndicator(...).copyWith(id: 12, name: "My name")
  /// ````
  MAIndicator call({
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

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMAIndicator.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMAIndicator.copyWith.fieldName(...)`
class _$MAIndicatorCWProxyImpl implements _$MAIndicatorCWProxy {
  const _$MAIndicatorCWProxyImpl(this._value);

  final MAIndicator _value;

  @override
  MAIndicator key(ValueKey<dynamic> key) => this(key: key);

  @override
  MAIndicator name(String name) => this(name: name);

  @override
  MAIndicator zIndex(int zIndex) => this(zIndex: zIndex);

  @override
  MAIndicator height(double height) => this(height: height);

  @override
  MAIndicator padding(EdgeInsets padding) => this(padding: padding);

  @override
  MAIndicator calcParams(List<MaParam> calcParams) =>
      this(calcParams: calcParams);

  @override
  MAIndicator tipsPadding(EdgeInsets tipsPadding) =>
      this(tipsPadding: tipsPadding);

  @override
  MAIndicator lineWidth(double lineWidth) => this(lineWidth: lineWidth);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MAIndicator(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MAIndicator(...).copyWith(id: 12, name: "My name")
  /// ````
  MAIndicator call({
    Object? key = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? zIndex = const $CopyWithPlaceholder(),
    Object? height = const $CopyWithPlaceholder(),
    Object? padding = const $CopyWithPlaceholder(),
    Object? calcParams = const $CopyWithPlaceholder(),
    Object? tipsPadding = const $CopyWithPlaceholder(),
    Object? lineWidth = const $CopyWithPlaceholder(),
  }) {
    return MAIndicator(
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

extension $MAIndicatorCopyWith on MAIndicator {
  /// Returns a callable class that can be used as follows: `instanceOfMAIndicator.copyWith(...)` or like so:`instanceOfMAIndicator.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MAIndicatorCWProxy get copyWith => _$MAIndicatorCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MAIndicator _$MAIndicatorFromJson(Map<String, dynamic> json) => MAIndicator(
      key: json['key'] == null
          ? maKey
          : const ValueKeyConverter().fromJson(json['key'] as String),
      name: json['name'] as String? ?? 'MA',
      zIndex: (json['zIndex'] as num?)?.toInt() ?? 1,
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

Map<String, dynamic> _$MAIndicatorToJson(MAIndicator instance) =>
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
