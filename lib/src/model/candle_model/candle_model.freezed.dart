// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'candle_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CandleModel _$CandleModelFromJson(Map<String, dynamic> json) {
  return _CandleModel.fromJson(json);
}

/// @nodoc
mixin _$CandleModel {
  /// 开始时间，Unix时间戳的毫秒数格式，如 1597026383085
  @JsonKey(fromJson: valueToInt, toJson: intToString)
  int get timestamp =>
      throw _privateConstructorUsedError; // @JsonKey(fromJson: valueToDateTime, toJson: dateTimeToInt)
// DateTime? datetime, // 从timestamp转换为dateTime;
  /// 开盘价格
  @JsonKey(fromJson: stringToDecimal, toJson: decimalToString)
  Decimal get open => throw _privateConstructorUsedError;

  /// 最高价格
  @JsonKey(fromJson: stringToDecimal, toJson: decimalToString)
  Decimal get high => throw _privateConstructorUsedError;

  ///最低价格
  @JsonKey(fromJson: stringToDecimal, toJson: decimalToString)
  Decimal get low => throw _privateConstructorUsedError;

  /// 收盘价格
  @JsonKey(fromJson: stringToDecimal, toJson: decimalToString)
  Decimal get close => throw _privateConstructorUsedError;

  /// 交易量，以张为单位: 如果是衍生品合约，数值为合约的张数。如果是币币/币币杠杆，数值为交易货币的数量。
  @JsonKey(fromJson: stringToDecimal, toJson: decimalToString)
  Decimal get vol => throw _privateConstructorUsedError;

  /// 交易量(成交额)，以币为单位: 如果是衍生品合约，数值为交易货币的数量。如果是币币/币币杠杆，数值为计价货币的数量。
  @JsonKey(fromJson: stringToDecimalOrNull, toJson: decimalToStringOrNull)
  Decimal? get volCcy => throw _privateConstructorUsedError;

  ///交易量(成交额)，以计价货币为单位: 如 BTC-USDT和BTC-USDT-SWAP，单位均是USDT。BTC-USD-SWAP单位是USD。
  @JsonKey(fromJson: stringToDecimalOrNull, toJson: decimalToStringOrNull)
  Decimal? get volCcyQuote => throw _privateConstructorUsedError;

  /// K线状态:  0：K线未完结  1：K线已完结
  String get confirm => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CandleModelCopyWith<CandleModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CandleModelCopyWith<$Res> {
  factory $CandleModelCopyWith(
          CandleModel value, $Res Function(CandleModel) then) =
      _$CandleModelCopyWithImpl<$Res, CandleModel>;
  @useResult
  $Res call(
      {@JsonKey(fromJson: valueToInt, toJson: intToString) int timestamp,
      @JsonKey(fromJson: stringToDecimal, toJson: decimalToString) Decimal open,
      @JsonKey(fromJson: stringToDecimal, toJson: decimalToString) Decimal high,
      @JsonKey(fromJson: stringToDecimal, toJson: decimalToString) Decimal low,
      @JsonKey(fromJson: stringToDecimal, toJson: decimalToString)
      Decimal close,
      @JsonKey(fromJson: stringToDecimal, toJson: decimalToString) Decimal vol,
      @JsonKey(fromJson: stringToDecimalOrNull, toJson: decimalToStringOrNull)
      Decimal? volCcy,
      @JsonKey(fromJson: stringToDecimalOrNull, toJson: decimalToStringOrNull)
      Decimal? volCcyQuote,
      String confirm});
}

/// @nodoc
class _$CandleModelCopyWithImpl<$Res, $Val extends CandleModel>
    implements $CandleModelCopyWith<$Res> {
  _$CandleModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? timestamp = null,
    Object? open = null,
    Object? high = null,
    Object? low = null,
    Object? close = null,
    Object? vol = null,
    Object? volCcy = freezed,
    Object? volCcyQuote = freezed,
    Object? confirm = null,
  }) {
    return _then(_value.copyWith(
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as int,
      open: null == open
          ? _value.open
          : open // ignore: cast_nullable_to_non_nullable
              as Decimal,
      high: null == high
          ? _value.high
          : high // ignore: cast_nullable_to_non_nullable
              as Decimal,
      low: null == low
          ? _value.low
          : low // ignore: cast_nullable_to_non_nullable
              as Decimal,
      close: null == close
          ? _value.close
          : close // ignore: cast_nullable_to_non_nullable
              as Decimal,
      vol: null == vol
          ? _value.vol
          : vol // ignore: cast_nullable_to_non_nullable
              as Decimal,
      volCcy: freezed == volCcy
          ? _value.volCcy
          : volCcy // ignore: cast_nullable_to_non_nullable
              as Decimal?,
      volCcyQuote: freezed == volCcyQuote
          ? _value.volCcyQuote
          : volCcyQuote // ignore: cast_nullable_to_non_nullable
              as Decimal?,
      confirm: null == confirm
          ? _value.confirm
          : confirm // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CandleModelImplCopyWith<$Res>
    implements $CandleModelCopyWith<$Res> {
  factory _$$CandleModelImplCopyWith(
          _$CandleModelImpl value, $Res Function(_$CandleModelImpl) then) =
      __$$CandleModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(fromJson: valueToInt, toJson: intToString) int timestamp,
      @JsonKey(fromJson: stringToDecimal, toJson: decimalToString) Decimal open,
      @JsonKey(fromJson: stringToDecimal, toJson: decimalToString) Decimal high,
      @JsonKey(fromJson: stringToDecimal, toJson: decimalToString) Decimal low,
      @JsonKey(fromJson: stringToDecimal, toJson: decimalToString)
      Decimal close,
      @JsonKey(fromJson: stringToDecimal, toJson: decimalToString) Decimal vol,
      @JsonKey(fromJson: stringToDecimalOrNull, toJson: decimalToStringOrNull)
      Decimal? volCcy,
      @JsonKey(fromJson: stringToDecimalOrNull, toJson: decimalToStringOrNull)
      Decimal? volCcyQuote,
      String confirm});
}

/// @nodoc
class __$$CandleModelImplCopyWithImpl<$Res>
    extends _$CandleModelCopyWithImpl<$Res, _$CandleModelImpl>
    implements _$$CandleModelImplCopyWith<$Res> {
  __$$CandleModelImplCopyWithImpl(
      _$CandleModelImpl _value, $Res Function(_$CandleModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? timestamp = null,
    Object? open = null,
    Object? high = null,
    Object? low = null,
    Object? close = null,
    Object? vol = null,
    Object? volCcy = freezed,
    Object? volCcyQuote = freezed,
    Object? confirm = null,
  }) {
    return _then(_$CandleModelImpl(
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as int,
      open: null == open
          ? _value.open
          : open // ignore: cast_nullable_to_non_nullable
              as Decimal,
      high: null == high
          ? _value.high
          : high // ignore: cast_nullable_to_non_nullable
              as Decimal,
      low: null == low
          ? _value.low
          : low // ignore: cast_nullable_to_non_nullable
              as Decimal,
      close: null == close
          ? _value.close
          : close // ignore: cast_nullable_to_non_nullable
              as Decimal,
      vol: null == vol
          ? _value.vol
          : vol // ignore: cast_nullable_to_non_nullable
              as Decimal,
      volCcy: freezed == volCcy
          ? _value.volCcy
          : volCcy // ignore: cast_nullable_to_non_nullable
              as Decimal?,
      volCcyQuote: freezed == volCcyQuote
          ? _value.volCcyQuote
          : volCcyQuote // ignore: cast_nullable_to_non_nullable
              as Decimal?,
      confirm: null == confirm
          ? _value.confirm
          : confirm // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CandleModelImpl implements _CandleModel {
  _$CandleModelImpl(
      {@JsonKey(fromJson: valueToInt, toJson: intToString)
      required this.timestamp,
      @JsonKey(fromJson: stringToDecimal, toJson: decimalToString)
      required this.open,
      @JsonKey(fromJson: stringToDecimal, toJson: decimalToString)
      required this.high,
      @JsonKey(fromJson: stringToDecimal, toJson: decimalToString)
      required this.low,
      @JsonKey(fromJson: stringToDecimal, toJson: decimalToString)
      required this.close,
      @JsonKey(fromJson: stringToDecimal, toJson: decimalToString)
      required this.vol,
      @JsonKey(fromJson: stringToDecimalOrNull, toJson: decimalToStringOrNull)
      this.volCcy,
      @JsonKey(fromJson: stringToDecimalOrNull, toJson: decimalToStringOrNull)
      this.volCcyQuote,
      this.confirm = "1"});

  factory _$CandleModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CandleModelImplFromJson(json);

  /// 开始时间，Unix时间戳的毫秒数格式，如 1597026383085
  @override
  @JsonKey(fromJson: valueToInt, toJson: intToString)
  final int timestamp;
// @JsonKey(fromJson: valueToDateTime, toJson: dateTimeToInt)
// DateTime? datetime, // 从timestamp转换为dateTime;
  /// 开盘价格
  @override
  @JsonKey(fromJson: stringToDecimal, toJson: decimalToString)
  final Decimal open;

  /// 最高价格
  @override
  @JsonKey(fromJson: stringToDecimal, toJson: decimalToString)
  final Decimal high;

  ///最低价格
  @override
  @JsonKey(fromJson: stringToDecimal, toJson: decimalToString)
  final Decimal low;

  /// 收盘价格
  @override
  @JsonKey(fromJson: stringToDecimal, toJson: decimalToString)
  final Decimal close;

  /// 交易量，以张为单位: 如果是衍生品合约，数值为合约的张数。如果是币币/币币杠杆，数值为交易货币的数量。
  @override
  @JsonKey(fromJson: stringToDecimal, toJson: decimalToString)
  final Decimal vol;

  /// 交易量(成交额)，以币为单位: 如果是衍生品合约，数值为交易货币的数量。如果是币币/币币杠杆，数值为计价货币的数量。
  @override
  @JsonKey(fromJson: stringToDecimalOrNull, toJson: decimalToStringOrNull)
  final Decimal? volCcy;

  ///交易量(成交额)，以计价货币为单位: 如 BTC-USDT和BTC-USDT-SWAP，单位均是USDT。BTC-USD-SWAP单位是USD。
  @override
  @JsonKey(fromJson: stringToDecimalOrNull, toJson: decimalToStringOrNull)
  final Decimal? volCcyQuote;

  /// K线状态:  0：K线未完结  1：K线已完结
  @override
  @JsonKey()
  final String confirm;

  @override
  String toString() {
    return 'CandleModel(timestamp: $timestamp, open: $open, high: $high, low: $low, close: $close, vol: $vol, volCcy: $volCcy, volCcyQuote: $volCcyQuote, confirm: $confirm)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CandleModelImpl &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.open, open) || other.open == open) &&
            (identical(other.high, high) || other.high == high) &&
            (identical(other.low, low) || other.low == low) &&
            (identical(other.close, close) || other.close == close) &&
            (identical(other.vol, vol) || other.vol == vol) &&
            (identical(other.volCcy, volCcy) || other.volCcy == volCcy) &&
            (identical(other.volCcyQuote, volCcyQuote) ||
                other.volCcyQuote == volCcyQuote) &&
            (identical(other.confirm, confirm) || other.confirm == confirm));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, timestamp, open, high, low,
      close, vol, volCcy, volCcyQuote, confirm);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CandleModelImplCopyWith<_$CandleModelImpl> get copyWith =>
      __$$CandleModelImplCopyWithImpl<_$CandleModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CandleModelImplToJson(
      this,
    );
  }
}

abstract class _CandleModel implements CandleModel {
  factory _CandleModel(
      {@JsonKey(fromJson: valueToInt, toJson: intToString)
      required final int timestamp,
      @JsonKey(fromJson: stringToDecimal, toJson: decimalToString)
      required final Decimal open,
      @JsonKey(fromJson: stringToDecimal, toJson: decimalToString)
      required final Decimal high,
      @JsonKey(fromJson: stringToDecimal, toJson: decimalToString)
      required final Decimal low,
      @JsonKey(fromJson: stringToDecimal, toJson: decimalToString)
      required final Decimal close,
      @JsonKey(fromJson: stringToDecimal, toJson: decimalToString)
      required final Decimal vol,
      @JsonKey(fromJson: stringToDecimalOrNull, toJson: decimalToStringOrNull)
      final Decimal? volCcy,
      @JsonKey(fromJson: stringToDecimalOrNull, toJson: decimalToStringOrNull)
      final Decimal? volCcyQuote,
      final String confirm}) = _$CandleModelImpl;

  factory _CandleModel.fromJson(Map<String, dynamic> json) =
      _$CandleModelImpl.fromJson;

  @override

  /// 开始时间，Unix时间戳的毫秒数格式，如 1597026383085
  @JsonKey(fromJson: valueToInt, toJson: intToString)
  int get timestamp;
  @override // @JsonKey(fromJson: valueToDateTime, toJson: dateTimeToInt)
// DateTime? datetime, // 从timestamp转换为dateTime;
  /// 开盘价格
  @JsonKey(fromJson: stringToDecimal, toJson: decimalToString)
  Decimal get open;
  @override

  /// 最高价格
  @JsonKey(fromJson: stringToDecimal, toJson: decimalToString)
  Decimal get high;
  @override

  ///最低价格
  @JsonKey(fromJson: stringToDecimal, toJson: decimalToString)
  Decimal get low;
  @override

  /// 收盘价格
  @JsonKey(fromJson: stringToDecimal, toJson: decimalToString)
  Decimal get close;
  @override

  /// 交易量，以张为单位: 如果是衍生品合约，数值为合约的张数。如果是币币/币币杠杆，数值为交易货币的数量。
  @JsonKey(fromJson: stringToDecimal, toJson: decimalToString)
  Decimal get vol;
  @override

  /// 交易量(成交额)，以币为单位: 如果是衍生品合约，数值为交易货币的数量。如果是币币/币币杠杆，数值为计价货币的数量。
  @JsonKey(fromJson: stringToDecimalOrNull, toJson: decimalToStringOrNull)
  Decimal? get volCcy;
  @override

  ///交易量(成交额)，以计价货币为单位: 如 BTC-USDT和BTC-USDT-SWAP，单位均是USDT。BTC-USD-SWAP单位是USD。
  @JsonKey(fromJson: stringToDecimalOrNull, toJson: decimalToStringOrNull)
  Decimal? get volCcyQuote;
  @override

  /// K线状态:  0：K线未完结  1：K线已完结
  String get confirm;
  @override
  @JsonKey(ignore: true)
  _$$CandleModelImplCopyWith<_$CandleModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
