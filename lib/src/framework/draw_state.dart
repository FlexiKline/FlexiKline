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

import '../core/export.dart';
import './overlay.dart';
import 'common.dart';

/// 图形绘制层状态
/// 1. prepared   准备就绪
/// 2. started    开始绘制(overlay中points为空)
/// 3. drawing    绘制中(overlay中points部分有值, 但未完成)
/// 4. modifying  修改中(overlay中points所有值都有, 修复中)
/// 5. exited     退出
///
/// 状态流转
/// prepared -> started -> drawing -> modifying -> exited
sealed class DrawState {
  const DrawState(this.overlay);

  final Overlay? overlay;

  factory DrawState.prepared() => const Prepared();

  factory DrawState.exited() => const Exited();

  factory DrawState.start(IDrawType type, IDraw drawBinding) {
    return Started(type.createOverlay(drawBinding));
  }

  factory DrawState.edit(Overlay overlay) {
    if (overlay.isStarted) {
      return Started(overlay);
    } else if (overlay.isModfying) {
      return Modifying(overlay);
    } else {
      return Drawing(overlay);
    }
  }

  bool get isExited => this is Exited;
  bool get isPrepared => this is Prepared;
  bool get isStarted => this is Started;
  bool get isDrawing => this is Drawing;
  bool get isModifying => this is Modifying;
  bool get isEditing {
    return overlay != null && isStarted && isDrawing && isModifying;
  }
}

class Prepared extends DrawState {
  const Prepared() : super(null);
}

class Started extends DrawState {
  const Started(super.overlay);
}

class Drawing extends DrawState {
  const Drawing(super.overlay);
}

class Modifying extends DrawState {
  const Modifying(super.overlay);
}

class Exited extends DrawState {
  const Exited() : super(null);
}
