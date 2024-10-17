// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stock_ticker.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

StockTicker _$StockTickerFromJson(Map<String, dynamic> json) {
  return _StockTicker.fromJson(json);
}

/// @nodoc
mixin _$StockTicker {
  String get ticker => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get market => throw _privateConstructorUsedError;
  String get locale => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  bool get active => throw _privateConstructorUsedError;
  String? get cik => throw _privateConstructorUsedError;
  @JsonKey(name: 'primary_exchange')
  String get primaryExchange => throw _privateConstructorUsedError;
  @JsonKey(name: 'currency_name')
  String get currencyName => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_updated_utc')
  DateTime get lastUpdatedUtc => throw _privateConstructorUsedError;
  @JsonKey(name: 'composite_figi')
  String? get compositeFigi => throw _privateConstructorUsedError;
  @JsonKey(name: 'share_class_figistring')
  String? get shareClassFigistring => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $StockTickerCopyWith<StockTicker> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StockTickerCopyWith<$Res> {
  factory $StockTickerCopyWith(
          StockTicker value, $Res Function(StockTicker) then) =
      _$StockTickerCopyWithImpl<$Res, StockTicker>;
  @useResult
  $Res call(
      {String ticker,
      String name,
      String market,
      String locale,
      String type,
      bool active,
      String? cik,
      @JsonKey(name: 'primary_exchange') String primaryExchange,
      @JsonKey(name: 'currency_name') String currencyName,
      @JsonKey(name: 'last_updated_utc') DateTime lastUpdatedUtc,
      @JsonKey(name: 'composite_figi') String? compositeFigi,
      @JsonKey(name: 'share_class_figistring') String? shareClassFigistring});
}

/// @nodoc
class _$StockTickerCopyWithImpl<$Res, $Val extends StockTicker>
    implements $StockTickerCopyWith<$Res> {
  _$StockTickerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ticker = null,
    Object? name = null,
    Object? market = null,
    Object? locale = null,
    Object? type = null,
    Object? active = null,
    Object? cik = freezed,
    Object? primaryExchange = null,
    Object? currencyName = null,
    Object? lastUpdatedUtc = null,
    Object? compositeFigi = freezed,
    Object? shareClassFigistring = freezed,
  }) {
    return _then(_value.copyWith(
      ticker: null == ticker
          ? _value.ticker
          : ticker // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      market: null == market
          ? _value.market
          : market // ignore: cast_nullable_to_non_nullable
              as String,
      locale: null == locale
          ? _value.locale
          : locale // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      active: null == active
          ? _value.active
          : active // ignore: cast_nullable_to_non_nullable
              as bool,
      cik: freezed == cik
          ? _value.cik
          : cik // ignore: cast_nullable_to_non_nullable
              as String?,
      primaryExchange: null == primaryExchange
          ? _value.primaryExchange
          : primaryExchange // ignore: cast_nullable_to_non_nullable
              as String,
      currencyName: null == currencyName
          ? _value.currencyName
          : currencyName // ignore: cast_nullable_to_non_nullable
              as String,
      lastUpdatedUtc: null == lastUpdatedUtc
          ? _value.lastUpdatedUtc
          : lastUpdatedUtc // ignore: cast_nullable_to_non_nullable
              as DateTime,
      compositeFigi: freezed == compositeFigi
          ? _value.compositeFigi
          : compositeFigi // ignore: cast_nullable_to_non_nullable
              as String?,
      shareClassFigistring: freezed == shareClassFigistring
          ? _value.shareClassFigistring
          : shareClassFigistring // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StockTickerImplCopyWith<$Res>
    implements $StockTickerCopyWith<$Res> {
  factory _$$StockTickerImplCopyWith(
          _$StockTickerImpl value, $Res Function(_$StockTickerImpl) then) =
      __$$StockTickerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String ticker,
      String name,
      String market,
      String locale,
      String type,
      bool active,
      String? cik,
      @JsonKey(name: 'primary_exchange') String primaryExchange,
      @JsonKey(name: 'currency_name') String currencyName,
      @JsonKey(name: 'last_updated_utc') DateTime lastUpdatedUtc,
      @JsonKey(name: 'composite_figi') String? compositeFigi,
      @JsonKey(name: 'share_class_figistring') String? shareClassFigistring});
}

/// @nodoc
class __$$StockTickerImplCopyWithImpl<$Res>
    extends _$StockTickerCopyWithImpl<$Res, _$StockTickerImpl>
    implements _$$StockTickerImplCopyWith<$Res> {
  __$$StockTickerImplCopyWithImpl(
      _$StockTickerImpl _value, $Res Function(_$StockTickerImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ticker = null,
    Object? name = null,
    Object? market = null,
    Object? locale = null,
    Object? type = null,
    Object? active = null,
    Object? cik = freezed,
    Object? primaryExchange = null,
    Object? currencyName = null,
    Object? lastUpdatedUtc = null,
    Object? compositeFigi = freezed,
    Object? shareClassFigistring = freezed,
  }) {
    return _then(_$StockTickerImpl(
      ticker: null == ticker
          ? _value.ticker
          : ticker // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      market: null == market
          ? _value.market
          : market // ignore: cast_nullable_to_non_nullable
              as String,
      locale: null == locale
          ? _value.locale
          : locale // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      active: null == active
          ? _value.active
          : active // ignore: cast_nullable_to_non_nullable
              as bool,
      cik: freezed == cik
          ? _value.cik
          : cik // ignore: cast_nullable_to_non_nullable
              as String?,
      primaryExchange: null == primaryExchange
          ? _value.primaryExchange
          : primaryExchange // ignore: cast_nullable_to_non_nullable
              as String,
      currencyName: null == currencyName
          ? _value.currencyName
          : currencyName // ignore: cast_nullable_to_non_nullable
              as String,
      lastUpdatedUtc: null == lastUpdatedUtc
          ? _value.lastUpdatedUtc
          : lastUpdatedUtc // ignore: cast_nullable_to_non_nullable
              as DateTime,
      compositeFigi: freezed == compositeFigi
          ? _value.compositeFigi
          : compositeFigi // ignore: cast_nullable_to_non_nullable
              as String?,
      shareClassFigistring: freezed == shareClassFigistring
          ? _value.shareClassFigistring
          : shareClassFigistring // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StockTickerImpl implements _StockTicker {
  _$StockTickerImpl(
      {required this.ticker,
      required this.name,
      required this.market,
      required this.locale,
      required this.type,
      required this.active,
      this.cik,
      @JsonKey(name: 'primary_exchange') required this.primaryExchange,
      @JsonKey(name: 'currency_name') required this.currencyName,
      @JsonKey(name: 'last_updated_utc') required this.lastUpdatedUtc,
      @JsonKey(name: 'composite_figi') this.compositeFigi,
      @JsonKey(name: 'share_class_figistring') this.shareClassFigistring});

  factory _$StockTickerImpl.fromJson(Map<String, dynamic> json) =>
      _$$StockTickerImplFromJson(json);

  @override
  final String ticker;
  @override
  final String name;
  @override
  final String market;
  @override
  final String locale;
  @override
  final String type;
  @override
  final bool active;
  @override
  final String? cik;
  @override
  @JsonKey(name: 'primary_exchange')
  final String primaryExchange;
  @override
  @JsonKey(name: 'currency_name')
  final String currencyName;
  @override
  @JsonKey(name: 'last_updated_utc')
  final DateTime lastUpdatedUtc;
  @override
  @JsonKey(name: 'composite_figi')
  final String? compositeFigi;
  @override
  @JsonKey(name: 'share_class_figistring')
  final String? shareClassFigistring;

  @override
  String toString() {
    return 'StockTicker(ticker: $ticker, name: $name, market: $market, locale: $locale, type: $type, active: $active, cik: $cik, primaryExchange: $primaryExchange, currencyName: $currencyName, lastUpdatedUtc: $lastUpdatedUtc, compositeFigi: $compositeFigi, shareClassFigistring: $shareClassFigistring)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StockTickerImpl &&
            (identical(other.ticker, ticker) || other.ticker == ticker) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.market, market) || other.market == market) &&
            (identical(other.locale, locale) || other.locale == locale) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.active, active) || other.active == active) &&
            (identical(other.cik, cik) || other.cik == cik) &&
            (identical(other.primaryExchange, primaryExchange) ||
                other.primaryExchange == primaryExchange) &&
            (identical(other.currencyName, currencyName) ||
                other.currencyName == currencyName) &&
            (identical(other.lastUpdatedUtc, lastUpdatedUtc) ||
                other.lastUpdatedUtc == lastUpdatedUtc) &&
            (identical(other.compositeFigi, compositeFigi) ||
                other.compositeFigi == compositeFigi) &&
            (identical(other.shareClassFigistring, shareClassFigistring) ||
                other.shareClassFigistring == shareClassFigistring));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      ticker,
      name,
      market,
      locale,
      type,
      active,
      cik,
      primaryExchange,
      currencyName,
      lastUpdatedUtc,
      compositeFigi,
      shareClassFigistring);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StockTickerImplCopyWith<_$StockTickerImpl> get copyWith =>
      __$$StockTickerImplCopyWithImpl<_$StockTickerImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StockTickerImplToJson(
      this,
    );
  }
}

abstract class _StockTicker implements StockTicker {
  factory _StockTicker(
      {required final String ticker,
      required final String name,
      required final String market,
      required final String locale,
      required final String type,
      required final bool active,
      final String? cik,
      @JsonKey(name: 'primary_exchange') required final String primaryExchange,
      @JsonKey(name: 'currency_name') required final String currencyName,
      @JsonKey(name: 'last_updated_utc') required final DateTime lastUpdatedUtc,
      @JsonKey(name: 'composite_figi') final String? compositeFigi,
      @JsonKey(name: 'share_class_figistring')
      final String? shareClassFigistring}) = _$StockTickerImpl;

  factory _StockTicker.fromJson(Map<String, dynamic> json) =
      _$StockTickerImpl.fromJson;

  @override
  String get ticker;
  @override
  String get name;
  @override
  String get market;
  @override
  String get locale;
  @override
  String get type;
  @override
  bool get active;
  @override
  String? get cik;
  @override
  @JsonKey(name: 'primary_exchange')
  String get primaryExchange;
  @override
  @JsonKey(name: 'currency_name')
  String get currencyName;
  @override
  @JsonKey(name: 'last_updated_utc')
  DateTime get lastUpdatedUtc;
  @override
  @JsonKey(name: 'composite_figi')
  String? get compositeFigi;
  @override
  @JsonKey(name: 'share_class_figistring')
  String? get shareClassFigistring;
  @override
  @JsonKey(ignore: true)
  _$$StockTickerImplCopyWith<_$StockTickerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
