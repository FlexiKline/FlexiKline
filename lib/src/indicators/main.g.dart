// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MainChartIndicator _$MainChartIndicatorFromJson(Map<String, dynamic> json) =>
    MainChartIndicator(
      key: json['key'] == null
          ? mainChartKey
          : const ValueKeyConverter().fromJson(json['key'] as String),
      name: json['name'] as String? ?? 'Main',
      height: (json['height'] as num).toDouble(),
      padding: json['padding'] == null
          ? defaultMainIndicatorPadding
          : const EdgeInsetsConverter()
              .fromJson(json['padding'] as Map<String, dynamic>),
    )..drawBelowTipsArea = json['drawBelowTipsArea'] as bool;

Map<String, dynamic> _$MainChartIndicatorToJson(MainChartIndicator instance) =>
    <String, dynamic>{
      'key': const ValueKeyConverter().toJson(instance.key),
      'name': instance.name,
      'height': instance.height,
      'padding': const EdgeInsetsConverter().toJson(instance.padding),
      'drawBelowTipsArea': instance.drawBelowTipsArea,
    };
