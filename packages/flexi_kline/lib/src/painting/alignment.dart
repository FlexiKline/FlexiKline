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

import 'package:flutter/painting.dart';

extension AlignmentPlace on Alignment {
  /// 让 [size] 的本对齐点落在 [anchor] 上; 给了 [bounds] 就整体平移回其内。
  ///
  /// topLeft / topRight / topCenter 对应旧 DrawDirection 的 ltr / rtl / center;
  /// 调用点手算的 `dy - areaHeight / 2` 也由它表达, 且用实测高度而非估算。
  Rect place(Size size, Offset anchor, [Rect? bounds]) {
    final rect = (anchor - alongSize(size)) & size;
    if (bounds == null) return rect;
    // 外层 max 不可省: bounds 装不下时上下界会反, clamp 会抛异常。
    return Offset(
          math.max(bounds.left, math.min(rect.left, bounds.right - size.width)),
          math.max(bounds.top, math.min(rect.top, bounds.bottom - size.height)),
        ) &
        size;
  }
}
