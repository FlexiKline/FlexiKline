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

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

import 'common.dart';
import 'indicator.dart';

class ValueKeyConverter implements JsonConverter<ValueKey, String> {
  const ValueKeyConverter();
  @override
  ValueKey fromJson(String json) {
    if (json.trim().isEmpty) return const ValueKey('');
    if (json.startsWith('IndicatorType')) {
      final name = json.substring('IndicatorType'.length + 1);
      final types = IndicatorType.values.where((type) => type.name == name);
      if (types.isNotEmpty) return ValueKey(types.first);
    }

    return ValueKey(json);
  }

  @override
  String toJson(ValueKey key) {
    return key.value.toString();
  }
}

class EdgeInsetsConverter
    implements JsonConverter<EdgeInsets, Map<String, double>> {
  const EdgeInsetsConverter();

  double parseDouble(dynamic value) {
    if (value == null) {
      return 0;
    } else if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      return double.parse(value);
    } else {
      return 0;
    }
  }

  @override
  EdgeInsets fromJson(Map<String, double> json) {
    if (json.isEmpty) {
      return EdgeInsets.zero;
    }

    if (json.containsKey('vertical') || json.containsKey('horizontal')) {
      return EdgeInsets.symmetric(
        vertical: parseDouble(json['vertical']),
        horizontal: parseDouble(json['horizontal']),
      );
    }

    if (json.containsKey('left') ||
        json.containsKey('top') ||
        json.containsKey('right') ||
        json.containsKey('bottom')) {
      return EdgeInsets.only(
        left: parseDouble(json['left']),
        top: parseDouble(json['top']),
        right: parseDouble(json['right']),
        bottom: parseDouble(json['bottom']),
      );
    }

    return EdgeInsets.zero;
  }

  @override
  Map<String, double> toJson(EdgeInsets edgeInsets) {
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
    if (json == null || json.trim().isEmpty) {
      return Colors.transparent;
    }

    if (json.startsWith('0x')) {
      int? colorInt = int.tryParse(json);
      if (colorInt == null) return Colors.transparent;
      return Color(colorInt);
    }

    json = json.toUpperCase().replaceAll("#", "");
    if (json.length == 6) {
      json = "FF$json";
    }
    int colorInt = int.parse(json, radix: 16);
    return Color(colorInt);
  }

  @override
  String toJson(Color? color) {
    if (color == null) return '';
    return '0x${color.value.toRadixString(16).padLeft(8, '0')}';
  }
}

const indicatorSerializable = JsonSerializable(
  converters: [
    ValueKeyConverter(),
    ColorConverter(),
    PaintModeConverter(),
    EdgeInsetsConverter(),
  ],
  explicitToJson: true,
  genericArgumentFactories: true,
);

const paramSerializable = JsonSerializable(
  converters: [
    ColorConverter(),
    EdgeInsetsConverter(),
  ],
  explicitToJson: true,
);
