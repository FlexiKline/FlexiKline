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

part of 'overlay.dart';

typedef DrawObjectBuilder<T extends Overlay, R extends DrawObject<T>> = R
    Function(T overlay);

abstract interface class IDrawType {
  int get steps;
  String get id;
}

/// 自定义绘制类型
final class FlexiDrawType implements IDrawType {
  const FlexiDrawType(this.id, this.steps);
  @override
  final String id;
  @override
  final int steps;

  @override
  bool operator ==(Object other) {
    // if (identical(this, other)) return true;
    return other is FlexiDrawType &&
        runtimeType == other.runtimeType &&
        id == other.id &&
        steps == other.steps;
  }

  @override
  int get hashCode {
    return runtimeType.hashCode ^ id.hashCode ^ steps.hashCode;
  }
}

const unknownDrawType = FlexiDrawType('unknown', 0);

enum DrawType implements IDrawType {
  // 单线
  trendLine(2), // 趋势线
  arrowLine(2), // 箭头
  extendedTrendLine(2), // 延长趋势线
  trendAngle(2), // 趋势线角度
  rayLine(2), // 射线
  horizontalTrendLine(2), // 水平趋势线
  horizontalRayLine(2), // 水平射线
  horizontalLine(1), // 水平线
  verticalLine(1), // 垂直线
  crossLine(1), // 十字线
  priceLine(1), // 价钱线
  // 多线
  rectangle(2), // 长方形
  parallelChannel(3), // 平行通道
  // parallelLines, // 平行直线
  fibRetracement(2), // 斐波那契回撤
  fibExpansion(3), // 斐波那契扩展
  fibFans(2); // 斐波那契扇形

  const DrawType(this.steps);

  @override
  final int steps;

  @override
  String get id => name;
}

enum MagnetMode {
  normal,
  weakMagnet,
  strongMagnet;
}
