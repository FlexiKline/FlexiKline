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

import './overlay.dart';

/// 图形绘制层状态
/// 1. prepared   准备就绪
/// 2. drawing    绘制中(overlay中points部分有值, 但未完成)
/// 3. modifying  修改中(overlay中points所有值都有, 修复中)
/// 4. exited     退出
///
/// 状态流转
/// prepared -> drawing -> modifying -> exited
sealed class DrawState {
  const DrawState(this.overlay);

  final Overlay? overlay;

  factory DrawState.prepared() => const Prepared();

  factory DrawState.exited() => const Exited();

  factory DrawState.draw(Overlay overlay) {
    assert(overlay.isInitial, 'Overlay is not initialized!');
    return Drawing(overlay);
  }

  factory DrawState.edit(Overlay overlay) {
    assert(overlay.isEditing, 'Overlay is not finished drawing');
    return Editing(overlay);
  }

  Point? get pointer => overlay?.pointer;
  bool get isExited => this is Exited;
  bool get isPrepared => this is Prepared;
  bool get isDrawing => this is Drawing;
  bool get isEditing => this is Editing;
  bool get isOngoing {
    return overlay != null && (isDrawing || isEditing);
  }
}

class Prepared extends DrawState {
  const Prepared() : super(null);
}

class Drawing extends DrawState {
  Drawing(super.overlay);
  DrawObject? object;
}

class Editing extends DrawState {
  const Editing(super.overlay);
}

class Exited extends DrawState {
  const Exited() : super(null);
}
