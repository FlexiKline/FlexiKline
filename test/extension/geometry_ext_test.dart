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

/// 几何扩展里带守卫的换算。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Rect.distanceFromBottom', () {
    const rect = Rect.fromLTRB(0, 100, 200, 400);

    test('从底边量起, 底边为 0、顶边为 height', () {
      expect(rect.distanceFromBottom(400), 0);
      expect(rect.distanceFromBottom(100), 300);
      expect(rect.distanceFromBottom(250), 150);
    });

    test('落在矩形之外时停在边界, 不继续增长', () {
      expect(rect.distanceFromBottom(500), 0, reason: '底边之下');
      expect(rect.distanceFromBottom(-50), 300, reason: '顶边之上');
    });

    test('高度为 0 返回 null', () {
      expect(const Rect.fromLTRB(0, 100, 200, 100).distanceFromBottom(100), isNull);
    });

    /// 上下翻转的矩形（`bottom < top`）高度为负，`clamp` 的上界小于下界会抛 `ArgumentError`。
    /// `chartRect` 的高度是 `size.height - padding.vertical - tipsAreaHeight`，主区很矮而
    /// 主区指标很多时确实会翻转，所以这条是真实可达的输入而非防御性洁癖。
    test('高度为负返回 null 而不抛异常', () {
      const inverted = Rect.fromLTRB(0, 40, 100, 20);
      expect(inverted.height, isNegative, reason: '前置条件: 必须是翻转矩形');
      expect(inverted.distanceFromBottom(30), isNull);
    });

    test('高度小于 1px 仍是合法输入', () {
      // 阈值曾是 `<= 1`，理由是 zoom 软化项由 `height - 1` 派生；软化项改为与高度成正比
      // 之后那个理由已消失，只有非正高度才是真正的危险输入。
      expect(const Rect.fromLTRB(0, 0, 10, 0.5).distanceFromBottom(0.2), closeTo(0.3, 1e-9));
    });
  });
}
