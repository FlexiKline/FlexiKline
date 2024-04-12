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
