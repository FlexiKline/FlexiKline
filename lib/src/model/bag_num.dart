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

import '../constant.dart';

extension NumBagExt on num {
  BagNum toBagNum() => BagNum.fromNum(this);

  Decimal toDecimal() {
    if (this is int) return Decimal.fromInt(this as int);
    return Decimal.parse(toString());
  }
}

extension DecimalBagExt on Decimal {
  BagNum toBagNum() => BagNum.fromDecimal(this);
}

final class BagNumException implements Exception {
  final String message;
  const BagNumException([this.message = '']);
}

/// 自定义包装数字.
/// 主要用于指标数据计算, 适配精确模式(Decimal)和快速模式(fast mode)
class BagNum implements Comparable<BagNum> {
  const BagNum._(this._value);

  static const BagNum zero = BagNum._(0);
  static const BagNum one = BagNum._(1);
  static const BagNum two = BagNum._(2);
  static const BagNum three = BagNum._(3);
  static const BagNum ten = BagNum._(10);
  static const BagNum fifty = BagNum._(50);
  static const BagNum hundred = BagNum._(100);

  // @Deprecated('unsafe')
  // factory BagNum.form(dynamic value) => BagNum._(value);
  factory BagNum.fromDecimal(Decimal value) => BagNum._(value);
  factory BagNum.fromNum(num value) => BagNum._(value);
  factory BagNum.fromInt(num value) => BagNum._(value);

  final dynamic _value;

  Decimal toDecimal() {
    if (_value is Decimal) return _value;
    if (_value is int) return Decimal.fromInt(_value);
    if (_value is num) return Decimal.parse(_value.toString());
    throw const BagNumException('BagNum toDecimal Type not match!');
  }

  double toDouble() {
    if (_value is num) return _value.toDouble();
    if (_value is Decimal) return _value.toDouble();
    throw const BagNumException('BagNum toDouble Type not match!');
  }

  bool get isZero {
    if (_value is num) return _value == 0;
    if (_value is Decimal) return _value == Decimal.zero;
    throw const BagNumException('BagNum isZero Type not match!');
  }

  BagNum operator +(BagNum other) {
    if (_value is num) {
      if (other._value is num) {
        return BagNum._(_value + other._value);
      } else if (other._value is Decimal) {
        return BagNum._(_value + other._value.toDouble());
      }
    } else if (_value is Decimal) {
      if (other._value is Decimal) {
        return BagNum._(_value + other._value);
      } else if (other._value is num) {
        return BagNum._(_value + other._value.toDecimal());
      }
    }
    throw const BagNumException('BagNum operator + Type not match!');
  }

  BagNum operator -(BagNum other) {
    if (_value is num) {
      if (other._value is num) {
        return BagNum._(_value - other._value);
      } else if (other._value is Decimal) {
        return BagNum._(_value - other._value.toDouble());
      }
    } else if (_value is Decimal) {
      if (other._value is Decimal) {
        return BagNum._(_value - other._value);
      } else if (other._value is num) {
        return BagNum._(_value - other._value.toDecimal());
      }
    }
    throw const BagNumException('BagNum operator - Type not match!');
  }

  BagNum operator *(BagNum other) {
    if (_value is num) {
      if (other._value is num) {
        return BagNum._(_value * other._value);
      } else if (other._value is Decimal) {
        return BagNum._(_value * other._value.toDouble());
      }
    } else if (_value is Decimal) {
      if (other._value is Decimal) {
        return BagNum._(_value * other._value);
      } else if (other._value is num) {
        return BagNum._(_value * other._value.toDecimal());
      }
    }
    throw const BagNumException('BagNum operator * Type not match!');
  }

  BagNum operator /(BagNum other) {
    if (_value is num) {
      if (other._value is num) {
        return BagNum._(_value / other._value);
      } else if (other._value is Decimal) {
        return BagNum._(_value / other._value.toDouble());
      }
    } else if (_value is Decimal) {
      if (other._value is Decimal) {
        return BagNum._((_value / other._value).toDecimal(
          scaleOnInfinitePrecision: defaultScaleOnInfinitePrecision,
        ));
      } else if (other._value is num) {
        return BagNum._((_value / other._value.toDecimal()).toDecimal(
          scaleOnInfinitePrecision: defaultScaleOnInfinitePrecision,
        ));
      }
    }
    throw const BagNumException('BagNum operator / Type not match!');
  }

  BagNum operator %(BagNum other) {
    if (_value is num) {
      if (other._value is num) {
        return BagNum._(_value / other._value);
      } else if (other._value is Decimal) {
        return BagNum._(_value / other._value.toDouble());
      }
    } else if (_value is Decimal) {
      if (other._value is Decimal) {
        return BagNum._(_value + other._value);
      } else if (other._value is num) {
        return BagNum._(_value % other._value.toDecimal());
      }
    }
    throw const BagNumException('BagNum operator % Type not match!');
  }

  /// Whether this number is numerically smaller than [other].
  bool operator <(BagNum other) {
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
    throw const BagNumException('BagNum operator < Type not match!');
  }

  /// Whether this number is numerically smaller than or equal to [other].
  bool operator <=(BagNum other) {
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
    throw const BagNumException('BagNum operator <= Type not match!');
  }

  /// Whether this number is numerically greater than [other].
  bool operator >(BagNum other) {
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
    throw const BagNumException('BagNum operator > Type not match!');
  }

  /// Whether this number is numerically greater than or equal to [other].
  bool operator >=(BagNum other) {
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
    throw const BagNumException('BagNum operator >= Type not match!');
  }

  BagNum abs() {
    if (_value is double) {
      return BagNum._(_value.abs());
    } else if (_value is Decimal) {
      return BagNum._(_value.abs());
    }
    throw const BagNumException('BagNum operator abs Type not match!');
  }

  /// 加BagNum
  BagNum add(BagNum value) => this + value;

  /// 加Num
  BagNum addNum(num value) {
    if (_value is num) {
      return BagNum._(_value + value);
    } else if (_value is Decimal) {
      return BagNum._(_value + value.toDecimal());
    }
    throw const BagNumException('BagNum mulNum Type not match!');
  }

  /// 加Decimal
  BagNum addDecimal(Decimal value) {
    if (_value is num) {
      return BagNum._(_value + value.toDouble());
    } else if (_value is Decimal) {
      return BagNum._(_value + value);
    }
    throw const BagNumException('BagNum mulDecimal Type not match!');
  }

  /// 减去BagNum
  BagNum sub(BagNum value) => this - value;

  /// 减去Num
  BagNum subNum(num value) {
    if (_value is num) {
      return BagNum._(_value - value);
    } else if (_value is Decimal) {
      return BagNum._(_value - value.toDecimal());
    }
    throw const BagNumException('BagNum mulNum Type not match!');
  }

  /// 减去Decimal
  BagNum subDecimal(Decimal value) {
    if (_value is num) {
      return BagNum._(_value - value.toDouble());
    } else if (_value is Decimal) {
      return BagNum._(_value - value);
    }
    throw const BagNumException('BagNum mulDecimal Type not match!');
  }

  /// 乘以BagNum
  BagNum mul(BagNum value) => this * value;

  /// 乘以Num
  BagNum mulNum(num value) {
    if (_value is num) {
      return BagNum._(_value * value);
    } else if (_value is Decimal) {
      return BagNum._(_value * value.toDecimal());
    }
    throw const BagNumException('BagNum mulNum Type not match!');
  }

  /// 乘以Decimal
  BagNum mulDecimal(Decimal value) {
    if (_value is num) {
      return BagNum._(_value * value.toDouble());
    } else if (_value is Decimal) {
      return BagNum._(_value * value);
    }
    throw const BagNumException('BagNum mulDecimal Type not match!');
  }

  /// 除以BagNum
  BagNum div(BagNum value) => this / value;

  /// 除以Num
  BagNum divNum(num value) {
    if (_value is num) {
      return BagNum._(_value / value);
    } else if (_value is Decimal) {
      return BagNum._((_value / value.toDecimal()).toDecimal(
        scaleOnInfinitePrecision: defaultScaleOnInfinitePrecision,
      ));
    }
    throw const BagNumException('BagNum divNum Type not match!');
  }

  /// 除以Decimal
  BagNum divDecimal(Decimal value) {
    if (_value is num) {
      return BagNum._(_value / value.toDouble());
    } else if (_value is Decimal) {
      return BagNum._((_value / value).toDecimal(
        scaleOnInfinitePrecision: defaultScaleOnInfinitePrecision,
      ));
    }
    throw const BagNumException('BagNum divDecimal Type not match!');
  }

  /// 取余BagNum
  BagNum remainder(BagNum value) => this % value;

  /// 取余Num
  BagNum remainderNum(num value) {
    if (_value is num) {
      return BagNum._(_value % value);
    } else if (_value is Decimal) {
      return BagNum._(_value % value.toDecimal());
    }
    throw const BagNumException('BagNum remainderNum Type not match!');
  }

  /// 取余Decimal
  BagNum remainderDecimal(Decimal value) {
    if (_value is num) {
      return BagNum._(_value % value.toDouble());
    } else if (_value is Decimal) {
      return BagNum._(_value % value);
    }
    throw const BagNumException('BagNum remainderNum Type not match!');
  }

  /// 大于BagNum
  bool gt(BagNum value) => this > value;

  /// 大于num
  bool gtNum(num value) {
    if (_value is num) {
      return _value > value;
    } else if (_value is Decimal) {
      return _value > value.toDecimal();
    }
    throw const BagNumException('BagNum gtNum Type not match!');
  }

  /// 大于Decimal
  bool gtDecimal(Decimal value) {
    if (_value is num) {
      return _value > value.toDouble();
    } else if (_value is Decimal) {
      return _value > value;
    }
    throw const BagNumException('BagNum gtDecimal Type not match!');
  }

  /// 大于等于BagNum
  bool gte(BagNum value) => this >= value;

  /// 大于等于num
  bool gteNum(num value) {
    if (_value is num) {
      return _value >= value;
    } else if (_value is Decimal) {
      return _value >= value.toDecimal();
    }
    throw const BagNumException('BagNum gteNum Type not match!');
  }

  /// 大于等于Decimal
  bool gteDecimal(Decimal value) {
    if (_value is num) {
      return _value >= value.toDouble();
    } else if (_value is Decimal) {
      return _value >= value;
    }
    throw const BagNumException('BagNum gteDecimal Type not match!');
  }

  /// 小于BagNum
  bool lt(BagNum value) => this < value;

  /// 小于num
  bool ltNum(num value) {
    if (_value is num) {
      return _value < value;
    } else if (_value is Decimal) {
      return _value < value.toDecimal();
    }
    throw const BagNumException('BagNum ltNum Type not match!');
  }

  /// 小于Decimal
  bool ltDecimal(Decimal value) {
    if (_value is num) {
      return _value < value.toDouble();
    } else if (_value is Decimal) {
      return _value < value;
    }
    throw const BagNumException('BagNum ltDecimal Type not match!');
  }

  /// 小于等于BagNum
  bool lte(BagNum value) => this <= value;

  /// 小于等于num
  bool lteNum(num value) {
    if (_value is num) {
      return _value <= value;
    } else if (_value is Decimal) {
      return _value <= value.toDecimal();
    }
    throw const BagNumException('BagNum lteNum Type not match!');
  }

  /// 小于等于Decimal
  bool lteDecimal(Decimal value) {
    if (_value is num) {
      return _value <= value.toDouble();
    } else if (_value is Decimal) {
      return _value <= value;
    }
    throw const BagNumException('BagNum lteDecimal Type not match!');
  }

  /// Clamps `this` to be in the range [lowerLimit]-[upperLimit].
  BagNum clamp(BagNum lowerLimit, BagNum upperLimit) {
    if (_value is num) {
      final lowerNum = lowerLimit.toDouble();
      final upperNum = upperLimit.toDouble();
      return BagNum.fromNum(_value.clamp(lowerNum, upperNum));
    } else if (_value is Decimal) {
      final lowerNum = lowerLimit.toDecimal();
      final upperNum = upperLimit.toDecimal();
      return BagNum.fromDecimal(_value.clamp(lowerNum, upperNum));
    }
    throw const BagNumException('BagNum clamp Type not match!');
  }

  BagNum clampNum(num lowerLimit, num upperLimit) {
    if (_value is num) {
      return BagNum.fromNum(_value.clamp(lowerLimit, upperLimit));
    } else if (_value is Decimal) {
      final lowerNum = lowerLimit.toDecimal();
      final upperNum = upperLimit.toDecimal();
      return BagNum.fromDecimal(_value.clamp(lowerNum, upperNum));
    }
    throw const BagNumException('BagNum clampNum Type not match!');
  }

  BagNum clampDecimal(Decimal lowerLimit, Decimal upperLimit) {
    if (_value is num) {
      final lowerNum = lowerLimit.toDouble();
      final upperNum = upperLimit.toDouble();
      return BagNum.fromNum(_value.clamp(lowerNum, upperNum));
    } else if (_value is Decimal) {
      return BagNum.fromDecimal(_value.clamp(lowerLimit, upperLimit));
    }
    throw const BagNumException('BagNum clampDecimal Type not match!');
  }

  num get signum {
    if (_value is num) {
      return _value.sign;
    } else if (_value is Decimal) {
      return _value.signum;
    }
    throw const BagNumException('BagNum signum Type not match!');
  }

  BagNum floor({int scale = 0}) {
    if (_value is num) {
      final mod = math.pow(10, scale);
      return BagNum.fromNum((_value * mod).floor() / mod);
    } else if (_value is Decimal) {
      return BagNum.fromDecimal(_value.floor(scale: scale));
    }
    throw const BagNumException('BagNum floor Type not match!');
  }

  BagNum ceil({int scale = 0}) {
    if (_value is num) {
      final mod = math.pow(10, scale);
      return BagNum.fromNum((_value * mod).ceil() / mod);
    } else if (_value is Decimal) {
      return BagNum.fromDecimal(_value.ceil(scale: scale));
    }
    throw const BagNumException('BagNum ceil Type not match!');
  }

  BagNum round({int scale = 0}) {
    if (_value is num) {
      final mod = math.pow(10, scale);
      return BagNum.fromNum((_value * mod).round() / mod);
    } else if (_value is Decimal) {
      return BagNum.fromDecimal(_value.round(scale: scale));
    }
    throw const BagNumException('BagNum round Type not match!');
  }

  BagNum shift(int value) {
    if (_value is num) {
      return BagNum.fromNum(_value * math.pow(10, value));
    } else if (_value is Decimal) {
      return BagNum.fromDecimal(_value.shift(value));
    }
    throw const BagNumException('BagNum shift Type not match!');
  }

  @override
  int compareTo(BagNum other) {
    return _value.compareTo(other._value);
  }

  BagNum calcuMin(BagNum other) {
    if (this > other) return other;
    return this;
  }

  BagNum calcuMax(BagNum other) {
    if (this < other) return other;
    return this;
  }

  @override
  bool operator ==(Object other) => other is BagNum && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  @override
  String toString() {
    return 'BagNum:${doubleString()}';
  }

  String doubleString() {
    if (_value is Decimal) {
      return _value.toStringAsFixed(defaultScaleOnInfinitePrecision);
    }
    return _value.toString();
  }
}
