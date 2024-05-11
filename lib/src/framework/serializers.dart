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
import 'package:flutter/widgets.dart';
import 'package:json_annotation/json_annotation.dart';

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
    return parseHexColor(json);
  }

  @override
  String toJson(Color? color) {
    return convertHexColor(color);
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
    DecimalConverter(),
  ],
  ignoreUnannotated: true,
  explicitToJson: true,
);

final class _Freezed {
  const _Freezed();
}

const freezed = _Freezed();
