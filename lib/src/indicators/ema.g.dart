// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ema.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EMAParam _$EMAParamFromJson(Map<String, dynamic> json) => EMAParam(
      label: json['label'] as String,
      count: (json['count'] as num).toInt(),
      color: const ColorConverter().fromJson(json['color'] as String?),
    );

Map<String, dynamic> _$EMAParamToJson(EMAParam instance) => <String, dynamic>{
      'label': instance.label,
      'count': instance.count,
      'color': const ColorConverter().toJson(instance.color),
    };

EMAIndicator _$EMAIndicatorFromJson(Map<String, dynamic> json) => EMAIndicator(
      key: json['key'] == null
          ? emaKey
          : const ValueKeyConverter().fromJson(json['key'] as String),
      name: json['name'] as String? ?? 'EMA',
      height: (json['height'] as num).toDouble(),
      tipsHeight: (json['tipsHeight'] as num?)?.toDouble() ??
          defaultIndicatorTipsHeight,
      padding: json['padding'] == null
          ? EdgeInsets.zero
          : const EdgeInsetsConverter()
              .fromJson(json['padding'] as Map<String, dynamic>),
      calcParams: (json['calcParams'] as List<dynamic>?)
              ?.map((e) => EMAParam.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [
            EMAParam(label: 'EMA5', count: 5, color: Color(0xFF806180)),
            EMAParam(label: 'EMA10', count: 10, color: Color(0xFFEBB736)),
            EMAParam(label: 'EMA20', count: 20, color: Color(0xFFD672D5)),
            EMAParam(label: 'EMA60', count: 60, color: Color(0xFF788FD5))
          ],
    );

Map<String, dynamic> _$EMAIndicatorToJson(EMAIndicator instance) =>
    <String, dynamic>{
      'key': const ValueKeyConverter().toJson(instance.key),
      'name': instance.name,
      'height': instance.height,
      'tipsHeight': instance.tipsHeight,
      'padding': const EdgeInsetsConverter().toJson(instance.padding),
      'calcParams': instance.calcParams.map((e) => e.toJson()).toList(),
    };
