// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'instrument.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$InstrumentImpl _$$InstrumentImplFromJson(Map<String, dynamic> json) =>
    _$InstrumentImpl(
      alias: json['alias'] as String?,
      baseCcy: json['baseCcy'] as String,
      ctMult: json['ctMult'] as String,
      ctType: json['ctType'] as String,
      ctVal: json['ctVal'] as String,
      ctValCcy: json['ctValCcy'] as String,
      expTime: json['expTime'] as String,
      instFamily: json['instFamily'] as String,
      instId: json['instId'] as String,
      instType: json['instType'] as String,
      lever: json['lever'] as String,
      listTime: json['listTime'] as String,
      lotSz: json['lotSz'] as String,
      maxIcebergSz: json['maxIcebergSz'] as String,
      maxLmtAmt: json['maxLmtAmt'] as String,
      maxLmtSz: json['maxLmtSz'] as String,
      maxMktAmt: json['maxMktAmt'] as String,
      maxMktSz: json['maxMktSz'] as String,
      maxStopSz: json['maxStopSz'] as String,
      maxTriggerSz: json['maxTriggerSz'] as String,
      maxTwapSz: json['maxTwapSz'] as String,
      minSz: json['minSz'] as String,
      optType: json['optType'] as String,
      quoteCcy: json['quoteCcy'] as String,
      settleCcy: json['settleCcy'] as String,
      state: json['state'] as String,
      stk: json['stk'] as String,
      tickSz: json['tickSz'] as String,
      uly: json['uly'] as String,
    );

Map<String, dynamic> _$$InstrumentImplToJson(_$InstrumentImpl instance) =>
    <String, dynamic>{
      'alias': instance.alias,
      'baseCcy': instance.baseCcy,
      'ctMult': instance.ctMult,
      'ctType': instance.ctType,
      'ctVal': instance.ctVal,
      'ctValCcy': instance.ctValCcy,
      'expTime': instance.expTime,
      'instFamily': instance.instFamily,
      'instId': instance.instId,
      'instType': instance.instType,
      'lever': instance.lever,
      'listTime': instance.listTime,
      'lotSz': instance.lotSz,
      'maxIcebergSz': instance.maxIcebergSz,
      'maxLmtAmt': instance.maxLmtAmt,
      'maxLmtSz': instance.maxLmtSz,
      'maxMktAmt': instance.maxMktAmt,
      'maxMktSz': instance.maxMktSz,
      'maxStopSz': instance.maxStopSz,
      'maxTriggerSz': instance.maxTriggerSz,
      'maxTwapSz': instance.maxTwapSz,
      'minSz': instance.minSz,
      'optType': instance.optType,
      'quoteCcy': instance.quoteCcy,
      'settleCcy': instance.settleCcy,
      'state': instance.state,
      'stk': instance.stk,
      'tickSz': instance.tickSz,
      'uly': instance.uly,
    };
