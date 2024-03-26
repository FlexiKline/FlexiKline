// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'candle_req.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CandleReq _$CandleReqFromJson(Map<String, dynamic> json) {
  return _CandleReq.fromJson(json);
}

/// @nodoc
mixin _$CandleReq {
  /// 产品ID，如 BTC-USDT
  String get instId => throw _privateConstructorUsedError;

  /// 产品ID，如 BTC-USDT
  set instId(String value) => throw _privateConstructorUsedError;

  /// 请求此时间戳之前（更旧的数据）的分页内容，传的值为对应接口的ts
  int? get after => throw _privateConstructorUsedError;

  /// 请求此时间戳之前（更旧的数据）的分页内容，传的值为对应接口的ts
  set after(int? value) => throw _privateConstructorUsedError;

  /// 请求此时间戳之后（更新的数据）的分页内容，传的值为对应接口的ts, 单独使用时，会返回最新的数据。
  int? get before => throw _privateConstructorUsedError;

  /// 请求此时间戳之后（更新的数据）的分页内容，传的值为对应接口的ts, 单独使用时，会返回最新的数据。
  set before(int? value) => throw _privateConstructorUsedError;

  /// 时间粒度，默认值1m
  /// 如 [1m/3m/5m/15m/30m/1H/2H/4H]
  /// 香港时间开盘价k线：[6H/12H/1D/2D/3D/1W/1M/3M]
  /// UTC时间开盘价k线：[/6Hutc/12Hutc/1Dutc/2Dutc/3Dutc/1Wutc/1Mutc/3Mutc]
  String get bar => throw _privateConstructorUsedError;

  /// 时间粒度，默认值1m
  /// 如 [1m/3m/5m/15m/30m/1H/2H/4H]
  /// 香港时间开盘价k线：[6H/12H/1D/2D/3D/1W/1M/3M]
  /// UTC时间开盘价k线：[/6Hutc/12Hutc/1Dutc/2Dutc/3Dutc/1Wutc/1Mutc/3Mutc]
  set bar(String value) => throw _privateConstructorUsedError;

  /// 分页返回的结果集数量，最大为300，不填默认返回100条
  int get limit => throw _privateConstructorUsedError;

  /// 分页返回的结果集数量，最大为300，不填默认返回100条
  set limit(int value) => throw _privateConstructorUsedError;

  /// 当前交易对精度
  int get precision => throw _privateConstructorUsedError;

  /// 当前交易对精度
  set precision(int value) => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CandleReqCopyWith<CandleReq> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CandleReqCopyWith<$Res> {
  factory $CandleReqCopyWith(CandleReq value, $Res Function(CandleReq) then) =
      _$CandleReqCopyWithImpl<$Res, CandleReq>;
  @useResult
  $Res call(
      {String instId,
      int? after,
      int? before,
      String bar,
      int limit,
      int precision});
}

/// @nodoc
class _$CandleReqCopyWithImpl<$Res, $Val extends CandleReq>
    implements $CandleReqCopyWith<$Res> {
  _$CandleReqCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? instId = null,
    Object? after = freezed,
    Object? before = freezed,
    Object? bar = null,
    Object? limit = null,
    Object? precision = null,
  }) {
    return _then(_value.copyWith(
      instId: null == instId
          ? _value.instId
          : instId // ignore: cast_nullable_to_non_nullable
              as String,
      after: freezed == after
          ? _value.after
          : after // ignore: cast_nullable_to_non_nullable
              as int?,
      before: freezed == before
          ? _value.before
          : before // ignore: cast_nullable_to_non_nullable
              as int?,
      bar: null == bar
          ? _value.bar
          : bar // ignore: cast_nullable_to_non_nullable
              as String,
      limit: null == limit
          ? _value.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int,
      precision: null == precision
          ? _value.precision
          : precision // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CandleReqImplCopyWith<$Res>
    implements $CandleReqCopyWith<$Res> {
  factory _$$CandleReqImplCopyWith(
          _$CandleReqImpl value, $Res Function(_$CandleReqImpl) then) =
      __$$CandleReqImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String instId,
      int? after,
      int? before,
      String bar,
      int limit,
      int precision});
}

/// @nodoc
class __$$CandleReqImplCopyWithImpl<$Res>
    extends _$CandleReqCopyWithImpl<$Res, _$CandleReqImpl>
    implements _$$CandleReqImplCopyWith<$Res> {
  __$$CandleReqImplCopyWithImpl(
      _$CandleReqImpl _value, $Res Function(_$CandleReqImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? instId = null,
    Object? after = freezed,
    Object? before = freezed,
    Object? bar = null,
    Object? limit = null,
    Object? precision = null,
  }) {
    return _then(_$CandleReqImpl(
      instId: null == instId
          ? _value.instId
          : instId // ignore: cast_nullable_to_non_nullable
              as String,
      after: freezed == after
          ? _value.after
          : after // ignore: cast_nullable_to_non_nullable
              as int?,
      before: freezed == before
          ? _value.before
          : before // ignore: cast_nullable_to_non_nullable
              as int?,
      bar: null == bar
          ? _value.bar
          : bar // ignore: cast_nullable_to_non_nullable
              as String,
      limit: null == limit
          ? _value.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int,
      precision: null == precision
          ? _value.precision
          : precision // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CandleReqImpl implements _CandleReq {
  _$CandleReqImpl(
      {required this.instId,
      this.after,
      this.before,
      this.bar = "1m",
      this.limit = 100,
      this.precision = 6});

  factory _$CandleReqImpl.fromJson(Map<String, dynamic> json) =>
      _$$CandleReqImplFromJson(json);

  /// 产品ID，如 BTC-USDT
  @override
  String instId;

  /// 请求此时间戳之前（更旧的数据）的分页内容，传的值为对应接口的ts
  @override
  int? after;

  /// 请求此时间戳之后（更新的数据）的分页内容，传的值为对应接口的ts, 单独使用时，会返回最新的数据。
  @override
  int? before;

  /// 时间粒度，默认值1m
  /// 如 [1m/3m/5m/15m/30m/1H/2H/4H]
  /// 香港时间开盘价k线：[6H/12H/1D/2D/3D/1W/1M/3M]
  /// UTC时间开盘价k线：[/6Hutc/12Hutc/1Dutc/2Dutc/3Dutc/1Wutc/1Mutc/3Mutc]
  @override
  @JsonKey()
  String bar;

  /// 分页返回的结果集数量，最大为300，不填默认返回100条
  @override
  @JsonKey()
  int limit;

  /// 当前交易对精度
  @override
  @JsonKey()
  int precision;

  @override
  String toString() {
    return 'CandleReq(instId: $instId, after: $after, before: $before, bar: $bar, limit: $limit, precision: $precision)';
  }

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CandleReqImplCopyWith<_$CandleReqImpl> get copyWith =>
      __$$CandleReqImplCopyWithImpl<_$CandleReqImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CandleReqImplToJson(
      this,
    );
  }
}

abstract class _CandleReq implements CandleReq {
  factory _CandleReq(
      {required String instId,
      int? after,
      int? before,
      String bar,
      int limit,
      int precision}) = _$CandleReqImpl;

  factory _CandleReq.fromJson(Map<String, dynamic> json) =
      _$CandleReqImpl.fromJson;

  @override

  /// 产品ID，如 BTC-USDT
  String get instId;

  /// 产品ID，如 BTC-USDT
  set instId(String value);
  @override

  /// 请求此时间戳之前（更旧的数据）的分页内容，传的值为对应接口的ts
  int? get after;

  /// 请求此时间戳之前（更旧的数据）的分页内容，传的值为对应接口的ts
  set after(int? value);
  @override

  /// 请求此时间戳之后（更新的数据）的分页内容，传的值为对应接口的ts, 单独使用时，会返回最新的数据。
  int? get before;

  /// 请求此时间戳之后（更新的数据）的分页内容，传的值为对应接口的ts, 单独使用时，会返回最新的数据。
  set before(int? value);
  @override

  /// 时间粒度，默认值1m
  /// 如 [1m/3m/5m/15m/30m/1H/2H/4H]
  /// 香港时间开盘价k线：[6H/12H/1D/2D/3D/1W/1M/3M]
  /// UTC时间开盘价k线：[/6Hutc/12Hutc/1Dutc/2Dutc/3Dutc/1Wutc/1Mutc/3Mutc]
  String get bar;

  /// 时间粒度，默认值1m
  /// 如 [1m/3m/5m/15m/30m/1H/2H/4H]
  /// 香港时间开盘价k线：[6H/12H/1D/2D/3D/1W/1M/3M]
  /// UTC时间开盘价k线：[/6Hutc/12Hutc/1Dutc/2Dutc/3Dutc/1Wutc/1Mutc/3Mutc]
  set bar(String value);
  @override

  /// 分页返回的结果集数量，最大为300，不填默认返回100条
  int get limit;

  /// 分页返回的结果集数量，最大为300，不填默认返回100条
  set limit(int value);
  @override

  /// 当前交易对精度
  int get precision;

  /// 当前交易对精度
  set precision(int value);
  @override
  @JsonKey(ignore: true)
  _$$CandleReqImplCopyWith<_$CandleReqImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
