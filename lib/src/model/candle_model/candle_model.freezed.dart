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
  @JsonKey(fromJson: valueToDecimal, toJson: valueToString)
  Decimal get open => throw _privateConstructorUsedError;
  @JsonKey(fromJson: valueToDecimal, toJson: valueToString)
  Decimal get close => throw _privateConstructorUsedError;
  @JsonKey(fromJson: valueToDecimal, toJson: valueToString)
  Decimal get high => throw _privateConstructorUsedError;
  @JsonKey(fromJson: valueToDecimal, toJson: valueToString)
  Decimal get low => throw _privateConstructorUsedError;
  @JsonKey(fromJson: valueToDecimal, toJson: valueToString)
  Decimal get volume => throw _privateConstructorUsedError;
  @JsonKey(fromJson: valueToDateTime, toJson: dateTimeToInt)
  DateTime get date => throw _privateConstructorUsedError;

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
      {@JsonKey(fromJson: valueToDecimal, toJson: valueToString) Decimal open,
      @JsonKey(fromJson: valueToDecimal, toJson: valueToString) Decimal close,
      @JsonKey(fromJson: valueToDecimal, toJson: valueToString) Decimal high,
      @JsonKey(fromJson: valueToDecimal, toJson: valueToString) Decimal low,
      @JsonKey(fromJson: valueToDecimal, toJson: valueToString) Decimal volume,
      @JsonKey(fromJson: valueToDateTime, toJson: dateTimeToInt)
      DateTime date});
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
    Object? open = null,
    Object? close = null,
    Object? high = null,
    Object? low = null,
    Object? volume = null,
    Object? date = null,
  }) {
    return _then(_value.copyWith(
      open: null == open
          ? _value.open
          : open // ignore: cast_nullable_to_non_nullable
              as Decimal,
      close: null == close
          ? _value.close
          : close // ignore: cast_nullable_to_non_nullable
              as Decimal,
      high: null == high
          ? _value.high
          : high // ignore: cast_nullable_to_non_nullable
              as Decimal,
      low: null == low
          ? _value.low
          : low // ignore: cast_nullable_to_non_nullable
              as Decimal,
      volume: null == volume
          ? _value.volume
          : volume // ignore: cast_nullable_to_non_nullable
              as Decimal,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
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
      {@JsonKey(fromJson: valueToDecimal, toJson: valueToString) Decimal open,
      @JsonKey(fromJson: valueToDecimal, toJson: valueToString) Decimal close,
      @JsonKey(fromJson: valueToDecimal, toJson: valueToString) Decimal high,
      @JsonKey(fromJson: valueToDecimal, toJson: valueToString) Decimal low,
      @JsonKey(fromJson: valueToDecimal, toJson: valueToString) Decimal volume,
      @JsonKey(fromJson: valueToDateTime, toJson: dateTimeToInt)
      DateTime date});
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
    Object? open = null,
    Object? close = null,
    Object? high = null,
    Object? low = null,
    Object? volume = null,
    Object? date = null,
  }) {
    return _then(_$CandleModelImpl(
      open: null == open
          ? _value.open
          : open // ignore: cast_nullable_to_non_nullable
              as Decimal,
      close: null == close
          ? _value.close
          : close // ignore: cast_nullable_to_non_nullable
              as Decimal,
      high: null == high
          ? _value.high
          : high // ignore: cast_nullable_to_non_nullable
              as Decimal,
      low: null == low
          ? _value.low
          : low // ignore: cast_nullable_to_non_nullable
              as Decimal,
      volume: null == volume
          ? _value.volume
          : volume // ignore: cast_nullable_to_non_nullable
              as Decimal,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CandleModelImpl implements _CandleModel {
  _$CandleModelImpl(
      {@JsonKey(fromJson: valueToDecimal, toJson: valueToString)
      required this.open,
      @JsonKey(fromJson: valueToDecimal, toJson: valueToString)
      required this.close,
      @JsonKey(fromJson: valueToDecimal, toJson: valueToString)
      required this.high,
      @JsonKey(fromJson: valueToDecimal, toJson: valueToString)
      required this.low,
      @JsonKey(fromJson: valueToDecimal, toJson: valueToString)
      required this.volume,
      @JsonKey(fromJson: valueToDateTime, toJson: dateTimeToInt)
      required this.date});

  factory _$CandleModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CandleModelImplFromJson(json);

  @override
  @JsonKey(fromJson: valueToDecimal, toJson: valueToString)
  final Decimal open;
  @override
  @JsonKey(fromJson: valueToDecimal, toJson: valueToString)
  final Decimal close;
  @override
  @JsonKey(fromJson: valueToDecimal, toJson: valueToString)
  final Decimal high;
  @override
  @JsonKey(fromJson: valueToDecimal, toJson: valueToString)
  final Decimal low;
  @override
  @JsonKey(fromJson: valueToDecimal, toJson: valueToString)
  final Decimal volume;
  @override
  @JsonKey(fromJson: valueToDateTime, toJson: dateTimeToInt)
  final DateTime date;

  @override
  String toString() {
    return 'CandleModel(open: $open, close: $close, high: $high, low: $low, volume: $volume, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CandleModelImpl &&
            (identical(other.open, open) || other.open == open) &&
            (identical(other.close, close) || other.close == close) &&
            (identical(other.high, high) || other.high == high) &&
            (identical(other.low, low) || other.low == low) &&
            (identical(other.volume, volume) || other.volume == volume) &&
            (identical(other.date, date) || other.date == date));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, open, close, high, low, volume, date);

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
      {@JsonKey(fromJson: valueToDecimal, toJson: valueToString)
      required final Decimal open,
      @JsonKey(fromJson: valueToDecimal, toJson: valueToString)
      required final Decimal close,
      @JsonKey(fromJson: valueToDecimal, toJson: valueToString)
      required final Decimal high,
      @JsonKey(fromJson: valueToDecimal, toJson: valueToString)
      required final Decimal low,
      @JsonKey(fromJson: valueToDecimal, toJson: valueToString)
      required final Decimal volume,
      @JsonKey(fromJson: valueToDateTime, toJson: dateTimeToInt)
      required final DateTime date}) = _$CandleModelImpl;

  factory _CandleModel.fromJson(Map<String, dynamic> json) =
      _$CandleModelImpl.fromJson;

  @override
  @JsonKey(fromJson: valueToDecimal, toJson: valueToString)
  Decimal get open;
  @override
  @JsonKey(fromJson: valueToDecimal, toJson: valueToString)
  Decimal get close;
  @override
  @JsonKey(fromJson: valueToDecimal, toJson: valueToString)
  Decimal get high;
  @override
  @JsonKey(fromJson: valueToDecimal, toJson: valueToString)
  Decimal get low;
  @override
  @JsonKey(fromJson: valueToDecimal, toJson: valueToString)
  Decimal get volume;
  @override
  @JsonKey(fromJson: valueToDateTime, toJson: dateTimeToInt)
  DateTime get date;
  @override
  @JsonKey(ignore: true)
  _$$CandleModelImplCopyWith<_$CandleModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
