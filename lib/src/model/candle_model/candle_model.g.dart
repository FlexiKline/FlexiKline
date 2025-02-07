// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'candle_model.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CandleModelCWProxy {
  CandleModel ts(int ts);

  CandleModel o(Decimal o);

  CandleModel h(Decimal h);

  CandleModel l(Decimal l);

  CandleModel c(Decimal c);

  CandleModel v(Decimal v);

  CandleModel vc(Decimal? vc);

  CandleModel vcq(Decimal? vcq);

  CandleModel confirm(String confirm);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CandleModel(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CandleModel(...).copyWith(id: 12, name: "My name")
  /// ````
  CandleModel call({
    int ts,
    Decimal o,
    Decimal h,
    Decimal l,
    Decimal c,
    Decimal v,
    Decimal? vc,
    Decimal? vcq,
    String confirm,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCandleModel.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCandleModel.copyWith.fieldName(...)`
class _$CandleModelCWProxyImpl implements _$CandleModelCWProxy {
  const _$CandleModelCWProxyImpl(this._value);

  final CandleModel _value;

  @override
  CandleModel ts(int ts) => this(ts: ts);

  @override
  CandleModel o(Decimal o) => this(o: o);

  @override
  CandleModel h(Decimal h) => this(h: h);

  @override
  CandleModel l(Decimal l) => this(l: l);

  @override
  CandleModel c(Decimal c) => this(c: c);

  @override
  CandleModel v(Decimal v) => this(v: v);

  @override
  CandleModel vc(Decimal? vc) => this(vc: vc);

  @override
  CandleModel vcq(Decimal? vcq) => this(vcq: vcq);

  @override
  CandleModel confirm(String confirm) => this(confirm: confirm);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CandleModel(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CandleModel(...).copyWith(id: 12, name: "My name")
  /// ````
  CandleModel call({
    Object? ts = const $CopyWithPlaceholder(),
    Object? o = const $CopyWithPlaceholder(),
    Object? h = const $CopyWithPlaceholder(),
    Object? l = const $CopyWithPlaceholder(),
    Object? c = const $CopyWithPlaceholder(),
    Object? v = const $CopyWithPlaceholder(),
    Object? vc = const $CopyWithPlaceholder(),
    Object? vcq = const $CopyWithPlaceholder(),
    Object? confirm = const $CopyWithPlaceholder(),
  }) {
    return CandleModel(
      ts: ts == const $CopyWithPlaceholder()
          ? _value.ts
          // ignore: cast_nullable_to_non_nullable
          : ts as int,
      o: o == const $CopyWithPlaceholder()
          ? _value.o
          // ignore: cast_nullable_to_non_nullable
          : o as Decimal,
      h: h == const $CopyWithPlaceholder()
          ? _value.h
          // ignore: cast_nullable_to_non_nullable
          : h as Decimal,
      l: l == const $CopyWithPlaceholder()
          ? _value.l
          // ignore: cast_nullable_to_non_nullable
          : l as Decimal,
      c: c == const $CopyWithPlaceholder()
          ? _value.c
          // ignore: cast_nullable_to_non_nullable
          : c as Decimal,
      v: v == const $CopyWithPlaceholder()
          ? _value.v
          // ignore: cast_nullable_to_non_nullable
          : v as Decimal,
      vc: vc == const $CopyWithPlaceholder()
          ? _value.vc
          // ignore: cast_nullable_to_non_nullable
          : vc as Decimal?,
      vcq: vcq == const $CopyWithPlaceholder()
          ? _value.vcq
          // ignore: cast_nullable_to_non_nullable
          : vcq as Decimal?,
      confirm: confirm == const $CopyWithPlaceholder()
          ? _value.confirm
          // ignore: cast_nullable_to_non_nullable
          : confirm as String,
    );
  }
}

extension $CandleModelCopyWith on CandleModel {
  /// Returns a callable class that can be used as follows: `instanceOfCandleModel.copyWith(...)` or like so:`instanceOfCandleModel.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CandleModelCWProxy get copyWith => _$CandleModelCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CandleModel _$CandleModelFromJson(Map<String, dynamic> json) => CandleModel(
      ts: valueToInt(json['ts']),
      o: const DecimalConverter().fromJson(json['o']),
      h: const DecimalConverter().fromJson(json['h']),
      l: const DecimalConverter().fromJson(json['l']),
      c: const DecimalConverter().fromJson(json['c']),
      v: const DecimalConverter().fromJson(json['v']),
      vc: const DecimalConverter().fromJson(json['vc']),
      vcq: const DecimalConverter().fromJson(json['vcq']),
      confirm: json['confirm'] as String? ?? '1',
    );

Map<String, dynamic> _$CandleModelToJson(CandleModel instance) =>
    <String, dynamic>{
      'ts': intToString(instance.ts),
      if (const DecimalConverter().toJson(instance.o) case final value?)
        'o': value,
      if (const DecimalConverter().toJson(instance.h) case final value?)
        'h': value,
      if (const DecimalConverter().toJson(instance.l) case final value?)
        'l': value,
      if (const DecimalConverter().toJson(instance.c) case final value?)
        'c': value,
      if (const DecimalConverter().toJson(instance.v) case final value?)
        'v': value,
      if (_$JsonConverterToJson<dynamic, Decimal>(
              instance.vc, const DecimalConverter().toJson)
          case final value?)
        'vc': value,
      if (_$JsonConverterToJson<dynamic, Decimal>(
              instance.vcq, const DecimalConverter().toJson)
          case final value?)
        'vcq': value,
      'confirm': instance.confirm,
    };

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
