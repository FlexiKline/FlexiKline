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

import 'package:flutter/gestures.dart';

/// 图表专用长按识别器：在归属要求独占时让开竞技场。
///
/// [LongPressGestureRecognizer.didExceedDeadline] 会在 [kLongPressTimeout] 到点时
/// `resolve(accepted)`，把竞技场里的其他成员连同图表的 Scale 一起 reject。落点归属的移动
/// 已全部收敛到 `onScaleUpdate`，于是「手指按在目标上停顿半秒再拖」变成整段手势零响应。
///
/// 让开时自我 reject 而非继续等待：既然本次序列归某个落点归属，长按对它就没有语义；退出
/// 后 Tap 与 Scale 照常竞争，轻点仍是点击、越过抢占阈值即拖动。
class TouchLongPressGestureRecognizer extends LongPressGestureRecognizer {
  TouchLongPressGestureRecognizer({
    required this.shouldYieldToOwner,
    super.debugOwner,
  });

  /// 本次序列是否已归某个要求独占的归属。deadline 到点时求值，那时归属早已确定。
  final bool Function() shouldYieldToOwner;

  @override
  void didExceedDeadline() {
    if (shouldYieldToOwner()) {
      resolve(GestureDisposition.rejected);
      return;
    }
    super.didExceedDeadline();
  }

  @override
  String get debugDescription => 'touch long press';
}
