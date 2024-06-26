// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'candle_req.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CandleReqCWProxy {
  CandleReq instId(String instId);

  CandleReq bar(String bar);

  CandleReq limit(int limit);

  CandleReq precision(int precision);

  CandleReq after(int? after);

  CandleReq before(int? before);

  CandleReq state(RequestState state);

  CandleReq displayName(String? displayName);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CandleReq(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CandleReq(...).copyWith(id: 12, name: "My name")
  /// ````
  CandleReq call({
    String? instId,
    String? bar,
    int? limit,
    int? precision,
    int? after,
    int? before,
    RequestState? state,
    String? displayName,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCandleReq.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCandleReq.copyWith.fieldName(...)`
class _$CandleReqCWProxyImpl implements _$CandleReqCWProxy {
  const _$CandleReqCWProxyImpl(this._value);

  final CandleReq _value;

  @override
  CandleReq instId(String instId) => this(instId: instId);

  @override
  CandleReq bar(String bar) => this(bar: bar);

  @override
  CandleReq limit(int limit) => this(limit: limit);

  @override
  CandleReq precision(int precision) => this(precision: precision);

  @override
  CandleReq after(int? after) => this(after: after);

  @override
  CandleReq before(int? before) => this(before: before);

  @override
  CandleReq state(RequestState state) => this(state: state);

  @override
  CandleReq displayName(String? displayName) => this(displayName: displayName);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CandleReq(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CandleReq(...).copyWith(id: 12, name: "My name")
  /// ````
  CandleReq call({
    Object? instId = const $CopyWithPlaceholder(),
    Object? bar = const $CopyWithPlaceholder(),
    Object? limit = const $CopyWithPlaceholder(),
    Object? precision = const $CopyWithPlaceholder(),
    Object? after = const $CopyWithPlaceholder(),
    Object? before = const $CopyWithPlaceholder(),
    Object? state = const $CopyWithPlaceholder(),
    Object? displayName = const $CopyWithPlaceholder(),
  }) {
    return CandleReq(
      instId: instId == const $CopyWithPlaceholder() || instId == null
          ? _value.instId
          // ignore: cast_nullable_to_non_nullable
          : instId as String,
      bar: bar == const $CopyWithPlaceholder() || bar == null
          ? _value.bar
          // ignore: cast_nullable_to_non_nullable
          : bar as String,
      limit: limit == const $CopyWithPlaceholder() || limit == null
          ? _value.limit
          // ignore: cast_nullable_to_non_nullable
          : limit as int,
      precision: precision == const $CopyWithPlaceholder() || precision == null
          ? _value.precision
          // ignore: cast_nullable_to_non_nullable
          : precision as int,
      after: after == const $CopyWithPlaceholder()
          ? _value.after
          // ignore: cast_nullable_to_non_nullable
          : after as int?,
      before: before == const $CopyWithPlaceholder()
          ? _value.before
          // ignore: cast_nullable_to_non_nullable
          : before as int?,
      state: state == const $CopyWithPlaceholder() || state == null
          ? _value.state
          // ignore: cast_nullable_to_non_nullable
          : state as RequestState,
      displayName: displayName == const $CopyWithPlaceholder()
          ? _value.displayName
          // ignore: cast_nullable_to_non_nullable
          : displayName as String?,
    );
  }
}

extension $CandleReqCopyWith on CandleReq {
  /// Returns a callable class that can be used as follows: `instanceOfCandleReq.copyWith(...)` or like so:`instanceOfCandleReq.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CandleReqCWProxy get copyWith => _$CandleReqCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CandleReq _$CandleReqFromJson(Map<String, dynamic> json) => CandleReq(
      instId: json['instId'] as String,
      bar: json['bar'] as String? ?? '1m',
      limit: (json['limit'] as num?)?.toInt() ?? 100,
      after: (json['after'] as num?)?.toInt(),
      before: (json['before'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CandleReqToJson(CandleReq instance) {
  final val = <String, dynamic>{
    'instId': instance.instId,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('after', instance.after);
  writeNotNull('before', instance.before);
  val['bar'] = instance.bar;
  val['limit'] = instance.limit;
  return val;
}
