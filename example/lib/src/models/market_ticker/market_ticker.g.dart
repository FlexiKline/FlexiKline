// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'market_ticker.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MarketTickerImpl _$$MarketTickerImplFromJson(Map<String, dynamic> json) =>
    _$MarketTickerImpl(
      instType: json['instType'] as String,
      instId: json['instId'] as String,
      last: json['last'] as String,
      lastSz: json['lastSz'] as String,
      askPx: json['askPx'] as String,
      askSz: json['askSz'] as String,
      bidPx: json['bidPx'] as String,
      bidSz: json['bidSz'] as String,
      open24h: json['open24h'] as String,
      high24h: json['high24h'] as String,
      low24h: json['low24h'] as String,
      volCcy24h: json['volCcy24h'] as String,
      vol24h: json['vol24h'] as String,
      ts: json['ts'] as String,
      sodUtc0: json['sodUtc0'] as String,
      sodUtc8: json['sodUtc8'] as String,
    );

Map<String, dynamic> _$$MarketTickerImplToJson(_$MarketTickerImpl instance) =>
    <String, dynamic>{
      'instType': instance.instType,
      'instId': instance.instId,
      'last': instance.last,
      'lastSz': instance.lastSz,
      'askPx': instance.askPx,
      'askSz': instance.askSz,
      'bidPx': instance.bidPx,
      'bidSz': instance.bidSz,
      'open24h': instance.open24h,
      'high24h': instance.high24h,
      'low24h': instance.low24h,
      'volCcy24h': instance.volCcy24h,
      'vol24h': instance.vol24h,
      'ts': instance.ts,
      'sodUtc0': instance.sodUtc0,
      'sodUtc8': instance.sodUtc8,
    };
