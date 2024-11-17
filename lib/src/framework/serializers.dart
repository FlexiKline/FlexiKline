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
import 'package:flutter/painting.dart';
import 'package:json_annotation/json_annotation.dart';

import '../extension/export.dart';
import '../model/bag_num.dart';
import '../utils/convert_util.dart';
import 'chart/indicator.dart';
import 'draw/overlay.dart';

class IIndicatorKeyConvert implements JsonConverter<IIndicatorKey, String> {
  const IIndicatorKeyConvert();

  @override
  IIndicatorKey fromJson(String json) {
    final splits = json.split(":");
    final id = splits.getItem(0);
    if (id == null || id.isEmpty) return unknownIndicatorKey;
    final indicatorType = IndicatorType.values.firstWhereOrNull(
      (type) => type.id == id,
    );
    if (indicatorType != null) return indicatorType;
    final label = splits.getItem(1);
    return FlexiIndicatorKey(id, label: label);
  }

  @override
  String toJson(IIndicatorKey key) {
    if (key is IndicatorType) {
      return key.id;
    }
    return "${key.id}:${key.label}";
  }
}

class SetIndicatorKeyConverter
    implements JsonConverter<Set<IIndicatorKey>, List<dynamic>> {
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

class BoxShadowConverter
    implements JsonConverter<BoxShadow, Map<String, dynamic>> {
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

class BagNumConverter implements JsonConverter<BagNum, dynamic> {
  const BagNumConverter();

  @override
  BagNum fromJson(dynamic json) {
    final value = parseDecimal(json);
    return value != null ? BagNum.fromDecimal(value) : BagNum.zero;
  }

  @override
  String toJson(BagNum object) {
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

class IDrawTypeConverter
    implements JsonConverter<IDrawType, Map<String, dynamic>> {
  const IDrawTypeConverter();

  @override
  IDrawType fromJson(Map<String, dynamic> json) {
    final String? groupId = json.getItem('groupId');
    final String? id = json.getItem('id');
    final int? steps = json.getItem('steps');
    if (id != null && steps != null) {
      IDrawType? type = DrawType.values.firstWhereOrNull((type) {
        return type.groupId == groupId && type.id == id && type.steps == steps;
      });
      return type ?? FlexiDrawType(id, steps, groupId: groupId);
    }
    return unknownDrawType;
  }

  @override
  Map<String, dynamic> toJson(IDrawType object) {
    return {'id': object.id, 'steps': object.steps};
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
  BoxShadowConverter(),
  OffsetConverter(),
  TextAlignConvert(),
  TextStyleConverter(),
  StrutStyleConverter(),
  ColorConverter(),
  DecimalConverter(),
  BagNumConverter(),
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
    IIndicatorKeyConvert(),
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
    SetIndicatorKeyConverter(),
  ],
  explicitToJson: true,
  includeIfNull: false,
);
