// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'setting_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettingConfig _$SettingConfigFromJson(Map<String, dynamic> json) =>
    SettingConfig(
      textColor: json['textColor'] == null
          ? Colors.black
          : const ColorConverter().fromJson(json['textColor'] as String?),
      longColor: json['longColor'] == null
          ? const Color(0xFF33BD65)
          : const ColorConverter().fromJson(json['longColor'] as String?),
      shortColor: json['shortColor'] == null
          ? const Color(0xFFE84E74)
          : const ColorConverter().fromJson(json['shortColor'] as String?),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 0.5,
      loadingProgressSize:
          (json['loadingProgressSize'] as num?)?.toDouble() ?? 24,
      loadingProgressStrokeWidth:
          (json['loadingProgressStrokeWidth'] as num?)?.toDouble() ?? 4,
      loadingProgressBackgroundColor:
          json['loadingProgressBackgroundColor'] == null
              ? const Color(0xFFECECEC)
              : const ColorConverter()
                  .fromJson(json['loadingProgressBackgroundColor'] as String?),
      loadingProgressValueColor: json['loadingProgressValueColor'] == null
          ? Colors.black
          : const ColorConverter()
              .fromJson(json['loadingProgressValueColor'] as String?),
      mainRect: json['mainRect'] == null
          ? Rect.zero
          : const RectConverter()
              .fromJson(json['mainRect'] as Map<String, dynamic>),
      mainTipsHeight: (json['mainTipsHeight'] as num?)?.toDouble() ?? 12,
      mainPadding: json['mainPadding'] == null
          ? const EdgeInsets.only(bottom: 15)
          : const EdgeInsetsConverter()
              .fromJson(json['mainPadding'] as Map<String, dynamic>),
      minPaintBlankRate: (json['minPaintBlankRate'] as num?)?.toDouble() ?? 0.5,
      alwaysCalculateScreenOfCandlesIfEnough:
          json['alwaysCalculateScreenOfCandlesIfEnough'] as bool? ?? false,
      candleMaxWidth: (json['candleMaxWidth'] as num?)?.toDouble() ?? 40.0,
      candleWidth: (json['candleWidth'] as num?)?.toDouble() ?? 7.0,
      candleSpacing: (json['candleSpacing'] as num?)?.toDouble() ?? 1.0,
      candleLineWidth: (json['candleLineWidth'] as num?)?.toDouble() ?? 1.0,
      firstCandleInitOffset:
          (json['firstCandleInitOffset'] as num?)?.toDouble() ?? 80,
      indicatorLineWidth:
          (json['indicatorLineWidth'] as num?)?.toDouble() ?? 1.0,
      defaultTextStyle: json['defaultTextStyle'] == null
          ? const TextStyle(
              fontSize: 10,
              color: Colors.black,
              overflow: TextOverflow.ellipsis,
              height: 1)
          : const TextStyleConverter()
              .fromJson(json['defaultTextStyle'] as Map<String, dynamic>),
      defaultPadding: json['defaultPadding'] == null
          ? const EdgeInsets.all(2)
          : const EdgeInsetsConverter()
              .fromJson(json['defaultPadding'] as Map<String, dynamic>),
      defaultBackground: json['defaultBackground'] == null
          ? Colors.white
          : const ColorConverter()
              .fromJson(json['defaultBackground'] as String?),
      defaultRadius: json['defaultRadius'] == null
          ? const BorderRadius.all(Radius.circular(2))
          : const BorderRadiusConverter()
              .fromJson(json['defaultRadius'] as Map<String, dynamic>),
      defaultBorder: json['defaultBorder'] == null
          ? const BorderSide(color: Colors.black, width: 0.5)
          : const BorderSideConvert()
              .fromJson(json['defaultBorder'] as Map<String, dynamic>),
      longTextStyle: _$JsonConverterFromJson<Map<String, dynamic>, TextStyle>(
          json['longTextStyle'], const TextStyleConverter().fromJson),
      shortTextStyle: _$JsonConverterFromJson<Map<String, dynamic>, TextStyle>(
          json['shortTextStyle'], const TextStyleConverter().fromJson),
      tipsTextStyle: _$JsonConverterFromJson<Map<String, dynamic>, TextStyle>(
          json['tipsTextStyle'], const TextStyleConverter().fromJson),
      tipsPadding: json['tipsPadding'] == null
          ? const EdgeInsets.only(left: 8)
          : const EdgeInsetsConverter()
              .fromJson(json['tipsPadding'] as Map<String, dynamic>),
      tickRectMargin: (json['tickRectMargin'] as num?)?.toDouble() ?? 1,
      tickTextStyle: _$JsonConverterFromJson<Map<String, dynamic>, TextStyle>(
          json['tickTextStyle'], const TextStyleConverter().fromJson),
      tickPadding: json['tickPadding'] == null
          ? const EdgeInsets.all(2)
          : const EdgeInsetsConverter()
              .fromJson(json['tickPadding'] as Map<String, dynamic>),
      markLineWidth: (json['markLineWidth'] as num?)?.toDouble() ?? 0.5,
      markLineColor:
          const ColorConverter().fromJson(json['markLineColor'] as String?),
      subChartMaxCount: (json['subChartMaxCount'] as num?)?.toInt() ??
          defaultSubChartMaxCount,
    );

Map<String, dynamic> _$SettingConfigToJson(SettingConfig instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('textColor', const ColorConverter().toJson(instance.textColor));
  writeNotNull('longColor', const ColorConverter().toJson(instance.longColor));
  writeNotNull(
      'shortColor', const ColorConverter().toJson(instance.shortColor));
  val['opacity'] = instance.opacity;
  val['loadingProgressSize'] = instance.loadingProgressSize;
  val['loadingProgressStrokeWidth'] = instance.loadingProgressStrokeWidth;
  writeNotNull('loadingProgressBackgroundColor',
      const ColorConverter().toJson(instance.loadingProgressBackgroundColor));
  writeNotNull('loadingProgressValueColor',
      const ColorConverter().toJson(instance.loadingProgressValueColor));
  val['mainRect'] = const RectConverter().toJson(instance.mainRect);
  val['mainTipsHeight'] = instance.mainTipsHeight;
  val['mainPadding'] = const EdgeInsetsConverter().toJson(instance.mainPadding);
  val['minPaintBlankRate'] = instance.minPaintBlankRate;
  val['alwaysCalculateScreenOfCandlesIfEnough'] =
      instance.alwaysCalculateScreenOfCandlesIfEnough;
  val['candleMaxWidth'] = instance.candleMaxWidth;
  val['candleWidth'] = instance.candleWidth;
  val['candleSpacing'] = instance.candleSpacing;
  val['candleLineWidth'] = instance.candleLineWidth;
  val['firstCandleInitOffset'] = instance.firstCandleInitOffset;
  val['indicatorLineWidth'] = instance.indicatorLineWidth;
  val['defaultTextStyle'] =
      const TextStyleConverter().toJson(instance.defaultTextStyle);
  val['defaultPadding'] =
      const EdgeInsetsConverter().toJson(instance.defaultPadding);
  writeNotNull('defaultBackground',
      const ColorConverter().toJson(instance.defaultBackground));
  val['defaultBorder'] =
      const BorderSideConvert().toJson(instance.defaultBorder);
  val['defaultRadius'] =
      const BorderRadiusConverter().toJson(instance.defaultRadius);
  val['longTextStyle'] =
      const TextStyleConverter().toJson(instance.longTextStyle);
  val['shortTextStyle'] =
      const TextStyleConverter().toJson(instance.shortTextStyle);
  val['tipsTextStyle'] =
      const TextStyleConverter().toJson(instance.tipsTextStyle);
  val['tipsPadding'] = const EdgeInsetsConverter().toJson(instance.tipsPadding);
  val['tickRectMargin'] = instance.tickRectMargin;
  val['tickTextStyle'] =
      const TextStyleConverter().toJson(instance.tickTextStyle);
  val['tickPadding'] = const EdgeInsetsConverter().toJson(instance.tickPadding);
  val['markLineWidth'] = instance.markLineWidth;
  writeNotNull(
      'markLineColor', const ColorConverter().toJson(instance.markLineColor));
  val['subChartMaxCount'] = instance.subChartMaxCount;
  return val;
}

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);
