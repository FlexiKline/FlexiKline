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
import 'package:flutter/widgets.dart';

import '../config/draw_config/draw_config.dart';
import '../core/interface.dart';
import '../framework/logger.dart';
import '../kline_controller.dart';
import '../model/gesture_data.dart';

class OverlayDrawGestureDetector extends StatefulWidget {
  const OverlayDrawGestureDetector({
    super.key,
    required this.controller,
    required this.isTouchDevice,
    this.child,
  });

  final FlexiKlineController controller;
  final bool isTouchDevice;
  final Widget? child;

  @override
  State<OverlayDrawGestureDetector> createState() =>
      _OverlayDrawGestureDetectorState();
}

class _OverlayDrawGestureDetectorState extends State<OverlayDrawGestureDetector>
    with KlineLog {
  /// Draw确认坐标事件
  GestureData? _tapData;
  GestureData? _panData;

  @override
  String get logTag => 'OverlayDrawGesture';

  IDraw get drawBinding => widget.controller;

  DrawConfig get drawConfig => widget.controller.drawConfig;

  @override
  void initState() {
    super.initState();
    loggerDelegate = widget.controller.loggerDelegate;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isTouchDevice) {
      return _buildTouchGestureDetector(context);
    } else {
      return _buildNonTouchGestureDetector(context);
    }
  }

  Widget _buildTouchGestureDetector(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: onTapUp,
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,

      /// 长按
      onLongPressStart: onLongPressStart,
      onLongPressMoveUpdate: onLongPressMoveUpdate,
      onLongPressEnd: onLongPressEnd,
      child: widget.child,
    );
  }

  Widget _buildNonTouchGestureDetector(BuildContext context) {
    return MouseRegion(
      onEnter: onEnter,
      onHover: onHover,
      onExit: onExit,
      child: GestureDetector(
        onTapUp: onTapUp,
        onPanUpdate: onPanUpdate,

        /// 长按
        onLongPressStart: onLongPressStart,
        onLongPressMoveUpdate: onLongPressMoveUpdate,
        onLongPressEnd: onLongPressEnd,
        child: widget.child,
      ),
    );
  }

  /// 点击 - 确认
  void onTapUp(TapUpDetails details) {
    logd("onTapUp details:$details");
    _tapData = GestureData.tap(details.localPosition);
    drawBinding.onConfirm(_tapData!);
  }

  /// 平移开始事件
  void onPanStart(DragStartDetails details) {
    _panData = GestureData.pan(details.localPosition);
  }

  /// 平移更新事件
  void onPanUpdate(DragUpdateDetails details) {
    logd('onPanUpdate $details');
    if (_panData == null) {
      return;
    }
    _panData!.update(details.localPosition);
    drawBinding.onDrawUpdate(_panData!);
  }

  /// 平移结束事件
  void onPanEnd(DragEndDetails details) {
    _panData?.end();
    _panData = null;
  }

  /// 鼠标Hover进入事件.
  void onEnter(PointerEnterEvent event) {
    logd('onEnter $event');
  }

  /// 鼠标Hover事件.
  /// onMouseHover _TransformedPointerHoverEvent#1614b(position: Offset(86.5, 343.6))
  void onHover(PointerHoverEvent event) {
    logd('onHover $event');
  }

  /// 鼠标Hover退出事件.
  void onExit(PointerExitEvent event) {
    logd('onExit $event');
  }

  /// 长按
  ///
  /// 如果当前已启动绘制(即选择了将要绘制的绘制工具), 但是又没有确认起始坐标点:
  ///   当手势识别为长按起动操作时, 即刻确认起始坐标(第一个点).
  ///   在后续[onLongPressMoveUpdate]中更新第二点坐标.
  ///   在最后[onLongPressEnd]结束时, 确诊第二点坐标.
  ///
  /// 长按起动
  void onLongPressStart(LongPressStartDetails details) {
    logd('onLongPressStart');
  }

  void onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    logd('onLongPressMoveUpdate');
  }

  void onLongPressEnd(LongPressEndDetails details) {
    logd('onLongPressEnd');
  }
}
