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

import '../constant.dart';

int valueToInt(dynamic value) {
  return parseInt(value) ?? 0;
}

String intToString(int value) {
  return value.toString();
}

int? parseInt(dynamic value, {int? def}) {
  if (value == null) {
    return def;
  } else if (value is num) {
    return value.toInt();
  } else if (value is String) {
    return int.tryParse(value);
  }
  return int.tryParse(value.toString());
}

String? convertInt(double? value, {String? def}) {
  if (value == null) return def;
  return value.toString();
}

DateTime? parseDateTime(dynamic value) {
  if (value == null) {
    return null;
  } else if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  } else if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

int? convertDateTime(dynamic dateTime) {
  if (dateTime == null) {
    return null;
  } else if (dateTime is DateTime) {
    return dateTime.millisecondsSinceEpoch;
  } else if (dateTime is int) {
    return dateTime;
  }
  return int.tryParse(dateTime.toString());
}

/// parse vs convert.

bool? parseBool(dynamic value, {bool? def}) {
  if (value == null) return def;
  final val = value.toString().toLowerCase();
  if (val == 'true') return true;
  if (val == 'false') return false;
  return null;
}

String? convertBool(bool? value) {
  if (value == null) return null;
  return value ? 'true' : 'false';
}

Decimal? parseDecimal(dynamic value, {Decimal? def}) {
  if (value == null) {
    return def;
  } else if (value is int) {
    return Decimal.fromInt(value);
  } else {
    return Decimal.tryParse(value.toString());
  }
}

String convertDecimal(Decimal value) {
  return value.toStringAsFixed(defaultScaleOnInfinitePrecision);
}

double? parseDouble(dynamic value, {double? def}) {
  if (value == null) {
    return def;
  } else if (value is num) {
    return value.toDouble();
  } else if (value is String) {
    return double.tryParse(value) ?? 0;
  } else {
    return def;
  }
}

String? convertDouble(double? value, {String? def}) {
  if (value == null) return def;
  return value.toString();
}

Color? parseHexColor(String? hexStr, {Color? def}) {
  if (hexStr == null || hexStr.trim().isEmpty) {
    return def;
  }

  if (hexStr.startsWith('0x')) {
    int? colorInt = int.tryParse(hexStr);
    if (colorInt == null) return def;
    return Color(colorInt);
  }

  hexStr = hexStr.toUpperCase().replaceAll("#", "");
  if (hexStr.length == 6) {
    hexStr = "FF$hexStr";
  }
  int colorInt = int.parse(hexStr, radix: 16);
  return Color(colorInt);
}

String? convertHexColor(Color? color, {String? def}) {
  if (color == null) return def;
  return '0x${color.value.toRadixString(16).padLeft(8, '0')}';
}

FontStyle parseFontStyle(
  String? fontStyle, {
  FontStyle def = FontStyle.normal,
}) {
  if (fontStyle == 'normal') {
    return FontStyle.normal;
  }

  if (fontStyle == 'italic') {
    return FontStyle.italic;
  }

  return def;
}

String convertFontStyle(FontStyle? style, {FontStyle def = FontStyle.normal}) {
  return style?.name ?? def.name;
}

FontWeight parseFontWeight(
  String? textFontWeight, {
  FontWeight def = FontWeight.normal,
}) {
  FontWeight fontWeight = def;
  switch (textFontWeight) {
    case 'w100':
      fontWeight = FontWeight.w100;
      break;
    case 'w200':
      fontWeight = FontWeight.w200;
      break;
    case 'w300':
      fontWeight = FontWeight.w300;
      break;
    case 'normal':
    case 'w400':
      fontWeight = FontWeight.w400;
      break;
    case 'w500':
      fontWeight = FontWeight.w500;
      break;
    case 'w600':
      fontWeight = FontWeight.w600;
      break;
    case 'bold':
    case 'w700':
      fontWeight = FontWeight.w700;
      break;
    case 'w800':
      fontWeight = FontWeight.w800;
      break;
    case 'w900':
      fontWeight = FontWeight.w900;
      break;
    default:
      fontWeight = FontWeight.normal;
  }
  return fontWeight;
}

String convertFontWeight(
  FontWeight? fontWeight, {
  FontWeight def = FontWeight.normal,
}) {
  fontWeight ??= def;
  String weight = 'w400';
  switch (fontWeight) {
    case FontWeight.w100:
      weight = 'w100';
      break;
    case FontWeight.w200:
      weight = 'w200';
      break;
    case FontWeight.w300:
      weight = 'w300';
      break;
    case FontWeight.w400:
      weight = 'w400';
      break;
    case FontWeight.w500:
      weight = 'w500';
      break;
    case FontWeight.w600:
      weight = 'w600';
      break;
    case FontWeight.w700:
      weight = 'w700';
      break;
    case FontWeight.w800:
      weight = 'w800';
      break;
    case FontWeight.w900:
      weight = 'w900';
      break;
    default:
      weight = 'w400';
  }
  return weight;
}

TextBaseline parseTextBaseline(
  String? textBaseline, {
  TextBaseline def = TextBaseline.ideographic,
}) {
  if (textBaseline == null) return def;
  return 'alphabetic' == textBaseline
      ? TextBaseline.alphabetic
      : TextBaseline.ideographic;
}

String convertTextBaseline(
  TextBaseline? textBaseline, {
  String def = 'ideographic',
}) {
  if (textBaseline == null) return def;
  return textBaseline.name;
}

TextDecoration parseTextDecoration(
  String? decoration, {
  TextDecoration def = TextDecoration.none,
}) {
  TextDecoration textDecoration = def;
  switch (decoration) {
    case "lineThrough":
      textDecoration = TextDecoration.lineThrough;
      break;
    case "overline":
      textDecoration = TextDecoration.overline;
      break;
    case "underline":
      textDecoration = TextDecoration.underline;
      break;
    case "none":
  }
  return textDecoration;
}

String convertTextDecoration(
  TextDecoration? decoration, {
  TextDecoration def = TextDecoration.none,
}) {
  decoration = def;
  switch (decoration) {
    case TextDecoration.none:
      return 'none';
    case TextDecoration.lineThrough:
      return 'lineThrough';
    case TextDecoration.overline:
      return 'overline';
    case TextDecoration.underline:
      return 'underline';
  }
  return 'none';
}

TextDecorationStyle parseTextDecorationStyle(
  String? style, {
  TextDecorationStyle def = TextDecorationStyle.solid,
}) {
  if (style == null) return def;
  return TextDecorationStyle.values.firstWhere(
    (e) => e.name == style,
    orElse: () => def,
  );
}

TextLeadingDistribution? parseTextLeadingDistribution(String? distribution,
    {TextLeadingDistribution? def}) {
  if (distribution == null) return def;
  if (distribution == TextLeadingDistribution.proportional.name) {
    return TextLeadingDistribution.proportional;
  }
  if (distribution == TextLeadingDistribution.even.name) {
    return TextLeadingDistribution.even;
  }
  return null;
}

String? convertTextLeadingDistribution(TextLeadingDistribution? distribution) {
  if (distribution == null) return null;
  return distribution.name;
}

BorderSide parseBorderSide(Map<String, dynamic>? json) {
  if (json == null || json.isEmpty) return BorderSide.none;
  final style = json['style']?.toString() ?? BorderStyle.solid.name;
  return BorderSide(
    color: parseHexColor(json['color']) ?? const Color(0xFF000000),
    width: parseDouble(json['width']) ?? 1.0,
    style: BorderStyle.values.firstWhere(
      (e) => e.name == style,
      orElse: () => BorderStyle.solid,
    ),
  );
}

Map<String, dynamic> convertBorderSide(BorderSide side) {
  return {
    "color": convertHexColor(side.color),
    "width": side.width,
    "style": side.style.name,
  };
}

Radius parseRadius(dynamic radius) {
  if (radius == null) return Radius.zero;
  if (radius is num) return Radius.circular(radius.toDouble());
  if (radius is String) {
    final values = radius.split(':');
    if (values.length == 1) {
      return Radius.circular(parseDouble(radius) ?? 0);
    } else if (values.length == 2) {
      return Radius.elliptical(
        parseDouble(values[0]) ?? 0,
        parseDouble(values[1]) ?? 0,
      );
    }
  }
  return Radius.zero;
}

dynamic convertRadius(Radius radius) {
  if (radius == Radius.zero) return null;
  if (radius.x == radius.y) return radius.x;
  return '${radius.x}:${radius.y}';
}

// Ref: https://api.flutter.dev/flutter/animation/Curves-class.html
Curve parseCurve(String curvestr) {
  switch (curvestr) {
    case 'decelerate':
      return Curves.decelerate;
    case 'linear':
      return Curves.linear;
    case 'ease':
      return Curves.ease;

    case 'easeIn':
      return Curves.easeIn;
    case 'easeInSine':
      return Curves.easeInSine;
    case 'easeInQuad':
      return Curves.easeInQuad;
    case 'easeInCubic':
      return Curves.easeInCubic;
    case 'easeInQuart':
      return Curves.easeInQuart;
    case 'easeInQuint':
      return Curves.easeInQuint;
    case 'easeInExpo':
      return Curves.easeInExpo;
    case 'easeInCirc':
      return Curves.easeInCirc;
    case 'easeInBack':
      return Curves.easeInBack;

    case 'easeInOut':
      return Curves.easeInOut;
    case 'easeInOutSine':
      return Curves.easeInOutSine;
    case 'easeInOutQuad':
      return Curves.easeInOutQuad;
    case 'easeInOutCubic':
      return Curves.easeInOutCubic;
    case 'easeInOutQuart':
      return Curves.easeInOutQuart;
    case 'easeInOutQuint':
      return Curves.easeInOutQuint;
    case 'easeInOutExpo':
      return Curves.easeInOutExpo;
    case 'easeInOutCirc':
      return Curves.easeInOutCirc;
    case 'easeInOutBack':
      return Curves.easeInOutBack;

    case 'easeOut':
      return Curves.easeOut;
    case 'easeOutSine':
      return Curves.easeOutSine;
    case 'easeOutQuad':
      return Curves.easeOutQuad;
    case 'easeOutCubic':
      return Curves.easeOutCubic;
    case 'easeOutQuart':
      return Curves.easeOutQuart;
    case 'easeOutQuint':
      return Curves.easeOutQuint;
    case 'easeOutExpo':
      return Curves.easeOutExpo;
    case 'easeOutCirc':
      return Curves.easeOutCirc;
    case 'easeOutBack':
      return Curves.easeOutBack;

    case 'elasticIn':
      return Curves.elasticIn;
    case 'elasticInOut':
      return Curves.elasticInOut;
    case 'elasticOut':
      return Curves.elasticOut;

    case 'fastOutSlowIn':
      return Curves.fastOutSlowIn;
    case 'slowMiddle':
      return Curves.slowMiddle;

    case 'bounceIn':
      return Curves.bounceIn;
    case 'bounceInOut':
      return Curves.bounceInOut;
    case 'bounceOut':
      return Curves.bounceOut;
  }
  return Curves.decelerate;
}
