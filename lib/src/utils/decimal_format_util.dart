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

import '../constant.dart';
import '../extension/export.dart';

/// 百分比
String formatPercentage(
  double? val, {
  int precision = 2,
  String defIfNull = '-%', // 如果为空或无效值时的默认展示.
}) {
  if (val == null) return defIfNull;
  return formatNumber(
    (val * 100).d,
    precision: 2,
    suffix: '%',
  );
}

String twoDigits(int n) {
  if (n >= 10) return "$n";
  return "0$n";
}

String formatNumber(
  Decimal? val, {
  int precision = 0, // 展示精度
  bool showSign = false, //是否展示符号位+
  RoundMode? mode,
  bool cutInvalidZero = false, //删除尾部零.
  bool showCompact = false, // 是否压缩大数展示(T, B, M, K)
  bool showThousands = false, // 是否千分位展示; 优先于正常精度展示
  String prefix = '', // 前缀
  String suffix = '', // 后缀
  String? defIfZero, // 如果为0时的默认展示.
  String defIfNull = '--', // 如果为空或无效值时的默认展示.
}) {
  // 处理数据为空的情况
  if (val == null) return defIfNull;

  // 处理数据为0的情况
  if (val == Decimal.zero && defIfZero != null) {
    return defIfZero;
  }

  String ret = "";
  if (showSign && val >= Decimal.zero) prefix += '+';

  if (showCompact) {
    ret += val.compact(precision: precision, isClean: cutInvalidZero);
  } else if (showThousands) {
    ret += val.thousands(precision, mode: mode, isClean: cutInvalidZero);
  } else {
    ret += val.formatAsString(precision, mode: mode, isClean: cutInvalidZero);
  }

  return '$prefix$ret$suffix';
}

/// 格式化价钱
String formatPrice(
  Decimal? val, {
  required int precision,
  bool cutInvalidZero = true,
  bool showThousands = false,
  String? defIfZero,
}) {
  return formatNumber(
    val,
    precision: precision,
    defIfZero: defIfZero,
    cutInvalidZero: cutInvalidZero,
    showThousands: showThousands,
  );
}

/// 格式化数量
String formatAmount(
  Decimal? val, {
  int precision = 2,
  bool showCompact = true,
  bool cutInvalidZero = true,
  String? defIfZero,
}) {
  return formatNumber(
    val,
    precision: precision,
    defIfZero: defIfZero,
    cutInvalidZero: cutInvalidZero,
    showCompact: showCompact,
  );
}
