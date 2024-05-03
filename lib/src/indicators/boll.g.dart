// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'boll.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BOLLParam _$BOLLParamFromJson(Map<String, dynamic> json) => BOLLParam(
      n: (json['n'] as num).toInt(),
      std: (json['std'] as num).toInt(),
    );

Map<String, dynamic> _$BOLLParamToJson(BOLLParam instance) => <String, dynamic>{
      'n': instance.n,
      'std': instance.std,
    };

BOLLIndicator _$BOLLIndicatorFromJson(Map<String, dynamic> json) =>
    BOLLIndicator(
      key: json['key'] == null
          ? const ValueKey(IndicatorType.boll)
          : const ValueKeyConverter().fromJson(json['key'] as String),
      name: json['name'] as String? ?? 'BOLL',
      height: (json['height'] as num).toDouble(),
      tipsHeight: (json['tipsHeight'] as num?)?.toDouble() ??
          defaultIndicatorTipsHeight,
      padding: json['padding'] == null
          ? EdgeInsets.zero
          : const EdgeInsetsConverter()
              .fromJson(json['padding'] as Map<String, double>),
      calcParam: json['calcParam'] == null
          ? const BOLLParam(n: 20, std: 2)
          : BOLLParam.fromJson(json['calcParam'] as Map<String, dynamic>),
      mbColor: json['mbColor'] == null
          ? const Color(0xFF886787)
          : const ColorConverter().fromJson(json['mbColor'] as String?),
      upColor: json['upColor'] == null
          ? const Color(0xFFF0B527)
          : const ColorConverter().fromJson(json['upColor'] as String?),
      dnColor: json['dnColor'] == null
          ? const Color(0xFFD85BE0)
          : const ColorConverter().fromJson(json['dnColor'] as String?),
      mbLabel: json['mbLabel'] as String? ?? 'BOLL(20):',
      upLabel: json['upLabel'] as String? ?? 'UB:',
      dnLabel: json['dnLabel'] as String? ?? 'LB:',
      precision: (json['precision'] as num?)?.toInt(),
      isFillBetweenUpAndDn: json['isFillBetweenUpAndDn'] as bool? ?? true,
      fillColor: const ColorConverter().fromJson(json['fillColor'] as String?),
    );

Map<String, dynamic> _$BOLLIndicatorToJson(BOLLIndicator instance) =>
    <String, dynamic>{
      'key': const ValueKeyConverter().toJson(instance.key),
      'name': instance.name,
      'height': instance.height,
      'tipsHeight': instance.tipsHeight,
      'padding': const EdgeInsetsConverter().toJson(instance.padding),
      'calcParam': instance.calcParam.toJson(),
      'mbColor': const ColorConverter().toJson(instance.mbColor),
      'upColor': const ColorConverter().toJson(instance.upColor),
      'dnColor': const ColorConverter().toJson(instance.dnColor),
      'mbLabel': instance.mbLabel,
      'upLabel': instance.upLabel,
      'dnLabel': instance.dnLabel,
      'precision': instance.precision,
      'isFillBetweenUpAndDn': instance.isFillBetweenUpAndDn,
      'fillColor': const ColorConverter().toJson(instance.fillColor),
    };
