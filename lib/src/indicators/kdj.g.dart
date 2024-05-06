// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kdj.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KDJParam _$KDJParamFromJson(Map<String, dynamic> json) => KDJParam(
      n: (json['n'] as num).toInt(),
      m1: (json['m1'] as num).toInt(),
      m2: (json['m2'] as num).toInt(),
    );

Map<String, dynamic> _$KDJParamToJson(KDJParam instance) => <String, dynamic>{
      'n': instance.n,
      'm1': instance.m1,
      'm2': instance.m2,
    };

KDJIndicator _$KDJIndicatorFromJson(Map<String, dynamic> json) => KDJIndicator(
      key: json['key'] == null
          ? const ValueKey(IndicatorType.kdj)
          : const ValueKeyConverter().fromJson(json['key'] as String),
      name: json['name'] as String? ?? 'KDJ',
      height: (json['height'] as num).toDouble(),
      tipsHeight: (json['tipsHeight'] as num?)?.toDouble() ??
          defaultIndicatorTipsHeight,
      padding: json['padding'] == null
          ? defaultIndicatorPadding
          : const EdgeInsetsConverter()
              .fromJson(json['padding'] as Map<String, dynamic>),
      calcParam: json['calcParam'] == null
          ? const KDJParam(n: 9, m1: 3, m2: 3)
          : KDJParam.fromJson(json['calcParam'] as Map<String, dynamic>),
      kColor: json['kColor'] == null
          ? const Color(0xFF7A5C79)
          : const ColorConverter().fromJson(json['kColor'] as String?),
      dColor: json['dColor'] == null
          ? const Color(0xFFFABD3F)
          : const ColorConverter().fromJson(json['dColor'] as String?),
      jColor: json['jColor'] == null
          ? const Color(0xFFBB72CA)
          : const ColorConverter().fromJson(json['jColor'] as String?),
      tickCount: (json['tickCount'] as num?)?.toInt(),
      precision: (json['precision'] as num?)?.toInt() ?? 2,
    );

Map<String, dynamic> _$KDJIndicatorToJson(KDJIndicator instance) =>
    <String, dynamic>{
      'key': const ValueKeyConverter().toJson(instance.key),
      'name': instance.name,
      'height': instance.height,
      'tipsHeight': instance.tipsHeight,
      'padding': const EdgeInsetsConverter().toJson(instance.padding),
      'calcParam': instance.calcParam.toJson(),
      'kColor': const ColorConverter().toJson(instance.kColor),
      'dColor': const ColorConverter().toJson(instance.dColor),
      'jColor': const ColorConverter().toJson(instance.jColor),
      'tickCount': instance.tickCount,
      'precision': instance.precision,
    };
