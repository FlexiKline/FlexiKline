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

/// 图表专用 Scale 识别器：归属由上层判定，本类只负责抢占手势竞技场。
///
/// 图表的单指阈值恒为外层 Scrollable 的两倍——[DeviceGestureSettings.panSlop] 是
/// `touchSlop * 2` 的派生 getter，而外层 [VerticalDragGestureRecognizer] 读同一个
/// `touchSlop`；这是恒等关系而非数值巧合，调参无解。所以在上层确认存在归属后把阈值降到
/// [_claimSlop] 并显式 [resolve]，抢在外层裁决之前胜出；上层没有归属时完全不干预，空白区
/// 拖动仍归外层滚动。
class TouchScaleGestureRecognizer extends ScaleGestureRecognizer {
  TouchScaleGestureRecognizer({
    required this.shouldClaimOnDown,
    required this.shouldClaimOnSlop,
    required this.claimSlopFactor,
    super.debugOwner,
  }) : assert(
          claimSlopFactor > 0 && claimSlopFactor < 1,
          'claimSlopFactor 必须落在 (0, 1) 内: 取 0 会抢掉手柄上的点击, '
          '取 >= 1 会晚于外层 Scrollable 的裁决',
        );

  /// 第一指按下即抢占。只用于 zoom slider 专属区域。
  final bool Function(Offset localPosition) shouldClaimOnDown;

  /// 任一指位移超过 [_claimSlop] 后是否抢占。
  final bool Function() shouldClaimOnSlop;

  /// 抢占阈值相对外层 hitSlop 的比例，取值 (0, 1)。
  final double claimSlopFactor;

  /// 抢占阈值，相对外层 Scrollable 的实际 hitSlop 派生。
  ///
  /// 不写死像素值：Android 的 `touchSlop` 常小于 [kTouchSlop]，写死会在部分设备上大于外层
  /// 阈值，表现为快速滑动抢得到、慢速拖动抢不到。[gestureSettings] 与外层同源，但
  /// [RawGestureDetector] 不像 [GestureDetector] 会自动注入，得由上层显式传。
  double get _claimSlop => (gestureSettings?.touchSlop ?? kTouchSlop) * claimSlopFactor;

  /// 每指按下时的全局位置，用于算抢占位移。
  ///
  /// 逐指记录而非只记第一指：捏合常是一指锚定、另一指移动，第一指到不了 [_claimSlop]。
  /// [_claimSlop] 防的是抢掉点击，而点击只可能是单指。
  final Map<int, Offset> _downPositions = <int, Offset>{};
  bool _hasClaimed = false;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    // 落点即抢占只问第一指: 落点归属独占整个 pointer session, 后续指针不重判。
    final isFirst = _downPositions.isEmpty;
    _downPositions[event.pointer] = event.position;
    if (isFirst && shouldClaimOnDown(event.localPosition)) {
      _hasClaimed = true;
      // 竞技场此刻还没关闭, accept 会先记为 eagerWinner, 在 close 的第一时刻兑现。
      resolve(GestureDisposition.accepted);
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    if (!_hasClaimed && event is PointerMoveEvent) {
      final down = _downPositions[event.pointer];
      if (down != null && (event.position - down).distance > _claimSlop && shouldClaimOnSlop()) {
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
    _downPositions.remove(pointer);
    // 全部指针离场即复位, 让下一轮重新判定。
    if (_downPositions.isEmpty) _hasClaimed = false;
    super.rejectGesture(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _downPositions.clear();
    _hasClaimed = false;
    super.didStopTrackingLastPointer(pointer);
  }

  @override
  String get debugDescription => 'touch scale';
}
