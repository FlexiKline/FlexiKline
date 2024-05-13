// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'candle_req.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CandleReq _$CandleReqFromJson(Map<String, dynamic> json) => CandleReq(
      instId: json['instId'] as String,
      bar: json['bar'] as String? ?? '1m',
      limit: (json['limit'] as num?)?.toInt() ?? 100,
      precision: (json['precision'] as num?)?.toInt() ?? defaultPrecision,
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
  val['precision'] = instance.precision;
  return val;
}
