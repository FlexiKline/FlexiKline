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
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

import '../extension/export.dart';
import '../utils/convert_util.dart';
import 'common.dart';
import 'indicator.dart';

ValueKey parseValueKey(String key) {
  if (key.trim().isEmpty) return const ValueKey('');
  final name = key.toLowerCase();
  final types = IndicatorType.values.where(
    (type) => type.name.toLowerCase() == name,
  );
  if (types.isNotEmpty) return ValueKey(types.first);
  return ValueKey(key);
}

String convertValueKey(ValueKey key) {
  if (key.value is IndicatorType) {
    return (key.value as IndicatorType).name;
  }
  return key.value.toString();
}

class ValueKeyConverter implements JsonConverter<ValueKey, String> {
  const ValueKeyConverter();

  @override
  ValueKey fromJson(String json) {
    return parseValueKey(json);
  }

  @override
  String toJson(ValueKey key) {
    return convertValueKey(key);
  }
}

class SetValueKeyConverter
    implements JsonConverter<Set<ValueKey>, List<dynamic>> {
  const SetValueKeyConverter();

  @override
  Set<ValueKey> fromJson(List<dynamic> json) {
    return json.map((e) => const ValueKeyConverter().fromJson(e)).toSet();
  }

  @override
  List<dynamic> toJson(Set<ValueKey> object) {
    return object.map((e) => const ValueKeyConverter().toJson(e)).toList();
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

class EdgeInsetsConverter
    implements JsonConverter<EdgeInsets, Map<String, dynamic>> {
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
    if (edgeInsets.left == 0 &&
        edgeInsets.top == 0 &&
        edgeInsets.right == 0 &&
        edgeInsets.bottom == 0) return {};

    if (edgeInsets.left == edgeInsets.right &&
        edgeInsets.top == edgeInsets.bottom) {
      return {
        "horizontal": edgeInsets.left,
        "vertical": edgeInsets.top,
      };
    }
    return {
      "left": edgeInsets.left,
      "top": edgeInsets.top,
      "right": edgeInsets.right,
      "bottom": edgeInsets.bottom,
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

class BorderSideConvert
    implements JsonConverter<BorderSide, Map<String, dynamic>> {
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
        "all": convertBorderSide(border.top),
      };
    }
    return {
      "top": convertBorderSide(border.top),
      "right": convertBorderSide(border.right),
      "bottom": convertBorderSide(border.bottom),
      "left": convertBorderSide(border.left),
    };
  }
}

// 仅支持圆角类型
class BorderRadiusConverter
    implements JsonConverter<BorderRadius, Map<String, dynamic>> {
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

class TextStyleConverter
    implements JsonConverter<TextStyle, Map<String, dynamic>> {
  const TextStyleConverter();

  @override
  TextStyle fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) return const TextStyle(); // TODO: 待优化.
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

class StrutStyleConverter
    implements JsonConverter<StrutStyle, Map<String, dynamic>> {
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

class ColorConverter implements JsonConverter<Color, String> {
  const ColorConverter();

  @override
  Color fromJson(String json) {
    return parseHexColor(json) ?? Colors.transparent;
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

const _basicConverterList = <JsonConverter>[
  DrawPositionConverter(),
  ScalePositionConverter(),
  PaintingStyleConverter(),
  LineTypeConverter(),
  EdgeInsetsConverter(),
  SizeConverter(),
  RectConverter(),
  BorderSideConvert(),
  BorderConverter(),
  BorderRadiusConverter(),
  TextAlignConvert(),
  TextStyleConverter(),
  StrutStyleConverter(),
  ColorConverter(),
  DecimalConverter(),
];

// ignore: constant_identifier_names
const FlexiIndicatorSerializable = JsonSerializable(
  converters: [
    ValueKeyConverter(),
    PaintModeConverter(),
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
  ignoreUnannotated: true,
  explicitToJson: true,
  includeIfNull: false,
);

// ignore: constant_identifier_names
const FlexiConfigSerializable = JsonSerializable(
  converters: [
    ..._basicConverterList,
    SetValueKeyConverter(),
  ],
  explicitToJson: true,
  includeIfNull: false,
);
