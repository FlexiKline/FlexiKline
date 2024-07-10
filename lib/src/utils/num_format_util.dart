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

import '../constant.dart';
import '../extension/num_ext.dart';

/// 百分比
String formatNumPercentage(
  double? val, {
  int precision = 2,
  String defIfNull = '-%', // 如果为空或无效值时的默认展示.
}) {
  if (val == null) return '-%';
  return formatNum(
    val * 100,
    precision: 2,
    suffix: '%',
  );
}

/// 统一的格式化数字函数
String formatNum(
  num? val, {
  int precision = 0, // 展示精度
  bool showSign = false, //是否展示符号位+
  RoundMode? mode, // 注: 在超过有效位数后会精度丢失.
  bool isClean = false, // 是否清理尾部零.
  bool showCompact = false, // 是否压缩大数展示(B, M, K)
  bool showThousands = false, // 是否千分位展示; 优先于正常精度展示
  String prefix = '', // 前缀
  String suffix = '', // 后缀
  String? defIfZero, // 如果为0时的默认展示.
  String defIfNull = '--', // 如果为空或无效值时的默认展示.
}) {
  // 处理数据为空的情况
  if (val == null) return defIfNull;

  // 处理数据为0的情况
  if (val == 0 && defIfZero != null) {
    return defIfZero;
  }

  String ret = "";
  if (showSign && val >= 0) prefix += '+';

  if (showCompact) {
    ret = val.compact(precision: precision, isClean: isClean);
  } else if (showThousands) {
    ret = val.thousands(precision, mode: mode, isClean: isClean);
  } else {
    ret = val.formatAsString(precision, mode: mode, isClean: isClean);
  }

  return '$prefix$ret$suffix';
}

/// 格式化价钱
String formatNumPrice(
  double? val, {
  required int precision,
  RoundMode? mode,
  bool isClean = true,
  bool showThousands = false,
  String? defIfZero,
}) {
  return formatNum(
    val,
    precision: precision,
    mode: mode,
    defIfZero: defIfZero,
    isClean: isClean,
    showThousands: showThousands,
  );
}

/// 格式化数量
String formatNumAmount(
  double? val, {
  int precision = 2,
  RoundMode? mode,
  bool showCompact = true,
  bool isClean = true,
  String? defIfZero,
}) {
  return formatNum(
    val,
    precision: precision,
    mode: mode,
    defIfZero: defIfZero,
    isClean: isClean,
    showCompact: showCompact,
  );
}
