// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'macd_param.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MACDParamCWProxy {
  MACDParam s(int s);

  MACDParam l(int l);

  MACDParam m(int m);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MACDParam(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MACDParam(...).copyWith(id: 12, name: "My name")
  /// ````
  MACDParam call({
    int? s,
    int? l,
    int? m,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMACDParam.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMACDParam.copyWith.fieldName(...)`
class _$MACDParamCWProxyImpl implements _$MACDParamCWProxy {
  const _$MACDParamCWProxyImpl(this._value);

  final MACDParam _value;

  @override
  MACDParam s(int s) => this(s: s);

  @override
  MACDParam l(int l) => this(l: l);

  @override
  MACDParam m(int m) => this(m: m);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MACDParam(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MACDParam(...).copyWith(id: 12, name: "My name")
  /// ````
  MACDParam call({
    Object? s = const $CopyWithPlaceholder(),
    Object? l = const $CopyWithPlaceholder(),
    Object? m = const $CopyWithPlaceholder(),
  }) {
    return MACDParam(
      s: s == const $CopyWithPlaceholder() || s == null
          ? _value.s
          // ignore: cast_nullable_to_non_nullable
          : s as int,
      l: l == const $CopyWithPlaceholder() || l == null
          ? _value.l
          // ignore: cast_nullable_to_non_nullable
          : l as int,
      m: m == const $CopyWithPlaceholder() || m == null
          ? _value.m
          // ignore: cast_nullable_to_non_nullable
          : m as int,
    );
  }
}

extension $MACDParamCopyWith on MACDParam {
  /// Returns a callable class that can be used as follows: `instanceOfMACDParam.copyWith(...)` or like so:`instanceOfMACDParam.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MACDParamCWProxy get copyWith => _$MACDParamCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MACDParam _$MACDParamFromJson(Map<String, dynamic> json) => MACDParam(
      s: (json['s'] as num).toInt(),
      l: (json['l'] as num).toInt(),
      m: (json['m'] as num).toInt(),
    );

Map<String, dynamic> _$MACDParamToJson(MACDParam instance) => <String, dynamic>{
      's': instance.s,
      'l': instance.l,
      'm': instance.m,
    };
