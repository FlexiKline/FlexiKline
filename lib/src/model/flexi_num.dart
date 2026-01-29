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

import 'dart:math' as math;

import 'package:decimal/decimal.dart';
import 'package:flexi_formatter/flexi_formatter.dart';

import '../constant.dart';
import 'minmax.dart';

extension ListFlexiNumExt on List<FlexiNum?> {
  MinMax? get minmax {
    if (isEmpty) return null;
    return MinMax.getMinMaxByList(this);
  }
}

extension NumFlexiNumExt on num {
  FlexiNum toFlexiNum() => FlexiNum.fromNum(this);

  Decimal toDecimal() {
    if (this is int) return Decimal.fromInt(this as int);
    return Decimal.parse(toString());
  }
}

extension DecimalFlexiNumExt on Decimal {
  FlexiNum toFlexiNum() => FlexiNum.fromDecimal(this);
}

final class FlexiNumException implements Exception {
  final String message;
  const FlexiNumException([this.message = '']);
}

/// 自定义数值类型Wrapper.
/// 主要用于指标数据计算, 适配精确模式(Decimal)和快速模式(fast mode)
extension type FlexiNum._(Object _value) {
  static final FlexiNum minusHundred = FlexiNum._(-100);
  static final FlexiNum minusFifty = FlexiNum._(-50);
  static final FlexiNum minusTen = FlexiNum._(-10);
  static final FlexiNum minusThree = FlexiNum._(-3);
  static final FlexiNum minusTwo = FlexiNum._(-2);
  static final FlexiNum minusOne = FlexiNum._(-1);
  static final FlexiNum zero = FlexiNum._(0);
  static final FlexiNum one = FlexiNum._(1);
  static final FlexiNum two = FlexiNum._(2);
  static final FlexiNum three = FlexiNum._(3);
  static final FlexiNum ten = FlexiNum._(10);
  static final FlexiNum fifty = FlexiNum._(50);
  static final FlexiNum hundred = FlexiNum._(100);

  factory FlexiNum.fromDecimal(Decimal value) => FlexiNum._(value);
  factory FlexiNum.fromNum(num value) => FlexiNum._(value);
  factory FlexiNum.fromInt(int value) => FlexiNum._(value);
  factory FlexiNum.fromBigInt(BigInt value) => FlexiNum._(value.toDecimal());

  /// 从任意 Object 转换为 FlexiNum（根据计算模式）
  ///
  /// 支持类型：num | Decimal | String | BigInt
  /// [mode] 计算模式：fast 使用 double，accurate 使用 Decimal
  static FlexiNum fromAny(Object value, ComputeMode mode) {
    final isFastMode = mode == ComputeMode.fast;
    return switch (value) {
      final num v => isFastMode ? FlexiNum._(v) : FlexiNum._(v.toDecimal()),
      final Decimal v => isFastMode ? FlexiNum._(v.toDouble()) : FlexiNum._(v),
      final String v => isFastMode ? FlexiNum._(double.parse(v)) : FlexiNum._(Decimal.parse(v)),
      final BigInt v => isFastMode ? FlexiNum._(v.toDouble()) : FlexiNum._(v.toDecimal()),
      _ => throw FlexiNumException('Unsupported type: ${value.runtimeType}'),
    };
  }

  static FlexiNum? fromAnyOrNull(Object? value, ComputeMode mode) {
    if (value == null) return null;
    return fromAny(value, mode);
  }

  ComputeMode get mode {
    if (_value is num) return ComputeMode.fast;
    if (_value is Decimal) return ComputeMode.accurate;
    throw const FlexiNumException('FlexiNum mode Type not match!');
  }

  FlexiNum reset(ComputeMode mode) {
    return switch (mode) {
      ComputeMode.fast => FlexiNum._(toDouble()),
      ComputeMode.accurate => FlexiNum._(toDecimal()),
    };
  }

  Decimal toDecimal() {
    if (_value is Decimal) return _value;
    if (_value is int) return Decimal.fromInt(_value);
    if (_value is num) return Decimal.parse(_value.toString());
    throw const FlexiNumException('FlexiNum toDecimal Type not match!');
  }

  double toDouble() {
    if (_value is num) return _value.toDouble();
    if (_value is Decimal) return _value.toDouble();
    throw const FlexiNumException('FlexiNum toDouble Type not match!');
  }

  bool get isZero {
    if (_value is num) return _value == 0;
    if (_value is Decimal) return _value == Decimal.zero;
    throw const FlexiNumException('FlexiNum isZero Type not match!');
  }

  FlexiNum operator +(FlexiNum other) {
    if (_value is num) {
      if (other._value is num) {
        return FlexiNum._(_value + other._value);
      } else if (other._value is Decimal) {
        return FlexiNum._(_value + other._value.toDouble());
      }
    } else if (_value is Decimal) {
      if (other._value is Decimal) {
        return FlexiNum._(_value + other._value);
      } else if (other._value is num) {
        return FlexiNum._(_value + other._value.toDecimal());
      }
    }
    throw const FlexiNumException('FlexiNum operator + Type not match!');
  }

  FlexiNum operator -(FlexiNum other) {
    if (_value is num) {
      if (other._value is num) {
        return FlexiNum._(_value - other._value);
      } else if (other._value is Decimal) {
        return FlexiNum._(_value - other._value.toDouble());
      }
    } else if (_value is Decimal) {
      if (other._value is Decimal) {
        return FlexiNum._(_value - other._value);
      } else if (other._value is num) {
        return FlexiNum._(_value - other._value.toDecimal());
      }
    }
    throw const FlexiNumException('FlexiNum operator - Type not match!');
  }

  FlexiNum operator *(FlexiNum other) {
    if (_value is num) {
      if (other._value is num) {
        return FlexiNum._(_value * other._value);
      } else if (other._value is Decimal) {
        return FlexiNum._(_value * other._value.toDouble());
      }
    } else if (_value is Decimal) {
      if (other._value is Decimal) {
        return FlexiNum._(_value * other._value);
      } else if (other._value is num) {
        return FlexiNum._(_value * other._value.toDecimal());
      }
    }
    throw const FlexiNumException('FlexiNum operator * Type not match!');
  }

  FlexiNum operator /(FlexiNum other) {
    if (_value is num) {
      if (other._value is num) {
        return FlexiNum._(_value / other._value);
      } else if (other._value is Decimal) {
        return FlexiNum._(_value / other._value.toDouble());
      }
    } else if (_value is Decimal) {
      if (other._value is Decimal) {
        return FlexiNum._((_value / other._value).toDecimal(
          scaleOnInfinitePrecision: FlexiFormatter.scaleOnInfinitePrecision,
        ));
      } else if (other._value is num) {
        return FlexiNum._((_value / other._value.toDecimal()).toDecimal(
          scaleOnInfinitePrecision: FlexiFormatter.scaleOnInfinitePrecision,
        ));
      }
    }
    throw const FlexiNumException('FlexiNum operator / Type not match!');
  }

  FlexiNum operator %(FlexiNum other) {
    if (_value is num) {
      if (other._value is num) {
        return FlexiNum._(_value % other._value);
      } else if (other._value is Decimal) {
        return FlexiNum._(_value % other._value.toDouble());
      }
    } else if (_value is Decimal) {
      if (other._value is Decimal) {
        return FlexiNum._(_value % other._value);
      } else if (other._value is num) {
        return FlexiNum._(_value % other._value.toDecimal());
      }
    }
    throw const FlexiNumException('FlexiNum operator % Type not match!');
  }

  /// Whether this number is numerically smaller than [other].
  bool operator <(FlexiNum other) {
    if (_value is num) {
      if (other._value is num) {
        return _value < other._value;
      } else if (other._value is Decimal) {
        return _value < other._value.toDouble();
      }
    } else if (_value is Decimal) {
      if (other._value is Decimal) {
        return _value < other._value;
      } else if (other._value is num) {
        return _value < other._value.toDecimal();
      }
    }
    throw const FlexiNumException('FlexiNum operator < Type not match!');
  }

  /// Whether this number is numerically smaller than or equal to [other].
  bool operator <=(FlexiNum other) {
    if (_value is num) {
      if (other._value is num) {
        return _value <= other._value;
      } else if (other._value is Decimal) {
        return _value <= other._value.toDouble();
      }
    } else if (_value is Decimal) {
      if (other._value is Decimal) {
        return _value <= other._value;
      } else if (other._value is num) {
        return _value <= other._value.toDecimal();
      }
    }
    throw const FlexiNumException('FlexiNum operator <= Type not match!');
  }

  /// Whether this number is numerically greater than [other].
  bool operator >(FlexiNum other) {
    if (_value is num) {
      if (other._value is num) {
        return _value > other._value;
      } else if (other._value is Decimal) {
        return _value > other._value.toDouble();
      }
    } else if (_value is Decimal) {
      if (other._value is Decimal) {
        return _value > other._value;
      } else if (other._value is num) {
        return _value > other._value.toDecimal();
      }
    }
    throw const FlexiNumException('FlexiNum operator > Type not match!');
  }

  /// Whether this number is numerically greater than or equal to [other].
  bool operator >=(FlexiNum other) {
    if (_value is num) {
      if (other._value is num) {
        return _value >= other._value;
      } else if (other._value is Decimal) {
        return _value >= other._value.toDouble();
      }
    } else if (_value is Decimal) {
      if (other._value is Decimal) {
        return _value >= other._value;
      } else if (other._value is num) {
        return _value >= other._value.toDecimal();
      }
    }
    throw const FlexiNumException('FlexiNum operator >= Type not match!');
  }

  FlexiNum abs() {
    if (_value is num) {
      return FlexiNum._(_value.abs());
    } else if (_value is Decimal) {
      return FlexiNum._(_value.abs());
    }
    throw const FlexiNumException('FlexiNum operator abs Type not match!');
  }

  /// 加FlexiNum
  FlexiNum add(FlexiNum value) => this + value;

  /// 加Num
  FlexiNum addNum(num value) {
    if (_value is num) {
      return FlexiNum._(_value + value);
    } else if (_value is Decimal) {
      return FlexiNum._(_value + value.toDecimal());
    }
    throw const FlexiNumException('FlexiNum mulNum Type not match!');
  }

  /// 加Decimal
  FlexiNum addDecimal(Decimal value) {
    if (_value is num) {
      return FlexiNum._(_value + value.toDouble());
    } else if (_value is Decimal) {
      return FlexiNum._(_value + value);
    }
    throw const FlexiNumException('FlexiNum mulDecimal Type not match!');
  }

  /// 减去FlexiNum
  FlexiNum sub(FlexiNum value) => this - value;

  /// 减去Num
  FlexiNum subNum(num value) {
    if (_value is num) {
      return FlexiNum._(_value - value);
    } else if (_value is Decimal) {
      return FlexiNum._(_value - value.toDecimal());
    }
    throw const FlexiNumException('FlexiNum mulNum Type not match!');
  }

  /// 减去Decimal
  FlexiNum subDecimal(Decimal value) {
    if (_value is num) {
      return FlexiNum._(_value - value.toDouble());
    } else if (_value is Decimal) {
      return FlexiNum._(_value - value);
    }
    throw const FlexiNumException('FlexiNum mulDecimal Type not match!');
  }

  /// 乘以FlexiNum
  FlexiNum mul(FlexiNum value) => this * value;

  /// 乘以Num
  FlexiNum mulNum(num value) {
    if (_value is num) {
      return FlexiNum._(_value * value);
    } else if (_value is Decimal) {
      return FlexiNum._(_value * value.toDecimal());
    }
    throw const FlexiNumException('FlexiNum mulNum Type not match!');
  }

  /// 乘以Decimal
  FlexiNum mulDecimal(Decimal value) {
    if (_value is num) {
      return FlexiNum._(_value * value.toDouble());
    } else if (_value is Decimal) {
      return FlexiNum._(_value * value);
    }
    throw const FlexiNumException('FlexiNum mulDecimal Type not match!');
  }

  /// 除以FlexiNum
  FlexiNum div(FlexiNum value) => this / value;

  /// 除以Num
  FlexiNum divNum(num value) {
    if (_value is num) {
      return FlexiNum._(_value / value);
    } else if (_value is Decimal) {
      return FlexiNum._((_value / value.toDecimal()).toDecimal(
        scaleOnInfinitePrecision: FlexiFormatter.scaleOnInfinitePrecision,
      ));
    }
    throw const FlexiNumException('FlexiNum divNum Type not match!');
  }

  /// 除以Decimal
  FlexiNum divDecimal(Decimal value) {
    if (_value is num) {
      return FlexiNum._(_value / value.toDouble());
    } else if (_value is Decimal) {
      return FlexiNum._((_value / value).toDecimal(
        scaleOnInfinitePrecision: FlexiFormatter.scaleOnInfinitePrecision,
      ));
    }
    throw const FlexiNumException('FlexiNum divDecimal Type not match!');
  }

  /// 除以FlexiNum, 如果value为0, 则返回def, 否则返回this / value
  /// [def] 默认值
  FlexiNum divSafe(FlexiNum value, [FlexiNum? def]) {
    if (value.isZero) return def ?? FlexiNum.zero;
    return div(value);
  }

  /// 除以Num, 如果value为0, 则返回def, 否则返回this / value
  /// [def] 默认值
  FlexiNum divSafeNum(num value, [num? def]) {
    if (value == 0) return def != null ? FlexiNum.fromNum(def) : FlexiNum.zero;
    return divNum(value);
  }

  /// 除以Decimal, 如果value为0, 则返回def, 否则返回this / value
  /// [def] 默认值
  FlexiNum divSafeDecimal(Decimal value, [Decimal? def]) {
    if (value == Decimal.zero) return def != null ? FlexiNum.fromDecimal(def) : FlexiNum.zero;
    return divDecimal(value);
  }

  /// 取余FlexiNum
  FlexiNum remainder(FlexiNum value) => this % value;

  /// 取余Num
  FlexiNum remainderNum(num value) {
    if (_value is num) {
      return FlexiNum._(_value % value);
    } else if (_value is Decimal) {
      return FlexiNum._(_value % value.toDecimal());
    }
    throw const FlexiNumException('FlexiNum remainderNum Type not match!');
  }

  /// 取余Decimal
  FlexiNum remainderDecimal(Decimal value) {
    if (_value is num) {
      return FlexiNum._(_value % value.toDouble());
    } else if (_value is Decimal) {
      return FlexiNum._(_value % value);
    }
    throw const FlexiNumException('FlexiNum remainderNum Type not match!');
  }

  /// 大于FlexiNum
  bool gt(FlexiNum value) => this > value;

  /// 大于num
  bool gtNum(num value) {
    if (_value is num) {
      return _value > value;
    } else if (_value is Decimal) {
      return _value > value.toDecimal();
    }
    throw const FlexiNumException('FlexiNum gtNum Type not match!');
  }

  /// 大于Decimal
  bool gtDecimal(Decimal value) {
    if (_value is num) {
      return _value > value.toDouble();
    } else if (_value is Decimal) {
      return _value > value;
    }
    throw const FlexiNumException('FlexiNum gtDecimal Type not match!');
  }

  /// 大于等于FlexiNum
  bool gte(FlexiNum value) => this >= value;

  /// 大于等于num
  bool gteNum(num value) {
    if (_value is num) {
      return _value >= value;
    } else if (_value is Decimal) {
      return _value >= value.toDecimal();
    }
    throw const FlexiNumException('FlexiNum gteNum Type not match!');
  }

  /// 大于等于Decimal
  bool gteDecimal(Decimal value) {
    if (_value is num) {
      return _value >= value.toDouble();
    } else if (_value is Decimal) {
      return _value >= value;
    }
    throw const FlexiNumException('FlexiNum gteDecimal Type not match!');
  }

  /// 小于FlexiNum
  bool lt(FlexiNum value) => this < value;

  /// 小于num
  bool ltNum(num value) {
    if (_value is num) {
      return _value < value;
    } else if (_value is Decimal) {
      return _value < value.toDecimal();
    }
    throw const FlexiNumException('FlexiNum ltNum Type not match!');
  }

  /// 小于Decimal
  bool ltDecimal(Decimal value) {
    if (_value is num) {
      return _value < value.toDouble();
    } else if (_value is Decimal) {
      return _value < value;
    }
    throw const FlexiNumException('FlexiNum ltDecimal Type not match!');
  }

  /// 小于等于FlexiNum
  bool lte(FlexiNum value) => this <= value;

  /// 小于等于num
  bool lteNum(num value) {
    if (_value is num) {
      return _value <= value;
    } else if (_value is Decimal) {
      return _value <= value.toDecimal();
    }
    throw const FlexiNumException('FlexiNum lteNum Type not match!');
  }

  /// 小于等于Decimal
  bool lteDecimal(Decimal value) {
    if (_value is num) {
      return _value <= value.toDouble();
    } else if (_value is Decimal) {
      return _value <= value;
    }
    throw const FlexiNumException('FlexiNum lteDecimal Type not match!');
  }

  /// Clamps `this` to be in the range [lowerLimit]-[upperLimit].
  FlexiNum clamp(FlexiNum lowerLimit, FlexiNum upperLimit) {
    if (_value is num) {
      final lowerNum = lowerLimit.toDouble();
      final upperNum = upperLimit.toDouble();
      return FlexiNum.fromNum(_value.clamp(lowerNum, upperNum));
    } else if (_value is Decimal) {
      final lowerNum = lowerLimit.toDecimal();
      final upperNum = upperLimit.toDecimal();
      return FlexiNum.fromDecimal(_value.clamp(lowerNum, upperNum));
    }
    throw const FlexiNumException('FlexiNum clamp Type not match!');
  }

  FlexiNum clampNum(num lowerLimit, num upperLimit) {
    if (_value is num) {
      return FlexiNum.fromNum(_value.clamp(lowerLimit, upperLimit));
    } else if (_value is Decimal) {
      final lowerNum = lowerLimit.toDecimal();
      final upperNum = upperLimit.toDecimal();
      return FlexiNum.fromDecimal(_value.clamp(lowerNum, upperNum));
    }
    throw const FlexiNumException('FlexiNum clampNum Type not match!');
  }

  FlexiNum clampDecimal(Decimal lowerLimit, Decimal upperLimit) {
    if (_value is num) {
      final lowerNum = lowerLimit.toDouble();
      final upperNum = upperLimit.toDouble();
      return FlexiNum.fromNum(_value.clamp(lowerNum, upperNum));
    } else if (_value is Decimal) {
      return FlexiNum.fromDecimal(_value.clamp(lowerLimit, upperLimit));
    }
    throw const FlexiNumException('FlexiNum clampDecimal Type not match!');
  }

  num get signum {
    if (_value is num) {
      return _value.sign;
    } else if (_value is Decimal) {
      return _value.signum;
    }
    throw const FlexiNumException('FlexiNum signum Type not match!');
  }

  FlexiNum floor({int scale = 0}) {
    if (_value is num) {
      final mod = math.pow(10, scale);
      return FlexiNum.fromNum((_value * mod).floor() / mod);
    } else if (_value is Decimal) {
      return FlexiNum.fromDecimal(_value.floor(scale: scale));
    }
    throw const FlexiNumException('FlexiNum floor Type not match!');
  }

  FlexiNum ceil({int scale = 0}) {
    if (_value is num) {
      final mod = math.pow(10, scale);
      return FlexiNum.fromNum((_value * mod).ceil() / mod);
    } else if (_value is Decimal) {
      return FlexiNum.fromDecimal(_value.ceil(scale: scale));
    }
    throw const FlexiNumException('FlexiNum ceil Type not match!');
  }

  FlexiNum round({int scale = 0}) {
    if (_value is num) {
      final mod = math.pow(10, scale);
      return FlexiNum.fromNum((_value * mod).round() / mod);
    } else if (_value is Decimal) {
      return FlexiNum.fromDecimal(_value.round(scale: scale));
    }
    throw const FlexiNumException('FlexiNum round Type not match!');
  }

  FlexiNum shift(int value) {
    if (_value is num) {
      return FlexiNum.fromNum(_value * math.pow(10, value));
    } else if (_value is Decimal) {
      return FlexiNum.fromDecimal(_value.shift(value));
    }
    throw const FlexiNumException('FlexiNum shift Type not match!');
  }

  FlexiNum calcuMin(FlexiNum other) {
    if (this > other) return other;
    return this;
  }

  FlexiNum calcuMax(FlexiNum other) {
    if (this < other) return other;
    return this;
  }

  String valueString() {
    if (_value is Decimal) {
      return _value.toStringAsFixed(FlexiFormatter.scaleOnInfinitePrecision);
    }
    return _value.toString();
  }
}
