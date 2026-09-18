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

/// `Path.takeFraction` 的长度语义与方向。
///
/// 方向是这个工具唯一「只会画错、不会报错」的地方：截取从路径起点开始，所以采样顺序决定生长
/// 方向。用等长线段构造路径，包围盒因此能直接反算出截到了哪里。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// 从 (0,0) 向右到 (300,0) 的水平折线，总长 300。
Path _horizontalLine() =>
    Path()..addPolygon(const [Offset(0, 0), Offset(100, 0), Offset(200, 0), Offset(300, 0)], false);

void main() {
  group('Path.takeFraction', () {
    test('按长度截取: 0.5 得到前一半', () {
      final bounds = _horizontalLine().takeFraction(0.5).getBounds();

      expect(bounds.left, moreOrLessEquals(0));
      expect(bounds.right, moreOrLessEquals(150), reason: '总长 300 的一半');
    });

    test('截取方向即路径方向: 从起点长出, 而非从终点', () {
      // 采样顺序是 dx 递增, 所以 0.25 只应留下最左侧那一段。
      final bounds = _horizontalLine().takeFraction(0.25).getBounds();

      expect(bounds.left, moreOrLessEquals(0));
      expect(bounds.right, moreOrLessEquals(75));
    });

    test('反向采样则从右侧长出', () {
      // 同一组点倒序采样, 截取结果落在右端——这正是 AVL 指标里「索引倒序收集」要保证的事。
      final reversed = Path()..addPolygon(const [Offset(300, 0), Offset(200, 0), Offset(100, 0), Offset(0, 0)], false);
      final bounds = reversed.takeFraction(0.25).getBounds();

      expect(bounds.right, moreOrLessEquals(300));
      expect(bounds.left, moreOrLessEquals(225));
    });

    test('不按点数截取: 长短不一的线段按长度均分', () {
      // 三段长度 10 / 10 / 80, 总长 100。按点数取 1/3 会停在 x=10, 按长度取 1/3 应到 x=33.3。
      final uneven = Path()..addPolygon(const [Offset(0, 0), Offset(10, 0), Offset(20, 0), Offset(100, 0)], false);

      final bounds = uneven.takeFraction(1 / 3).getBounds();
      expect(bounds.right, moreOrLessEquals(100 / 3, epsilon: 0.01));
    });

    test('fraction >= 1 返回自身实例', () {
      final path = _horizontalLine();

      expect(path.takeFraction(1), same(path));
      expect(path.takeFraction(1.5), same(path));
    });

    test('fraction <= 0 返回空路径', () {
      expect(_horizontalLine().takeFraction(0).getBounds(), Rect.zero);
      expect(_horizontalLine().takeFraction(-1).getBounds(), Rect.zero);
    });

    test('多 contour 各自按比例截取', () {
      final two = Path()
        ..addPolygon(const [Offset(0, 0), Offset(100, 0)], false)
        ..addPolygon(const [Offset(0, 50), Offset(100, 50)], false);

      final bounds = two.takeFraction(0.5).getBounds();
      expect(bounds.right, moreOrLessEquals(50));
      expect(bounds.bottom, moreOrLessEquals(50), reason: '第二段仍在, 只是也被截半');
    });
  });
}
