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

class EdgeInsetsConverter
    implements JsonConverter<EdgeInsets, Map<String, dynamic>> {
  const EdgeInsetsConverter();

  @override
  EdgeInsets fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) {
      return EdgeInsets.zero;
    }

    if (json.containsKey('vertical') || json.containsKey('horizontal')) {
      return EdgeInsets.symmetric(
        vertical: parseDouble(json['vertical']) ?? 0.0,
        horizontal: parseDouble(json['horizontal']) ?? 0.0,
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
        "vertical": edgeInsets.left,
        "horizontal": edgeInsets.top,
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

// 定义一个JsonConverter实现类，用于转换Status枚举类型。
class PaintModeConverter implements JsonConverter<PaintMode, String> {
  const PaintModeConverter();

  // 从JSON到Dart的转换：将字符串转换为Status枚举值。
  @override
  PaintMode fromJson(String json) {
    switch (json) {
      case 'combine':
        return PaintMode.combine;
      case 'alone':
        return PaintMode.alone;
      default:
        return PaintMode.combine;
    }
  }

  // 从Dart到JSON的转换：将Status枚举值转换为字符串。
  @override
  String toJson(PaintMode mode) => mode.name;
}

class ColorConverter implements JsonConverter<Color, String?> {
  const ColorConverter();

  @override
  Color fromJson(String? json) {
    return parseHexColor(json) ?? Colors.transparent;
  }

  @override
  String toJson(Color? color) {
    return convertHexColor(color) ?? '';
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
      'fontSize': convertDouble(style.fontSize),
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

// ignore: constant_identifier_names
const FlexiIndicatorSerializable = JsonSerializable(
  converters: [
    ValueKeyConverter(),
    ColorConverter(),
    PaintModeConverter(),
    EdgeInsetsConverter(),
    TextStyleConverter(),
    SizeConverter(),
    RectConverter(),
    BorderSideConvert(),
    BorderConverter(),
    BorderRadiusConverter(),
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
  converters: [
    ColorConverter(),
    DecimalConverter(),
    EdgeInsetsConverter(),
    TextStyleConverter(),
    SizeConverter(),
    RectConverter(),
    BorderSideConvert(),
    BorderConverter(),
    BorderRadiusConverter(),
    PaintingStyleConverter(),
    LineTypeConverter(),
  ],
  ignoreUnannotated: true,
  explicitToJson: true,
  includeIfNull: false,
);

// ignore: constant_identifier_names
const FlexiConfigSerializable = JsonSerializable(
  converters: [
    ColorConverter(),
    DecimalConverter(),
    EdgeInsetsConverter(),
    TextStyleConverter(),
    SizeConverter(),
    RectConverter(),
    BorderSideConvert(),
    BorderConverter(),
    BorderRadiusConverter(),
    PaintingStyleConverter(),
    LineTypeConverter(),
  ],
  explicitToJson: true,
  includeIfNull: false,
);

final class _Freezed {
  const _Freezed();
}

const freezed = _Freezed();