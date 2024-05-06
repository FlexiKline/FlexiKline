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

import '../constant.dart';

Decimal stringToDecimal(dynamic value) =>
    stringToDecimalOrNull(value) ?? Decimal.zero;

Decimal? stringToDecimalOrNull(dynamic value) {
  if (value == null) {
    return null;
  } else {
    return Decimal.tryParse(value.toString());
  }
}

String decimalToString(dynamic value) => value?.toString() ?? "";

String? decimalToStringOrNull(dynamic value) => value?.toString();

int valueToInt(dynamic value) {
  if (value is int) {
    return value;
  } else {
    return int.tryParse(value.toString()) ?? 0;
  }
}

String intToString(int value) {
  return value.toString();
}

DateTime? valueToDateTime(dynamic value) {
  if (value == null) {
    return null;
  } else if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  } else if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

int? dateTimeToInt(dynamic dateTime) {
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

Color parseHexColor(String? hexStr, {Color def = Colors.transparent}) {
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

String convertHexColor(Color? color, {String def = ''}) {
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

String convertFontWeight(FontWeight? fontWeight, {String def = 'normal'}) {
  if (fontWeight == null) return def;
  String weight = def;
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
    case FontWeight.normal:
      weight = 'normal';
      break;
    case FontWeight.bold:
      weight = 'bold';
      break;
    default:
      weight = def;
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
