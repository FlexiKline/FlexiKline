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

/// 图表专用 Scale 识别器：由上层判定归属，本类只负责抢占手势竞技场。
///
/// [DeviceGestureSettings.panSlop] 是 `touchSlop * 2` 的派生 getter，而外层 Scrollable 的
/// [VerticalDragGestureRecognizer] 读的正是同一个 `touchSlop`。也就是说图表的单指阈值恒为
/// 外层的两倍，同一 [MediaQuery] 作用域下必输——这是恒等关系而非数值巧合，调参无法解决。
/// 本类在上层确认存在归属后把阈值降到 [_claimSlop] 并显式 [resolve]，抢在外层之前胜出。
///
/// 上层没有归属时不做任何干预：空白区拖动仍归外层滚动。
class FlexiScaleGestureRecognizer extends ScaleGestureRecognizer {
  FlexiScaleGestureRecognizer({
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
  /// `touchSlop` 常小于 [kTouchSlop]，写死的值会在部分设备上大于外层阈值，表现为快速滑动
  /// 抢得到、慢速拖动抢不到。这里读的 [gestureSettings] 与外层同源，前提是它被正确注入
  /// ——[RawGestureDetector] 不会像 [GestureDetector] 那样自动注入。
  double get _claimSlop => (gestureSettings?.touchSlop ?? kTouchSlop) * claimSlopFactor;

  /// 本轮手势的第一指及其按下时的全局位置，用于算抢占位移。
  int? _primaryPointer;
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
      // 竞技场此刻还没关闭, accept 会先记为 eagerWinner, 在 close 的第一时刻兑现。
      resolve(GestureDisposition.accepted);
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    if (!_hasClaimed && event is PointerMoveEvent && event.pointer == _primaryPointer) {
      if ((event.position - _primaryDownGlobal!).distance > _claimSlop && shouldClaimOnSlop()) {
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
  String get debugDescription => 'flexi scale';
}
