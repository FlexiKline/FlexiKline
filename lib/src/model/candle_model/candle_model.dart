import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kline/src/extension/export.dart';

part 'candle_model.freezed.dart';
part 'candle_model.g.dart';

@freezed
class CandleModel with _$CandleModel {
  factory CandleModel({
    @JsonKey(fromJson: valueToDecimal, toJson: valueToString)
    required Decimal open,
    @JsonKey(fromJson: valueToDecimal, toJson: valueToString)
    required Decimal close,
    @JsonKey(fromJson: valueToDecimal, toJson: valueToString)
    required Decimal high,
    @JsonKey(fromJson: valueToDecimal, toJson: valueToString)
    required Decimal low,
    @JsonKey(fromJson: valueToDecimal, toJson: valueToString)
    required Decimal volume,
    @JsonKey(fromJson: valueToDateTime, toJson: dateTimeToString)
    required DateTime date,
  }) = _CandleModel;

  factory CandleModel.fromJson(Map<String, dynamic> json) =>
      _$CandleModelFromJson(json);
}
