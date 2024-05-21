// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ma_param.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MaParam _$MaParamFromJson(Map<String, dynamic> json) => MaParam(
      count: (json['count'] as num).toInt(),
      tips: TipsConfig.fromJson(json['tips'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MaParamToJson(MaParam instance) => <String, dynamic>{
      'count': instance.count,
      'tips': instance.tips.toJson(),
    };
