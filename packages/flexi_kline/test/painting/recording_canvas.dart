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

import 'dart:ui';

/// 记录绘制调用的 [Canvas] 替身。
///
/// 容器类绘制扩展的实际落点读不全: `drawText` 只返回 [Size], `drawRectBackground` 只返回
/// 矫正后的原点。用它捕获背景路径、文本段落与图片的真实坐标, 以便断言边界矫正结果。
///
/// 经 [noSuchMethod] 吞掉全部调用, 因此不随 [Canvas] 接口增减方法而失效; 代价是只有下面
/// 显式暴露的几类调用可读, 其余需自行从 [invocations] 取。
class RecordingCanvas implements Canvas {
  /// 按调用顺序记录的全部调用。
  final List<Invocation> invocations = <Invocation>[];

  /// 全部 `drawPath` 的路径包围盒。
  ///
  /// 容器背景与边框共用一条路径, 传了背景色或边框时各产生一次调用, 包围盒即容器区域。
  List<Rect> get pathBounds => _argsOf(#drawPath).map((args) => (args[0] as Path).getBounds()).toList();

  /// 全部 `drawRRect` 的圆角矩形外接区域。
  List<Rect> get rrectBounds => _argsOf(#drawRRect).map((args) => (args[0] as RRect).outerRect).toList();

  /// 全部 `drawParagraph` 的绘制原点, 即文本左上角。
  List<Offset> get paragraphOffsets => _argsOf(#drawParagraph).map((args) => args[1] as Offset).toList();

  /// 全部 `drawImageRect` 的目标区域。
  List<Rect> get imageDstRects => _argsOf(#drawImageRect).map((args) => args[2] as Rect).toList();

  /// 指定方法的调用次数。
  int countOf(Symbol member) => _argsOf(member).length;

  void clear() => invocations.clear();

  Iterable<List<Object?>> _argsOf(Symbol member) =>
      invocations.where((i) => i.memberName == member).map((i) => i.positionalArguments);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    invocations.add(invocation);
    return null;
  }
}
