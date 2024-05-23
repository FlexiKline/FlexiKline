// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kdj_param.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$KDJParamCWProxy {
  KDJParam n(int n);

  KDJParam m1(int m1);

  KDJParam m2(int m2);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `KDJParam(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// KDJParam(...).copyWith(id: 12, name: "My name")
  /// ````
  KDJParam call({
    int? n,
    int? m1,
    int? m2,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfKDJParam.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfKDJParam.copyWith.fieldName(...)`
class _$KDJParamCWProxyImpl implements _$KDJParamCWProxy {
  const _$KDJParamCWProxyImpl(this._value);

  final KDJParam _value;

  @override
  KDJParam n(int n) => this(n: n);

  @override
  KDJParam m1(int m1) => this(m1: m1);

  @override
  KDJParam m2(int m2) => this(m2: m2);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `KDJParam(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// KDJParam(...).copyWith(id: 12, name: "My name")
  /// ````
  KDJParam call({
    Object? n = const $CopyWithPlaceholder(),
    Object? m1 = const $CopyWithPlaceholder(),
    Object? m2 = const $CopyWithPlaceholder(),
  }) {
    return KDJParam(
      n: n == const $CopyWithPlaceholder() || n == null
          ? _value.n
          // ignore: cast_nullable_to_non_nullable
          : n as int,
      m1: m1 == const $CopyWithPlaceholder() || m1 == null
          ? _value.m1
          // ignore: cast_nullable_to_non_nullable
          : m1 as int,
      m2: m2 == const $CopyWithPlaceholder() || m2 == null
          ? _value.m2
          // ignore: cast_nullable_to_non_nullable
          : m2 as int,
    );
  }
}

extension $KDJParamCopyWith on KDJParam {
  /// Returns a callable class that can be used as follows: `instanceOfKDJParam.copyWith(...)` or like so:`instanceOfKDJParam.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$KDJParamCWProxy get copyWith => _$KDJParamCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KDJParam _$KDJParamFromJson(Map<String, dynamic> json) => KDJParam(
      n: (json['n'] as num).toInt(),
      m1: (json['m1'] as num).toInt(),
      m2: (json['m2'] as num).toInt(),
    );

Map<String, dynamic> _$KDJParamToJson(KDJParam instance) => <String, dynamic>{
      'n': instance.n,
      'm1': instance.m1,
      'm2': instance.m2,
    };
