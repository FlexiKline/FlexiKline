import 'package:example/src/utils/model_util.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'instrument.freezed.dart';
part 'instrument.g.dart';

/// 获取交易产品基础信息
/// https://www.okx.com/docs-v5/zh/#public-data-rest-api-get-instruments
/// /api/v5/public/instruments
/// 限速：20次/2s
@freezed
class Instrument with _$Instrument {
  factory Instrument({
    String? alias,
    required String baseCcy, // 交易货币币种
    required String ctMult,
    required String ctType,
    required String ctVal,
    required String ctValCcy,
    required String expTime,
    required String instFamily,
    required String instId, // 产品id
    required String instType,
    required String lever,
    required String listTime,
    required String lotSz, // 下单数量精度
    required String maxIcebergSz,
    required String maxLmtAmt,
    required String maxLmtSz,
    required String maxMktAmt,
    required String maxMktSz,
    required String maxStopSz,
    required String maxTriggerSz,
    required String maxTwapSz,
    required String minSz,
    required String optType,
    required String quoteCcy, // 计价货币币种
    required String settleCcy,
    required String state,
    required String stk,
    required String tickSz, // 下单价格精度
    required String uly,
  }) = _Instrument;

  factory Instrument.fromJson(Map<String, dynamic> json) =>
      _$InstrumentFromJson(json);
}

extension InstrumentExt on Instrument {
  String get baseCcyIcon {
    return currencyIconUrl(baseCcy);
  }

  String get tradingSymbol {
    return '$baseCcy$quoteCcy';
  }

  int get precision => calcPrecision(tickSz);
}
