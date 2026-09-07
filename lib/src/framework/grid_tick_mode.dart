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

/// 网格线与刻度的取位方式。
///
/// 每个模式自带它唯一需要的参数, 而不是共用一个数值字段: 三种模式下参数的量纲不同
/// (间隔数 / 像素 / 间隔数), 共用一个字段会让「把像素填进 nice」这类错误在运行时才显形。
///
/// 横竖两个方向共用本类型。竖线遇 [GridNiceTickMode] 退化为 [GridCountTickMode] 并
/// assert —— 竖线是几何参考线, 永不按值取整。
sealed class GridTickMode {
  const GridTickMode();

  /// 按长度等分, [GridCountTickMode.divisions] 是间隔数。
  const factory GridTickMode.count(int divisions) = GridCountTickMode;

  /// 按固定像素间距切分, 余量平分两端。
  const factory GridTickMode.size(double spacing) = GridSizeTickMode;

  /// 按 nice-number 取整刻度值, 位置由值换算。
  const factory GridTickMode.nice({int targetDivisions}) = GridNiceTickMode;

  /// 反序列化遇到未知模式时的回落值。
  ///
  /// 取 count 而不是 nice: 它在横竖两个方向上都成立, 且位置不依赖任何值区间。
  static const fallback = GridCountTickMode(5);

  /// 模式标识, 同时是序列化的 `type` 字段。
  String get type;
}

/// 按长度等分。
final class GridCountTickMode extends GridTickMode {
  const GridCountTickMode(this.divisions);

  /// 间隔数。轴长被切成 [divisions] 段, 内部线条数因此是 `divisions - 1`。
  final int divisions;

  @override
  String get type => 'count';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is GridCountTickMode && divisions == other.divisions;

  @override
  int get hashCode => Object.hash(type, divisions);
}

/// 按固定像素间距切分, 余量平分两端(即整体居中)。
///
/// 位置精确按 [spacing] 排布, 不为了整除而调整间距 —— 那会让不同高度的 pane 呈现不同间距,
/// 本模式随之失去意义。装不下一格时不产出任何位置。
///
/// **刻度值仍由 `dyToValue` 从位置反算, 不产出「好读的数」**, 与 [GridCountTickMode] 同一
/// 缺点。想要「好读的值 + 大致固定的间距」, 用 [GridNiceTickMode] 并按 pane 高度换算
/// [GridNiceTickMode.targetDivisions]。
final class GridSizeTickMode extends GridTickMode {
  const GridSizeTickMode(this.spacing);

  /// 相邻两条线的像素间距。非正或非有限时不产出任何位置。
  final double spacing;

  @override
  String get type => 'size';

  @override
  bool operator ==(Object other) => identical(this, other) || other is GridSizeTickMode && spacing == other.spacing;

  @override
  int get hashCode => Object.hash(type, spacing);
}

/// 按 nice-number 取整刻度值, 位置由值换算。
///
/// 值好读, 数量在 [targetDivisions] 附近浮动。区间不可用时退化为 [GridCountTickMode]。
final class GridNiceTickMode extends GridTickMode {
  const GridNiceTickMode({this.targetDivisions = 5});

  /// 目标间隔数。步长要取整到好读的档位, 实际刻度数在它附近浮动。
  final int targetDivisions;

  @override
  String get type => 'nice';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is GridNiceTickMode && targetDivisions == other.targetDivisions;

  @override
  int get hashCode => Object.hash(type, targetDivisions);
}
