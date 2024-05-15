// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ema.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EMAIndicator _$EMAIndicatorFromJson(Map<String, dynamic> json) => EMAIndicator(
      key: json['key'] == null
          ? emaKey
          : const ValueKeyConverter().fromJson(json['key'] as String),
      name: json['name'] as String? ?? 'EMA',
      height: (json['height'] as num).toDouble(),
      tipsHeight: (json['tipsHeight'] as num?)?.toDouble() ??
          defaultIndicatorTipsHeight,
      padding: json['padding'] == null
          ? defaultIndicatorPadding
          : const EdgeInsetsConverter()
              .fromJson(json['padding'] as Map<String, dynamic>),
      calcParams: (json['calcParams'] as List<dynamic>?)
              ?.map((e) => MaParam.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [
            MaParam(
                count: 5,
                tips: TipsConfig(
                    label: 'EMA5: ',
                    style: TextStyle(
                        fontSize: defaulTextSize,
                        color: Color(0xFF806180),
                        overflow: TextOverflow.ellipsis,
                        height: defaultTipsTextHeight))),
            MaParam(
                count: 10,
                tips: TipsConfig(
                    label: 'EMA10: ',
                    style: TextStyle(
                        fontSize: defaulTextSize,
                        color: Color(0xFFEBB736),
                        overflow: TextOverflow.ellipsis,
                        height: defaultTipsTextHeight))),
            MaParam(
                count: 20,
                tips: TipsConfig(
                    label: 'EMA20: ',
                    style: TextStyle(
                        fontSize: defaulTextSize,
                        color: Color(0xFFD672D5),
                        overflow: TextOverflow.ellipsis,
                        height: defaultTipsTextHeight))),
            MaParam(
                count: 60,
                tips: TipsConfig(
                    label: 'EMA60: ',
                    style: TextStyle(
                        fontSize: defaulTextSize,
                        color: Color(0xFF788FD5),
                        overflow: TextOverflow.ellipsis,
                        height: defaultTipsTextHeight)))
          ],
      tipsPadding: json['tipsPadding'] == null
          ? defaultTipsPadding
          : const EdgeInsetsConverter()
              .fromJson(json['tipsPadding'] as Map<String, dynamic>),
      lineWidth:
          (json['lineWidth'] as num?)?.toDouble() ?? defaultIndicatorLineWidth,
    );

Map<String, dynamic> _$EMAIndicatorToJson(EMAIndicator instance) =>
    <String, dynamic>{
      'key': const ValueKeyConverter().toJson(instance.key),
      'name': instance.name,
      'height': instance.height,
      'tipsHeight': instance.tipsHeight,
      'padding': const EdgeInsetsConverter().toJson(instance.padding),
      'calcParams': instance.calcParams.map((e) => e.toJson()).toList(),
      'tipsPadding': const EdgeInsetsConverter().toJson(instance.tipsPadding),
      'lineWidth': instance.lineWidth,
    };
