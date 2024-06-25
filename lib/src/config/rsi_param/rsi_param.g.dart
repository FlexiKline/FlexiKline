// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rsi_param.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RsiParamCWProxy {
  RsiParam count(int count);

  RsiParam tips(TipsConfig tips);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RsiParam(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RsiParam(...).copyWith(id: 12, name: "My name")
  /// ````
  RsiParam call({
    int? count,
    TipsConfig? tips,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRsiParam.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRsiParam.copyWith.fieldName(...)`
class _$RsiParamCWProxyImpl implements _$RsiParamCWProxy {
  const _$RsiParamCWProxyImpl(this._value);

  final RsiParam _value;

  @override
  RsiParam count(int count) => this(count: count);

  @override
  RsiParam tips(TipsConfig tips) => this(tips: tips);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RsiParam(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RsiParam(...).copyWith(id: 12, name: "My name")
  /// ````
  RsiParam call({
    Object? count = const $CopyWithPlaceholder(),
    Object? tips = const $CopyWithPlaceholder(),
  }) {
    return RsiParam(
      count: count == const $CopyWithPlaceholder() || count == null
          ? _value.count
          // ignore: cast_nullable_to_non_nullable
          : count as int,
      tips: tips == const $CopyWithPlaceholder() || tips == null
          ? _value.tips
          // ignore: cast_nullable_to_non_nullable
          : tips as TipsConfig,
    );
  }
}

extension $RsiParamCopyWith on RsiParam {
  /// Returns a callable class that can be used as follows: `instanceOfRsiParam.copyWith(...)` or like so:`instanceOfRsiParam.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RsiParamCWProxy get copyWith => _$RsiParamCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RsiParam _$RsiParamFromJson(Map<String, dynamic> json) => RsiParam(
      count: (json['count'] as num).toInt(),
      tips: TipsConfig.fromJson(json['tips'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RsiParamToJson(RsiParam instance) => <String, dynamic>{
      'count': instance.count,
      'tips': instance.tips.toJson(),
    };
