// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'candle_req.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CandleReqImpl _$$CandleReqImplFromJson(Map<String, dynamic> json) =>
    _$CandleReqImpl(
      instId: json['instId'] as String,
      after: json['after'] as int?,
      before: json['before'] as int?,
      bar: json['bar'] as String? ?? "1m",
      limit: json['limit'] as int? ?? 100,
    );

Map<String, dynamic> _$$CandleReqImplToJson(_$CandleReqImpl instance) =>
    <String, dynamic>{
      'instId': instance.instId,
      'after': instance.after,
      'before': instance.before,
      'bar': instance.bar,
      'limit': instance.limit,
    };
