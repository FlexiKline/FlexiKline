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

import 'package:flutter/painting.dart';

/// 外延在 body 之外、且依赖锚点的形状(带箭头的气泡、单侧收口的标签等)。
///
/// 宿主实现它即可接入 LabelPainter 的摆放与夹取, 不需要改框架。
abstract class AnchoredBorder extends ShapeBorder {
  const AnchoredBorder();

  /// 形状在 body 之外占的空间, 参与摆放与边界夹取。
  EdgeInsets get outsets;

  /// 返回对准 [anchor] 的形状; [anchor] 相对 body(即 getOuterPath 收到的 rect)的左上角。
  ///
  /// body 被夹取平移后锚点可能落在可放置区间外, 实现须自己把箭头夹进去。
  /// 路径必须按 rect 相对计算, 这样阴影平移 rect 时箭头跟着平移。
  ShapeBorder anchorTo(Offset anchor);
}
