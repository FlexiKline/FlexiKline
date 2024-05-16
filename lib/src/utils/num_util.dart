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

import '../extension/export.dart';

String formatPercentage(
  double? val, {
  int precision = 2,
}) {
  if (val == null) return '0%';
  return formatNumber(
    (val * 100).d,
    precision: 2,
    suffix: '%',
  );
}

String compactBigNumber(Decimal val, {int precision = 2}) {
  if (val.abs() >= 1e9.d) {
    return '${(val / 1e9.d).toDecimal().toStringAsFixed(precision)}B';
  } else if (val.abs() >= 1e6.d) {
    return '${(val / 1e6.d).toDecimal().toStringAsFixed(precision)}M';
  } else if (val.abs() >= 1e3.d) {
    return '${(val / 1e3.d).toDecimal().toStringAsFixed(precision)}K';
  } else {
    return val.toStringAsFixed(precision);
  }
}

String twoDigits(int n) {
  if (n >= 10) return "$n";
  return "0$n";
}

/// 对value计算精度;
/// 如果isFloor为true, 向下截断
/// 如果isFloor为false, 向上截断
/// 如果为空, 四舍五入.
Decimal toFixed(
  Decimal val, {
  int precision = 0,
  bool? isFloor,
}) {
  if (isFloor != null) {
    if (isFloor) {
      val = val.floor(scale: precision);
    } else {
      val = val.ceil(scale: precision);
    }
    return val;
  }
  return val.round();
}

const decimalSeparator = '.';
const thousandSeparator = ',';

String formatNumber(
  Decimal? val, {
  int precision = 0, // 展示精度
  bool isSign = false, //是否展示符号位+
  bool? isFloor = true, // 默认为true: 向下截断, false:则向上, null: 四舍五入.
  bool cutInvalidZero = false, //删除尾部零.
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
  if (val == Decimal.zero && defIfZero != null) {
    return defIfZero;
  }

  String ret = "";
  if (isSign) {
    if (val > Decimal.zero) {
      ret += '+';
    } else if (val < Decimal.zero) {
      ret += '-';
    }
    val = val.abs();
  }
  ret += prefix;

  val = toFixed(val, isFloor: isFloor, precision: precision);

  if (showCompact) {
    ret += compactBigNumber(val);
  } else if (showThousands) {
    String number = val.toStringAsFixed(precision);
    String oldNum = number.split(decimalSeparator)[0];
    number = number.contains(decimalSeparator)
        ? decimalSeparator + number.split(decimalSeparator)[1]
        : '';
    for (int i = 0; i < oldNum.length; i++) {
      number = oldNum[oldNum.length - i - 1] + number;
      if ((i + 1) % 3 == 0 &&
          i < oldNum.length - (oldNum.startsWith('-') ? 2 : 1)) {
        number = thousandSeparator + number;
      }
    }
    ret += number;
  } else {
    ret += val.toStringAsFixed(precision);
  }

  if (cutInvalidZero) {
    // 如果包含点，则删除后面无效的0和.
    while (ret.contains('.') && (ret.endsWith('0') || ret.endsWith('.'))) {
      ret = ret.substring(0, ret.length - 1);
    }
  }

  ret += suffix;

  return ret;
}

/// 格式化价钱
String formatPrice(
  Decimal? val, {
  required int precision,
  bool cutInvalidZero = true,
  String? defIfZero,
}) {
  return formatNumber(
    val,
    precision: precision,
    defIfZero: defIfZero,
    cutInvalidZero: cutInvalidZero,
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
