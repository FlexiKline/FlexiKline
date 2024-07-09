// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ma_param.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MaParamCWProxy {
  MaParam key(ValueKey<dynamic> key);

  MaParam count(int count);

  MaParam tips(TipsConfig tips);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MaParam(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MaParam(...).copyWith(id: 12, name: "My name")
  /// ````
  MaParam call({
    ValueKey<dynamic>? key,
    int? count,
    TipsConfig? tips,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMaParam.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMaParam.copyWith.fieldName(...)`
class _$MaParamCWProxyImpl implements _$MaParamCWProxy {
  const _$MaParamCWProxyImpl(this._value);

  final MaParam _value;

  @override
  MaParam key(ValueKey<dynamic> key) => this(key: key);

  @override
  MaParam count(int count) => this(count: count);

  @override
  MaParam tips(TipsConfig tips) => this(tips: tips);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MaParam(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MaParam(...).copyWith(id: 12, name: "My name")
  /// ````
  MaParam call({
    Object? key = const $CopyWithPlaceholder(),
    Object? count = const $CopyWithPlaceholder(),
    Object? tips = const $CopyWithPlaceholder(),
  }) {
    return MaParam(
      key: key == const $CopyWithPlaceholder() || key == null
          ? _value.key
          // ignore: cast_nullable_to_non_nullable
          : key as ValueKey<dynamic>,
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

extension $MaParamCopyWith on MaParam {
  /// Returns a callable class that can be used as follows: `instanceOfMaParam.copyWith(...)` or like so:`instanceOfMaParam.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MaParamCWProxy get copyWith => _$MaParamCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MaParam _$MaParamFromJson(Map<String, dynamic> json) => MaParam(
      key: const ValueKeyConverter().fromJson(json['key'] as String),
      count: (json['count'] as num).toInt(),
      tips: TipsConfig.fromJson(json['tips'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MaParamToJson(MaParam instance) => <String, dynamic>{
      'key': const ValueKeyConverter().toJson(instance.key),
      'count': instance.count,
      'tips': instance.tips.toJson(),
    };
