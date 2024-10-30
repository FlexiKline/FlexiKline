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

const drawObjectDefaultZIndex = 0;

typedef DrawObjectBuilder<T extends Overlay, R extends DrawObject<T>> = R
    Function(T overlay, DrawConfig config);

abstract interface class IDrawType {
  int get steps;
  String get id;
  String get groupId;
}

/// 自定义绘制类型
final class FlexiDrawType implements IDrawType {
  const FlexiDrawType(
    this.id,
    this.steps, {
    String? groupId,
  }) : groupId = groupId ?? drawGroupUnknown;

  @override
  final String groupId;

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

const String drawGroupUnknown = 'unknown';
const String drawGroupLines = 'lines';
const String drawGroupProjection = 'projection';
const String drawGroupFibonacci = 'fibonacci';
const String drawGroupPatterns = 'patterns';

enum DrawType implements IDrawType {
  // 单线
  trendLine(drawGroupLines, 2), // 趋势线
  arrowLine(drawGroupLines, 2), // 箭头
  extendedTrendLine(drawGroupLines, 2), // 延长趋势线
  trendAngle(drawGroupLines, 2), // 趋势线角度
  rayLine(drawGroupLines, 2), // 射线
  horizontalTrendLine(drawGroupLines, 2), // 水平趋势线
  horizontalRayLine(drawGroupLines, 2), // 水平射线
  horizontalLine(drawGroupLines, 1), // 水平线
  verticalLine(drawGroupLines, 1), // 垂直线
  crossLine(drawGroupLines, 1), // 十字线
  priceLine(drawGroupUnknown, 1), // 价钱线
  // 多线
  rectangle(drawGroupProjection, 2), // 长方形
  parallelChannel(drawGroupProjection, 3), // 平行通道
  // parallelLines, // 平行直线
  fibRetracement(drawGroupPatterns, 2), // 斐波那契回撤
  fibExpansion(drawGroupPatterns, 3), // 斐波那契扩展
  fibFans(drawGroupPatterns, 2); // 斐波那契扇形

  const DrawType(this.groupId, this.steps);
  @override
  final String groupId;

  @override
  String get id => name;

  @override
  final int steps;
}

enum MagnetMode {
  normal,
  weak,
  strong;

  MagnetMode get next {
    switch (this) {
      case MagnetMode.normal:
        return MagnetMode.weak;
      case MagnetMode.weak:
        return MagnetMode.strong;
      case MagnetMode.strong:
        return MagnetMode.normal;
    }
  }

  /// 排除[strong]类型
  MagnetMode get next2 {
    switch (this) {
      case MagnetMode.normal:
        return MagnetMode.weak;
      case MagnetMode.weak:
        return MagnetMode.normal;
      case MagnetMode.strong:
        return MagnetMode.normal;
    }
  }

  bool get isNormal => this == MagnetMode.normal;
  bool get isWeak => this == MagnetMode.weak;
  bool get isStrong => this == MagnetMode.strong;
}
