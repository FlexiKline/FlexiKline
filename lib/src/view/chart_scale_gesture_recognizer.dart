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

/// 图表专用 Scale 识别器：由上层判定落点归属，本类只负责抢占手势竞技场。
///
/// 单指 pan 的 [ScaleGestureRecognizer] 接受阈值是 `panSlop`，而
/// [DeviceGestureSettings.panSlop] 是 `touchSlop * 2` 的派生 getter，外层 Scrollable 的
/// [VerticalDragGestureRecognizer] 读的正是同一个 `touchSlop`。也就是说图表的阈值恒为
/// 外层的两倍，同一 [MediaQuery] 作用域下单指拖动必输——这是恒等关系而非数值巧合，
/// 无法通过调参解决。本类在上层确认存在落点归属后，把阈值降到 [_claimSlop] 并显式
/// [resolve]，抢在外层之前胜出。
///
/// 没有落点归属时不做任何干预：空白区拖动仍归外层滚动。
class ChartScaleGestureRecognizer extends ScaleGestureRecognizer {
  ChartScaleGestureRecognizer({
    required this.shouldClaimImmediately,
    required this.shouldClaimOnSlop,
    required this.claimSlopFactor,
    super.debugOwner,
  }) : assert(
          claimSlopFactor > 0 && claimSlopFactor < 1,
          'claimSlopFactor 必须落在 (0, 1) 内: 取 0 会抢掉手柄上的点击, '
          '取 >= 1 会晚于外层 Scrollable 的裁决',
        );

  /// 是否在 PointerDown 阶段立即抢占。只用于 zoom slider 专属区域。
  final bool Function(Offset localPosition) shouldClaimImmediately;

  /// 第一指位移超过 [_claimSlop] 后是否抢占。
  final bool Function() shouldClaimOnSlop;

  /// 抢占阈值相对外层 hitSlop 的比例，取值 (0, 1)。
  final double claimSlopFactor;

  /// 抢占阈值。
  ///
  /// 必须相对外层 Scrollable 的实际 hitSlop 派生，不能写死像素值：Android 平台提供的
  /// `touchSlop` 常小于 [kTouchSlop]，写死的值会在部分设备上大于外层阈值而抢占失败，
  /// 且快速滑动能抢到、慢速拖动抢不到，表现为时灵时不灵。
  ///
  /// 这里读的 [gestureSettings] 与外层 Scrollable 同源（同一 [MediaQuery] 作用域），
  /// 前提是它被正确注入——[RawGestureDetector] 不会像 [GestureDetector] 那样自动注入。
  double get _claimSlop => (gestureSettings?.touchSlop ?? kTouchSlop) * claimSlopFactor;

  /// 本轮手势的第一指。
  int? _primaryPointer;

  /// [_primaryPointer] 按下时的全局位置，用于算抢占位移。
  Offset? _primaryDownGlobal;

  bool _hasClaimed = false;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    if (_primaryPointer != null) return;
    _primaryPointer = event.pointer;
    _primaryDownGlobal = event.position;
    if (shouldClaimImmediately(event.localPosition)) {
      _hasClaimed = true;
      resolve(GestureDisposition.accepted);
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    if (!_hasClaimed && event is PointerMoveEvent && event.pointer == _primaryPointer) {
      final downGlobal = _primaryDownGlobal!;
      if ((event.position - downGlobal).distance > _claimSlop && shouldClaimOnSlop()) {
        _hasClaimed = true;
        // 显式 accept 由发起者胜出, 与竞技场成员顺序无关; 父类 acceptGesture 会在
        // _state == possible 时派发 onScaleStart, 现有手势流程原样接上。
        resolve(GestureDisposition.accepted);
      }
    }
    super.handleEvent(event);
  }

  @override
  void rejectGesture(int pointer) {
    if (pointer == _primaryPointer) _clearPrimary();
    super.rejectGesture(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _clearPrimary();
    super.didStopTrackingLastPointer(pointer);
  }

  void _clearPrimary() {
    _primaryPointer = null;
    _primaryDownGlobal = null;
    _hasClaimed = false;
  }

  @override
  String get debugDescription => 'chart scale';
}
