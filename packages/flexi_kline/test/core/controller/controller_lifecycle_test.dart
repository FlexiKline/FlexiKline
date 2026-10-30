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

/// Controller 的生命周期：initial → mounted → disposed，以及挂载前的调用。
library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/support.dart';

const _spec = KlineSpec(symbol: 'LIFECYCLE', interval: FlexiTimeInterval(1, TimeUnit.minute));

FlexiKlineController _controller() => FlexiKlineController(
  configuration: FakeFlexiKlineConfiguration(mainIndicatorDefaultSize: const Size(400, 300)),
);

void _mount(FlexiKlineController c) => c.mountIndicators(
  candle: TestCandleIndicator(),
  time: TestTimeIndicator(),
  mainIndicators: const [],
  subIndicators: const [],
);

void main() {
  test('initial → mounted → disposed', () {
    final c = _controller();
    expect(c.lifecycleListenable.value, FlexiKlineLifecycle.initial);
    expect(c.isMounted, isFalse);

    _mount(c);
    expect(c.lifecycleListenable.value, FlexiKlineLifecycle.mounted);
    expect(c.isMounted, isTrue);

    c.dispose();
    expect(c.lifecycleListenable.value, FlexiKlineLifecycle.disposed);
  });

  group('挂载前', () {
    test('受守卫的 API 不抛异常, moveToDateTime 返回 null', () async {
      final c = _controller();
      addTearDown(c.dispose);

      expect(c.onThemeChanged, returnsNormally);
      expect(c.requestMoveToInitialPosition, returnsNormally);
      expect(await c.moveToDateTime(DateTime.utc(2026, 7, 10)), isNull);
    });

    testWidgets('replaceKlineData 先排队, initState 之后生效', (tester) async {
      final c = _controller();
      addTearDown(c.dispose);
      c.switchKlineData(_spec);
      c.replaceKlineData(_spec, genFlatCandleList(count: 3));
      expect(c.klineData.isEmpty, isTrue);

      _mount(c);
      c.initState();
      c.flushPendingKlineData();

      expect(c.klineData.length, 3);
    });
  });

  test('requestMoveToInitialPosition 经 moveToPositionCallback 从当前位置移到初始位置', () {
    final c = _controller();
    addTearDown(c.dispose);
    _mount(c);
    c.initState();
    double? begin, end;
    c.moveToPositionCallback = (b, e) async {
      begin = b;
      end = e;
      return true;
    };

    c.requestMoveToInitialPosition();

    expect(begin, c.paintDxOffset);
    expect(end, c.clampPaintDxOffset(c.getInitPaintDxOffset()));
  });
}
