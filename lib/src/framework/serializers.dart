// Copyright 2024 Andy.Zhao
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:decimal/decimal.dart';
import 'package:flexi_formatter/date_time.dart';
import 'package:flutter/painting.dart';
import 'package:json_annotation/json_annotation.dart';

import '../constant.dart';
import '../extension/export.dart';
import '../model/flexi_num.dart';
import '../utils/convert_util.dart';
import 'chart/indicator.dart';
import 'draw/overlay.dart';

/// IndicatorKey 序列化转换器
///
/// 格式：`type:id:label`，其中 type 为 `base` | `data` | `business`。
/// - toJson：根据 Key 类型写入对应前缀。
/// - fromJson：根据 type 前缀还原为对应 Key 子类型。
class IIndicatorKeyConvert implements JsonConverter<IIndicatorKey, String> {
  const IIndicatorKeyConvert();

  @override
  IIndicatorKey fromJson(String json) {
    final parts = json.split(':');
    // 格式要求至少 3 段：type:id:label
    if (parts.length < 3) return unknownIndicatorKey;

    final type = parts[0];
    final id = parts[1];
    if (id.isEmpty) return unknownIndicatorKey;

    // 第三段起整体视为 label（兼容 label 含 `:` 的情况）
    final label = parts.sublist(2).join(':');

    return switch (type) {
      final typeName when typeName == (DataIndicatorKey).toString() => DataIndicatorKey(id, label: label),
      final typeName when typeName == (BusinessIndicatorKey).toString() => BusinessIndicatorKey(id, label: label),
      final typeName when typeName == (NormalIndicatorKey).toString() => NormalIndicatorKey(id, label: label),
      _ => NormalIndicatorKey(id, label: label), // unknownIndicatorKey
    };
  }

  @override
  String toJson(IIndicatorKey key) {
    return key.toString();
  }
}

/// NormalIndicatorKey 序列化转换器
///
/// 专门用于处理 NormalIndicatorKey 类型的序列化，
/// 让 json_serializable 能够识别并生成正确的序列化代码。
class NormalIndicatorKeyConvert implements JsonConverter<NormalIndicatorKey, String> {
  const NormalIndicatorKeyConvert();

  @override
  NormalIndicatorKey fromJson(String json) {
    final result = const IIndicatorKeyConvert().fromJson(json);
    if (result is NormalIndicatorKey) {
      return result;
    }
    // 如果解析结果不是 NormalIndicatorKey，返回一个默认值
    // 这种情况理论上不应该发生，但为了类型安全需要处理
    return NormalIndicatorKey(result.id, label: result.label);
  }

  @override
  String toJson(NormalIndicatorKey key) {
    return const IIndicatorKeyConvert().toJson(key);
  }
}

/// DataIndicatorKey 序列化转换器
///
/// 专门用于处理 DataIndicatorKey 类型的序列化，
/// 让 json_serializable 能够识别并生成正确的序列化代码。
class DataIndicatorKeyConvert implements JsonConverter<DataIndicatorKey, String> {
  const DataIndicatorKeyConvert();

  @override
  DataIndicatorKey fromJson(String json) {
    final result = const IIndicatorKeyConvert().fromJson(json);
    if (result is DataIndicatorKey) {
      return result;
    }
    // 如果解析结果不是 DataIndicatorKey，返回一个默认值
    // 这种情况理论上不应该发生，但为了类型安全需要处理
    return DataIndicatorKey(result.id, label: result.label);
  }

  @override
  String toJson(DataIndicatorKey key) {
    return const IIndicatorKeyConvert().toJson(key);
  }
}

/// BusinessIndicatorKey 序列化转换器
///
/// 专门用于处理 BusinessIndicatorKey 类型的序列化，
/// 让 json_serializable 能够识别并生成正确的序列化代码。
class BusinessIndicatorKeyConvert implements JsonConverter<BusinessIndicatorKey, String> {
  const BusinessIndicatorKeyConvert();

  @override
  BusinessIndicatorKey fromJson(String json) {
    final result = const IIndicatorKeyConvert().fromJson(json);
    if (result is BusinessIndicatorKey) {
      return result;
    }
    // 如果解析结果不是 BusinessIndicatorKey，返回一个默认值
    // 这种情况理论上不应该发生，但为了类型安全需要处理
    return BusinessIndicatorKey(result.id, label: result.label);
  }

  @override
  String toJson(BusinessIndicatorKey key) {
    return const IIndicatorKeyConvert().toJson(key);
  }
}

class ITimeBarConvert implements JsonConverter<ITimeBar, Map<String, dynamic>> {
  const ITimeBarConvert();

  @override
  ITimeBar fromJson(Map<String, dynamic> json) {
    final bar = json['bar']?.toString().trim() ?? '';
    final multiplier = parseInt(json['multiplier']) ?? 0;
    final unitName = json['unit']?.toString().trim();
    TimeUnit? unit;
    if (unitName != null && unitName.isNotEmpty) {
      unit = TimeUnit.values.firstWhereOrNull((e) => e.name == unitName);
    }
    unit ??= TimeUnit.microsecond;
    return TimeBar.from(bar, multiplier, unit) ?? FlexiTimeBar(bar, multiplier, unit);
  }

  @override
  Map<String, dynamic> toJson(ITimeBar timeBar) {
    return {
      'bar': timeBar.bar,
      'multiplier': timeBar.multiplier,
      'unit': timeBar.unit.name,
    };
  }
}

class SetIndicatorKeyConverter implements JsonConverter<Set<IIndicatorKey>, List<dynamic>> {
  const SetIndicatorKeyConverter();

  @override
  Set<IIndicatorKey> fromJson(List<dynamic> json) {
    return json.map((e) => const IIndicatorKeyConvert().fromJson(e)).toSet();
  }

  @override
  List<dynamic> toJson(Set<IIndicatorKey> object) {
    return object.map((e) => const IIndicatorKeyConvert().toJson(e)).toList();
  }
}

class PaintModeConverter implements JsonConverter<PaintMode, String> {
  const PaintModeConverter();

  @override
  PaintMode fromJson(String json) {
    return PaintMode.values.firstWhere(
      (e) => e.name == json,
      orElse: () => PaintMode.combine,
    );
  }

  @override
  String toJson(PaintMode mode) => mode.name;
}

class FlexiChartTypeConverter implements JsonConverter<FlexiChartType, Map<String, dynamic>> {
  const FlexiChartTypeConverter();

  @override
  FlexiChartType fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final style = json['style'] as String;

    switch (type) {
      case 'bar':
        final barStyle = ChartBarStyle.values.firstWhere(
          (e) => e.name == style,
          orElse: () => ChartBarStyle.allSolid,
        );
        return FlexiBarChartType(barStyle);
      case 'line':
        final lineStyle = ChartLineStyle.values.firstWhere(
          (e) => e.name == style,
          orElse: () => ChartLineStyle.normal,
        );
        return FlexiLineChartType(lineStyle);
      default:
        return FlexiChartType.barSolid; // 默认值
    }
  }

  @override
  Map<String, dynamic> toJson(FlexiChartType chartType) {
    return switch (chartType) {
      FlexiBarChartType(:final style) => {
          'type': 'bar',
          'style': style.name,
        },
      FlexiLineChartType(:final style) => {
          'type': 'line',
          'style': style.name,
        },
    };
  }
}

class FlexiChartBarStyleConverter implements JsonConverter<ChartBarStyle, String> {
  const FlexiChartBarStyleConverter();

  @override
  ChartBarStyle fromJson(String json) {
    return ChartBarStyle.values.firstWhere(
      (e) => e.name.equalsIgnoreCase(json),
      orElse: () => ChartBarStyle.allSolid,
    );
  }

  @override
  String toJson(ChartBarStyle style) => style.name;
}

class FlexiChartLineStyleConverter implements JsonConverter<ChartLineStyle, String> {
  const FlexiChartLineStyleConverter();

  @override
  ChartLineStyle fromJson(String json) {
    return ChartLineStyle.values.firstWhere(
      (e) => e.name.equalsIgnoreCase(json),
      orElse: () => ChartLineStyle.normal,
    );
  }

  @override
  String toJson(ChartLineStyle style) => style.name;
}

/// LineChartType 类型的序列化转换器
/// 复用 ChartTypeConverter 的实现
class LineChartTypeConverter implements JsonConverter<FlexiLineChartType, Map<String, dynamic>> {
  const LineChartTypeConverter();

  @override
  FlexiLineChartType fromJson(Map<String, dynamic> json) {
    final chartType = const FlexiChartTypeConverter().fromJson(json);
    return chartType is FlexiLineChartType ? chartType : FlexiChartType.lineNormal;
  }

  @override
  Map<String, dynamic> toJson(FlexiLineChartType chartType) {
    return const FlexiChartTypeConverter().toJson(chartType);
  }
}

/// BarChartType 类型的序列化转换器
/// 复用 ChartTypeConverter 的实现
class BarChartTypeConverter implements JsonConverter<FlexiBarChartType, Map<String, dynamic>> {
  const BarChartTypeConverter();

  @override
  FlexiBarChartType fromJson(Map<String, dynamic> json) {
    final chartType = const FlexiChartTypeConverter().fromJson(json);
    return chartType is FlexiBarChartType ? chartType : FlexiChartType.barSolid;
  }

  @override
  Map<String, dynamic> toJson(FlexiBarChartType chartType) {
    return const FlexiChartTypeConverter().toJson(chartType);
  }
}

/// 时间周期图表类型映射的序列化转换器
class TimeBarChartTypesConverter implements JsonConverter<Map<ITimeBar, FlexiChartType>?, List<dynamic>?> {
  const TimeBarChartTypesConverter();

  @override
  Map<ITimeBar, FlexiChartType>? fromJson(List<dynamic>? json) {
    if (json == null) return null;
    return Map.fromEntries(json.map((e) {
      final map = e as Map<String, dynamic>;
      return MapEntry(
        const ITimeBarConvert().fromJson(map['timeBar'] as Map<String, dynamic>),
        const FlexiChartTypeConverter().fromJson(map['chartType'] as Map<String, dynamic>),
      );
    }));
  }

  @override
  List<dynamic>? toJson(Map<ITimeBar, FlexiChartType>? map) {
    if (map == null) return null;
    return map.entries
        .map((e) => {
              'timeBar': const ITimeBarConvert().toJson(e.key),
              'chartType': const FlexiChartTypeConverter().toJson(e.value),
            })
        .toList();
  }
}

/// 基础样式转换

class DrawPositionConverter implements JsonConverter<DrawPosition, String> {
  const DrawPositionConverter();

  @override
  DrawPosition fromJson(String json) {
    return DrawPosition.values.firstWhere(
      (e) => e.name == json,
      orElse: () => DrawPosition.middle,
    );
  }

  @override
  String toJson(DrawPosition object) {
    return object.name;
  }
}

class ScalePositionConverter implements JsonConverter<ScalePosition, String> {
  const ScalePositionConverter();

  @override
  ScalePosition fromJson(String json) {
    return ScalePosition.values.firstWhere(
      (e) => e.name == json,
      orElse: () => ScalePosition.auto,
    );
  }

  @override
  String toJson(ScalePosition object) {
    return object.name;
  }
}

class PaintingStyleConverter implements JsonConverter<PaintingStyle, String> {
  const PaintingStyleConverter();
  @override
  PaintingStyle fromJson(String json) {
    return PaintingStyle.values.firstWhere(
      (e) => e.name == json,
      orElse: () => PaintingStyle.stroke,
    );
  }

  @override
  String toJson(PaintingStyle object) {
    return object.name;
  }
}

class BlendModeConverter implements JsonConverter<BlendMode, String> {
  const BlendModeConverter();
  @override
  BlendMode fromJson(String json) {
    return BlendMode.values.firstWhere(
      (e) => e.name == json,
      orElse: () => BlendMode.srcOver,
    );
  }

  @override
  String toJson(BlendMode object) {
    return object.name;
  }
}

class LineTypeConverter implements JsonConverter<LineType, String> {
  const LineTypeConverter();

  @override
  LineType fromJson(String json) {
    return LineType.values.firstWhere(
      (e) => e.name == json,
      orElse: () => LineType.solid,
    );
  }

  @override
  String toJson(LineType object) {
    return object.name;
  }
}

class EdgeInsetsConverter implements JsonConverter<EdgeInsets, Map<String, dynamic>> {
  const EdgeInsetsConverter();

  @override
  EdgeInsets fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) {
      return EdgeInsets.zero;
    }

    if (json.containsKey('horizontal') || json.containsKey('vertical')) {
      return EdgeInsets.symmetric(
        horizontal: parseDouble(json['horizontal']) ?? 0.0,
        vertical: parseDouble(json['vertical']) ?? 0.0,
      );
    }

    if (json.containsKey('left') ||
        json.containsKey('top') ||
        json.containsKey('right') ||
        json.containsKey('bottom')) {
      return EdgeInsets.only(
        left: parseDouble(json['left']) ?? 0.0,
        top: parseDouble(json['top']) ?? 0.0,
        right: parseDouble(json['right']) ?? 0.0,
        bottom: parseDouble(json['bottom']) ?? 0.0,
      );
    }

    return EdgeInsets.zero;
  }

  @override
  Map<String, dynamic> toJson(EdgeInsets edgeInsets) {
    if (edgeInsets.left == 0 && edgeInsets.top == 0 && edgeInsets.right == 0 && edgeInsets.bottom == 0) {
      return {};
    }

    if (edgeInsets.left == edgeInsets.right && edgeInsets.top == edgeInsets.bottom) {
      return {
        'horizontal': edgeInsets.left,
        'vertical': edgeInsets.top,
      };
    }
    return {
      'left': edgeInsets.left,
      'top': edgeInsets.top,
      'right': edgeInsets.right,
      'bottom': edgeInsets.bottom,
    };
  }
}

class SizeConverter implements JsonConverter<Size, Map<String, dynamic>> {
  const SizeConverter();

  @override
  Size fromJson(Map<String, dynamic> json) {
    return Size(
      parseDouble(json['width']) ?? 0,
      parseDouble(json['height']) ?? 0,
    );
  }

  @override
  Map<String, dynamic> toJson(Size size) {
    return {
      'width': size.width,
      'height': size.height,
    };
  }
}

class RectConverter implements JsonConverter<Rect, Map<String, dynamic>> {
  const RectConverter();

  @override
  Rect fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) return Rect.zero;
    if (json.containsKey('left') || json.containsKey('top')) {
      if (json.containsKey('width') && json.containsKey('height')) {
        return Rect.fromLTWH(
          parseDouble(json['left']) ?? 0,
          parseDouble(json['top']) ?? 0,
          parseDouble(json['width']) ?? 0,
          parseDouble(json['width']) ?? 0,
        );
      } else {
        return Rect.fromLTRB(
          parseDouble(json['left']) ?? 0,
          parseDouble(json['top']) ?? 0,
          parseDouble(json['right']) ?? 0,
          parseDouble(json['bottom']) ?? 0,
        );
      }
    }
    return Rect.zero;
  }

  @override
  Map<String, dynamic> toJson(Rect rect) {
    return {
      'left': rect.left,
      'top': rect.top,
      'right': rect.right,
      'bottom': rect.bottom,
    };
  }
}

class BorderSideConvert implements JsonConverter<BorderSide, Map<String, dynamic>> {
  const BorderSideConvert();

  @override
  BorderSide fromJson(Map<String, dynamic> json) {
    return parseBorderSide(json);
  }

  @override
  Map<String, dynamic> toJson(BorderSide side) {
    return convertBorderSide(side);
  }
}

class BorderConverter implements JsonConverter<Border, Map<String, dynamic>> {
  const BorderConverter();

  @override
  Border fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) return const Border.fromBorderSide(BorderSide.none);
    if (json.containsKey('all')) {
      return Border.fromBorderSide(parseBorderSide(json['all']));
    } else {
      return Border(
        top: parseBorderSide(json['top']),
        right: parseBorderSide(json['right']),
        bottom: parseBorderSide(json['bottom']),
        left: parseBorderSide(json['left']),
      );
    }
  }

  @override
  Map<String, dynamic> toJson(Border border) {
    if (border.isUniform) {
      return {
        'all': convertBorderSide(border.top),
      };
    }
    return {
      'top': convertBorderSide(border.top),
      'right': convertBorderSide(border.right),
      'bottom': convertBorderSide(border.bottom),
      'left': convertBorderSide(border.left),
    };
  }
}

// 仅支持圆角类型
class BorderRadiusConverter implements JsonConverter<BorderRadius, Map<String, dynamic>> {
  const BorderRadiusConverter();

  @override
  BorderRadius fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) return BorderRadius.zero;
    if (json.containsKey('topLeft') ||
        json.containsKey('topRight') ||
        json.containsKey('bottomLeft') ||
        json.containsKey('bottomRight')) {
      return BorderRadius.only(
        topLeft: parseRadius(json['topLeft']),
        topRight: parseRadius(json['topRight']),
        bottomLeft: parseRadius(json['bottomLeft']),
        bottomRight: parseRadius(json['bottomRight']),
      );
    }
    return BorderRadius.zero;
  }

  @override
  Map<String, dynamic> toJson(BorderRadius borderRadius) {
    return {
      'topLeft': convertRadius(borderRadius.topLeft),
      'topRight': convertRadius(borderRadius.topRight),
      'bottomLeft': convertRadius(borderRadius.bottomLeft),
      'bottomRight': convertRadius(borderRadius.bottomRight),
    };
  }
}

class TextAlignConvert implements JsonConverter<TextAlign, String> {
  const TextAlignConvert();

  @override
  TextAlign fromJson(String json) {
    return TextAlign.values.firstWhere(
      (e) => e.name == json,
      orElse: () => TextAlign.start,
    );
  }

  @override
  String toJson(TextAlign object) {
    return object.name;
  }
}

class TextStyleConverter implements JsonConverter<TextStyle, Map<String, dynamic>> {
  const TextStyleConverter();

  @override
  TextStyle fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) return const TextStyle();
    return TextStyle(
      color: parseHexColor(json['color']),
      fontSize: parseDouble(json['fontSize']),
      fontFamily: json['fontFamily'],
      fontStyle: parseFontStyle(json['fontStyle']),
      height: parseDouble(json['height']),
      fontWeight: parseFontWeight(json['fontWeight']),
      textBaseline: parseTextBaseline(json['textBaseline']),
      decoration: parseTextDecoration(json['decoration']),
      decorationColor: parseHexColor(json['decorationColor']),
      decorationStyle: parseTextDecorationStyle(json['decorationStyle']),
    );
  }

  @override
  Map<String, dynamic> toJson(TextStyle style) {
    return {
      'color': convertHexColor(style.color),
      'fontSize': style.fontSize,
      'fontFamily': style.fontFamily,
      'fontStyle': convertFontStyle(style.fontStyle),
      'height': style.height,
      'fontWeight': convertFontWeight(style.fontWeight),
      'textBaseline': convertTextBaseline(style.textBaseline),
      'decoration': convertTextDecoration(style.decoration),
      'decorationColor': convertHexColor(style.decorationColor),
      'decorationStyle': style.decorationStyle?.name,
    };
  }
}

class StrutStyleConverter implements JsonConverter<StrutStyle, Map<String, dynamic>> {
  const StrutStyleConverter();

  @override
  StrutStyle fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) return const StrutStyle();
    return StrutStyle(
      fontFamily: json['fontFamily'],
      height: parseDouble(json['height']),
      leadingDistribution: parseTextLeadingDistribution(
        json['leadingDistribution'],
      ),
      leading: parseDouble(json['leading']),
      fontWeight: parseFontWeight(json['fontWeight']),
      fontStyle: parseFontStyle(json['fontStyle']),
      forceStrutHeight: parseBool(json['forceStrutHeight']),
    );
  }

  @override
  Map<String, dynamic> toJson(StrutStyle style) {
    return {
      'fontFamily': style.fontFamily,
      'height': convertDouble(style.height),
      'leadingDistribution': convertTextLeadingDistribution(
        style.leadingDistribution,
      ),
      'leading': style.leading,
      'fontWeight': convertFontWeight(style.fontWeight),
      'fontStyle': convertFontStyle(style.fontStyle),
      'forceStrutHeight': convertBool(style.forceStrutHeight),
    };
  }
}

class ClipConverter implements JsonConverter<Clip, String> {
  const ClipConverter();

  @override
  Clip fromJson(String clip) {
    return Clip.values.firstWhere(
      (e) => e.name == clip,
      orElse: () => Clip.none,
    );
  }

  @override
  String toJson(Clip clip) {
    return clip.name;
  }
}

/// Alignment 序列化转换器
class AlignmentConverter implements JsonConverter<Alignment, Map<String, dynamic>> {
  const AlignmentConverter();

  @override
  Alignment fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) return Alignment.center;

    // 支持预定义的 Alignment 常量
    final preset = json['preset']?.toString();
    if (preset != null) {
      switch (preset) {
        case 'topLeft':
          return Alignment.topLeft;
        case 'topCenter':
          return Alignment.topCenter;
        case 'topRight':
          return Alignment.topRight;
        case 'centerLeft':
          return Alignment.centerLeft;
        case 'center':
          return Alignment.center;
        case 'centerRight':
          return Alignment.centerRight;
        case 'bottomLeft':
          return Alignment.bottomLeft;
        case 'bottomCenter':
          return Alignment.bottomCenter;
        case 'bottomRight':
          return Alignment.bottomRight;
      }
    }

    // 支持自定义 x, y 值
    if (json.containsKey('x') && json.containsKey('y')) {
      return Alignment(
        parseDouble(json['x']) ?? 0.0,
        parseDouble(json['y']) ?? 0.0,
      );
    }

    return Alignment.center;
  }

  @override
  Map<String, dynamic> toJson(Alignment alignment) {
    // 尝试匹配预定义常量
    if (alignment == Alignment.topLeft) return {'preset': 'topLeft'};
    if (alignment == Alignment.topCenter) return {'preset': 'topCenter'};
    if (alignment == Alignment.topRight) return {'preset': 'topRight'};
    if (alignment == Alignment.centerLeft) return {'preset': 'centerLeft'};
    if (alignment == Alignment.center) return {'preset': 'center'};
    if (alignment == Alignment.centerRight) return {'preset': 'centerRight'};
    if (alignment == Alignment.bottomLeft) return {'preset': 'bottomLeft'};
    if (alignment == Alignment.bottomCenter) return {'preset': 'bottomCenter'};
    if (alignment == Alignment.bottomRight) return {'preset': 'bottomRight'};

    // 自定义值
    return {
      'x': alignment.x,
      'y': alignment.y,
    };
  }
}

/// TileMode 序列化转换器
class TileModeConverter implements JsonConverter<TileMode, String> {
  const TileModeConverter();

  @override
  TileMode fromJson(String json) {
    return TileMode.values.firstWhere(
      (e) => e.name == json,
      orElse: () => TileMode.clamp,
    );
  }

  @override
  String toJson(TileMode mode) {
    return mode.name;
  }
}

/// LinearGradient 序列化转换器
class LinearGradientConverter implements JsonConverter<LinearGradient, Map<String, dynamic>> {
  const LinearGradientConverter();

  @override
  LinearGradient fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) {
      return const LinearGradient(colors: []);
    }

    // 解析颜色列表
    final colorsList = json['colors'] as List<dynamic>?;
    final colors = colorsList?.map((c) {
          if (c is String) {
            return parseHexColor(c) ?? const Color(0x00000000);
          } else if (c is int) {
            return Color(c);
          }
          return const Color(0x00000000);
        }).toList() ??
        [];

    // 解析 stops
    final stopsList = json['stops'] as List<dynamic>?;
    final stops = stopsList?.map((s) => parseDouble(s) ?? 0.0).toList();

    return LinearGradient(
      begin: json.containsKey('begin') ? const AlignmentConverter().fromJson(json['begin']) : Alignment.centerLeft,
      end: json.containsKey('end') ? const AlignmentConverter().fromJson(json['end']) : Alignment.centerRight,
      colors: colors,
      stops: stops,
      tileMode: json.containsKey('tileMode') ? const TileModeConverter().fromJson(json['tileMode']) : TileMode.clamp,
    );
  }

  @override
  Map<String, dynamic> toJson(LinearGradient gradient) {
    return {
      'begin': const AlignmentConverter().toJson(gradient.begin as Alignment),
      'end': const AlignmentConverter().toJson(gradient.end as Alignment),
      'colors': gradient.colors.map((c) => convertHexColor(c)).toList(),
      if (gradient.stops != null) 'stops': gradient.stops,
      'tileMode': const TileModeConverter().toJson(gradient.tileMode),
    };
  }
}

class BoxShadowConverter implements JsonConverter<BoxShadow, Map<String, dynamic>> {
  const BoxShadowConverter();

  @override
  BoxShadow fromJson(Map<String, dynamic> json) {
    return BoxShadow(
      color: parseHexColor(json['color']) ?? const Color(0xFF000000),
      offset: const OffsetConverter().fromJson(json['offset']),
      blurRadius: parseDouble(json['blurRadius']) ?? 0.0,
      spreadRadius: parseDouble(json['spreadRadius']) ?? 0.0,
      blurStyle: BlurStyle.values.firstWhere(
        (e) => e.name == json['blurStyle'],
        orElse: () => BlurStyle.normal,
      ),
    );
  }

  @override
  Map<String, dynamic> toJson(BoxShadow shadow) {
    return {
      'color': convertHexColor(shadow.color),
      'offset': const OffsetConverter().toJson(shadow.offset),
      'blurRadius': convertDouble(shadow.blurRadius),
      'spreadRadius': convertDouble(shadow.spreadRadius),
      'blurStyle': shadow.blurStyle.name,
    };
  }
}

class OffsetConverter implements JsonConverter<Offset, Map<String, dynamic>> {
  const OffsetConverter({this.defaultOffset = Offset.zero});

  final Offset defaultOffset;

  @override
  Offset fromJson(Map<String, dynamic> json) {
    final dx = parseDouble(json['dx']);
    final dy = parseDouble(json['dy']);
    if (dx != null && dy != null) {
      return Offset(dx, dy);
    }
    return defaultOffset;
  }

  @override
  Map<String, dynamic> toJson(Offset offset) {
    return {
      'dx': convertDouble(offset.dx),
      'dy': convertDouble(offset.dy),
    };
  }
}

class ColorConverter implements JsonConverter<Color, String> {
  const ColorConverter();

  @override
  Color fromJson(String json) {
    return parseHexColor(json) ?? const Color(0x00000000);
  }

  @override
  String toJson(Color color) {
    return convertHexColor(color) ?? '';
  }
}

class DecimalConverter implements JsonConverter<Decimal, dynamic> {
  const DecimalConverter();
  @override
  Decimal fromJson(dynamic json) {
    return parseDecimal(json) ?? Decimal.zero;
  }

  @override
  String toJson(Decimal object) {
    return convertDecimal(object);
  }
}

class FlexiNumConverter implements JsonConverter<FlexiNum, dynamic> {
  const FlexiNumConverter();

  @override
  FlexiNum fromJson(dynamic json) {
    final value = parseDecimal(json);
    return value != null ? FlexiNum.fromDecimal(value) : FlexiNum.zero;
  }

  @override
  String toJson(FlexiNum object) {
    return convertDecimal(object.toDecimal());
  }
}

class MagnetModeConverter implements JsonConverter<MagnetMode, String> {
  const MagnetModeConverter();
  @override
  MagnetMode fromJson(String json) {
    return MagnetMode.values.firstWhere(
      (e) => e.name == json,
      orElse: () => MagnetMode.normal,
    );
  }

  @override
  String toJson(MagnetMode object) {
    return object.name;
  }
}

class IDrawTypeConverter implements JsonConverter<IDrawType, Map<String, dynamic>> {
  const IDrawTypeConverter();

  @override
  IDrawType fromJson(Map<String, dynamic> json) {
    final String? groupId = json.getItem('groupId');
    final String? id = json.getItem('id');
    final int? steps = json.getItem('steps');
    if (id != null && steps != null) {
      return FlexiDrawType(id, steps, groupId: groupId);
    }
    return unknownDrawType;
  }

  @override
  Map<String, dynamic> toJson(IDrawType object) {
    return {'id': object.id, 'steps': object.steps, 'groupId': object.groupId};
  }
}

const _basicConverterList = <JsonConverter>[
  DrawPositionConverter(),
  ScalePositionConverter(),
  PaintingStyleConverter(),
  BlendModeConverter(),
  LineTypeConverter(),
  EdgeInsetsConverter(),
  SizeConverter(),
  RectConverter(),
  BorderSideConvert(),
  BorderConverter(),
  BorderRadiusConverter(),
  ClipConverter(),
  AlignmentConverter(),
  TileModeConverter(),
  LinearGradientConverter(),
  BoxShadowConverter(),
  OffsetConverter(),
  TextAlignConvert(),
  TextStyleConverter(),
  StrutStyleConverter(),
  ColorConverter(),
  DecimalConverter(),
  FlexiNumConverter(),
  FlexiChartTypeConverter(),
  FlexiChartBarStyleConverter(),
  FlexiChartLineStyleConverter(),
  LineChartTypeConverter(),
  BarChartTypeConverter(),
  ITimeBarConvert(),
];

// ignore: constant_identifier_names
const FlexiOverlaySerializable = JsonSerializable(
  converters: [
    IDrawTypeConverter(),
    MagnetModeConverter(),
    ..._basicConverterList,
  ],
  explicitToJson: true,
  // genericArgumentFactories: true,
);

// ignore: constant_identifier_names
const FlexiIndicatorSerializable = JsonSerializable(
  converters: [
    BusinessIndicatorKeyConvert(),
    DataIndicatorKeyConvert(),
    NormalIndicatorKeyConvert(),
    IIndicatorKeyConvert(),
    PaintModeConverter(),
    TimeBarChartTypesConverter(),
    ..._basicConverterList,
  ],
  explicitToJson: true,
  // genericArgumentFactories: true,
);

// ignore: constant_identifier_names
const FlexiParamSerializable = JsonSerializable(
  converters: [
    ColorConverter(),
    EdgeInsetsConverter(),
  ],
  explicitToJson: true,
);

// ignore: constant_identifier_names
const FlexiModelSerializable = JsonSerializable(
  converters: _basicConverterList,
  // ignoreUnannotated: true,
  explicitToJson: true,
  includeIfNull: false,
);

// ignore: constant_identifier_names
const FlexiConfigSerializable = JsonSerializable(
  converters: [
    ..._basicConverterList,
    SetIndicatorKeyConverter(),
  ],
  explicitToJson: true,
  includeIfNull: false,
);
