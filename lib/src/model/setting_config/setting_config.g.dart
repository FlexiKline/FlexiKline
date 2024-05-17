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
      mainPadding: json['mainPadding'] == null
          ? const EdgeInsets.only(top: 12, bottom: 15)
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
      tickText: json['tickText'] == null
          ? const TextAreaConfig(
              style: TextStyle(
                  fontSize: defaulTextSize,
                  color: Colors.black,
                  overflow: TextOverflow.ellipsis,
                  height: defaultTextHeight),
              textAlign: TextAlign.end,
              padding: EdgeInsets.symmetric(horizontal: 2))
          : TextAreaConfig.fromJson(json['tickText'] as Map<String, dynamic>),
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
  val['mainPadding'] = const EdgeInsetsConverter().toJson(instance.mainPadding);
  val['minPaintBlankRate'] = instance.minPaintBlankRate;
  val['alwaysCalculateScreenOfCandlesIfEnough'] =
      instance.alwaysCalculateScreenOfCandlesIfEnough;
  val['candleMaxWidth'] = instance.candleMaxWidth;
  val['candleWidth'] = instance.candleWidth;
  val['candleSpacing'] = instance.candleSpacing;
  val['candleLineWidth'] = instance.candleLineWidth;
  val['firstCandleInitOffset'] = instance.firstCandleInitOffset;
  val['tickText'] = instance.tickText.toJson();
  val['subChartMaxCount'] = instance.subChartMaxCount;
  return val;
}
