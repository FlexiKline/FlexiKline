// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'setting_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettingData _$SettingDataFromJson(Map<String, dynamic> json) => SettingData(
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
      gridCount: (json['gridCount'] as num?)?.toInt() ?? 5,
      gridLineColor: json['gridLineColor'] == null
          ? const Color(0xffE9EDF0)
          : const ColorConverter().fromJson(json['gridLineColor'] as String?),
      gridLineWidth: (json['gridLineWidth'] as num?)?.toDouble() ?? 0.5,
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
      crosshairLineWidth:
          (json['crosshairLineWidth'] as num?)?.toDouble() ?? 0.5,
      crosshairLineColor: json['crosshairLineColor'] == null
          ? Colors.black
          : const ColorConverter()
              .fromJson(json['crosshairLineColor'] as String?),
      crosshairLineDashes: (json['crosshairLineDashes'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const [3, 3],
      corssPointColor: json['corssPointColor'] == null
          ? Colors.black
          : const ColorConverter().fromJson(json['corssPointColor'] as String?),
      crossPointRadius: (json['crossPointRadius'] as num?)?.toDouble() ?? 2,
      crossPointWidth: (json['crossPointWidth'] as num?)?.toDouble() ?? 6,
      crossTickTextStyle: json['crossTickTextStyle'] == null
          ? const TextStyle(
              fontSize: 10,
              color: Colors.white,
              overflow: TextOverflow.ellipsis,
              height: 1)
          : const TextStyleConverter()
              .fromJson(json['crossTickTextStyle'] as Map<String, dynamic>),
      crossTickBackground: json['crossTickBackground'] == null
          ? Colors.black
          : const ColorConverter()
              .fromJson(json['crossTickBackground'] as String?),
      crossTickPadding: json['crossTickPadding'] == null
          ? const EdgeInsets.all(2)
          : const EdgeInsetsConverter()
              .fromJson(json['crossTickPadding'] as Map<String, dynamic>),
      crossTickBorder: json['crossTickBorder'] == null
          ? BorderSide.none
          : const BorderSideConvert()
              .fromJson(json['crossTickBorder'] as Map<String, dynamic>),
      crossTickRadius: json['crossTickRadius'] == null
          ? const BorderRadius.all(Radius.circular(2))
          : const BorderRadiusConverter()
              .fromJson(json['crossTickRadius'] as Map<String, dynamic>),
      subChartMaxCount: (json['subChartMaxCount'] as num?)?.toInt() ??
          defaultSubChartMaxCount,
      subIndicatorTickCount:
          (json['subIndicatorTickCount'] as num?)?.toInt() ?? 3,
      subIndicatorDefaultHeight:
          (json['subIndicatorDefaultHeight'] as num?)?.toDouble() ??
              defaultSubIndicatorHeight,
      subIndicatorDefaultTipsHeight:
          (json['subIndicatorDefaultTipsHeight'] as num?)?.toDouble() ??
              defaultIndicatorTipsHeight,
      subIndicatorDefaultPadding: json['subIndicatorDefaultPadding'] == null
          ? defaultIndicatorPadding
          : const EdgeInsetsConverter().fromJson(
              json['subIndicatorDefaultPadding'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SettingDataToJson(SettingData instance) {
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
  val['gridCount'] = instance.gridCount;
  writeNotNull(
      'gridLineColor', const ColorConverter().toJson(instance.gridLineColor));
  val['gridLineWidth'] = instance.gridLineWidth;
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
  val['crosshairLineWidth'] = instance.crosshairLineWidth;
  writeNotNull('crosshairLineColor',
      const ColorConverter().toJson(instance.crosshairLineColor));
  val['crosshairLineDashes'] = instance.crosshairLineDashes;
  writeNotNull('corssPointColor',
      const ColorConverter().toJson(instance.corssPointColor));
  val['crossPointRadius'] = instance.crossPointRadius;
  val['crossPointWidth'] = instance.crossPointWidth;
  val['crossTickTextStyle'] =
      const TextStyleConverter().toJson(instance.crossTickTextStyle);
  writeNotNull('crossTickBackground',
      const ColorConverter().toJson(instance.crossTickBackground));
  val['crossTickPadding'] =
      const EdgeInsetsConverter().toJson(instance.crossTickPadding);
  val['crossTickBorder'] =
      const BorderSideConvert().toJson(instance.crossTickBorder);
  val['crossTickRadius'] =
      const BorderRadiusConverter().toJson(instance.crossTickRadius);
  val['subChartMaxCount'] = instance.subChartMaxCount;
  val['subIndicatorTickCount'] = instance.subIndicatorTickCount;
  val['subIndicatorDefaultHeight'] = instance.subIndicatorDefaultHeight;
  val['subIndicatorDefaultTipsHeight'] = instance.subIndicatorDefaultTipsHeight;
  val['subIndicatorDefaultPadding'] =
      const EdgeInsetsConverter().toJson(instance.subIndicatorDefaultPadding);
  return val;
}

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);
