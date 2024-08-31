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

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../kline_controller.dart';

class OverlayDrawBox extends SingleChildRenderObjectWidget {
  const OverlayDrawBox({
    super.key,
    super.child,
    required this.controller,
  });

  final FlexiKlineController controller;

  @override
  RenderOverlayDrawBox createRenderObject(BuildContext context) {
    return RenderOverlayDrawBox(
      controller: controller,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderOverlayDrawBox renderObject,
  ) {
    renderObject._controller = controller;
  }
}

class RenderOverlayDrawBox extends RenderProxyBox {
  RenderOverlayDrawBox({
    required FlexiKlineController controller,
  }) : _controller = controller;

  FlexiKlineController _controller;
  FlexiKlineController get controller => _controller;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // TODO: 检查position位置是否命中到已绘制的Overlay.
    if (!controller.isDrawing) return false;
    return super.hitTest(result, position: position);
  }

  @override
  bool hitTestSelf(Offset position) {
    return controller.isDrawing;
  }
}
