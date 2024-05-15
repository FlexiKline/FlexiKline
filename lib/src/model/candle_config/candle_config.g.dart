// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'candle_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CandleConfig _$CandleConfigFromJson(Map<String, dynamic> json) => CandleConfig(
      high: json['high'] == null
          ? const MarkConfig(
              spacing: 2,
              line: LineConfig(
                  type: LineType.solid,
                  color: Colors.black,
                  length: 20,
                  width: 0.5))
          : MarkConfig.fromJson(json['high'] as Map<String, dynamic>),
      low: json['low'] == null
          ? const MarkConfig(
              spacing: 2,
              line: LineConfig(
                  type: LineType.solid,
                  color: Colors.black,
                  length: 20,
                  width: 0.5))
          : MarkConfig.fromJson(json['low'] as Map<String, dynamic>),
      last: json['last'] == null
          ? const MarkConfig(
              show: true,
              spacing: 0,
              line: LineConfig(
                  type: LineType.dashed,
                  color: Colors.black,
                  width: 0.5,
                  dashes: [3, 3]),
              text: TextAreaConfig(
                  style: TextStyle(
                      fontSize: defaulTextSize,
                      color: Colors.white,
                      overflow: TextOverflow.ellipsis,
                      height: defaultTextHeight),
                  background: Colors.black38,
                  padding: defaultTextPading,
                  border: BorderSide(color: Colors.transparent),
                  borderRadius: BorderRadius.all(Radius.circular(5))))
          : MarkConfig.fromJson(json['last'] as Map<String, dynamic>),
      latest: json['latest'] == null
          ? const MarkConfig(
              show: true,
              spacing: 1,
              line: LineConfig(
                  type: LineType.dashed,
                  color: Colors.black,
                  width: 0.5,
                  dashes: [3, 3]),
              text: TextAreaConfig(
                  style: TextStyle(
                      fontSize: defaulTextSize,
                      color: Colors.black,
                      overflow: TextOverflow.ellipsis,
                      height: defaultTextHeight),
                  background: Colors.white,
                  padding: defaultTextPading,
                  border: BorderSide(color: Colors.black, width: 0.5),
                  borderRadius: BorderRadius.all(Radius.circular(2))))
          : MarkConfig.fromJson(json['latest'] as Map<String, dynamic>),
      showCountDown: json['showCountDown'] as bool? ?? true,
      countDown: json['countDown'] == null
          ? const TextAreaConfig(
              style: TextStyle(
                  fontSize: defaulTextSize,
                  color: Colors.black,
                  overflow: TextOverflow.ellipsis,
                  height: defaultTextHeight),
              background: Colors.white30,
              padding: defaultTextPading,
              border: BorderSide(color: Colors.black, width: 0.5),
              borderRadius: BorderRadius.all(Radius.circular(2)))
          : TextAreaConfig.fromJson(json['countDown'] as Map<String, dynamic>),
      timeTick: json['timeTick'] == null
          ? const TextAreaConfig(
              style: TextStyle(
                  fontSize: defaulTextSize,
                  color: Colors.black,
                  overflow: TextOverflow.ellipsis,
                  height: defaultTextHeight),
              textWidth: 80)
          : TextAreaConfig.fromJson(json['timeTick'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CandleConfigToJson(CandleConfig instance) =>
    <String, dynamic>{
      'high': instance.high.toJson(),
      'low': instance.low.toJson(),
      'last': instance.last.toJson(),
      'latest': instance.latest.toJson(),
      'showCountDown': instance.showCountDown,
      'countDown': instance.countDown.toJson(),
      'timeTick': instance.timeTick.toJson(),
    };
