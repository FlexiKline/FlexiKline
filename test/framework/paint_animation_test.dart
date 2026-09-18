// Copyright 2024 Andy.Zhao
//
// ignore_for_file: invalid_use_of_protected_member
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

/// [TickerProviderPaintObjectMixin] 的 vsync 与静音契约。
///
/// Ticker 引用由用例自己经 `createTicker` 持有，所以断言 `muted` / `forceFrames` 不需要生产
/// 代码开放 ticker 集合。需要时间前进的用例走 [testWidgets]——Ticker 靠 `SchedulerBinding` 的
/// frame callback 推进，只有泵过 widget 树才有帧。
library;

// 直接引入内部库，使框架内部的 do* 调度扩展（PaintDelegateExt）对包内测试可见。
import 'package:flexi_kline/src/framework/chart/indicator.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

/// 可见且不强制出帧，等价 [TickerModeData.fallback]。
const _visible = TickerModeData(enabled: true, forceFrames: false);

/// 不可见（图表被路由覆盖等），动画应冻结。
const _hidden = TickerModeData(enabled: false, forceFrames: false);

/// 可见且宿主显式要求强制出帧。
const _forced = TickerModeData(enabled: true, forceFrames: true);

/// 记录 `requestRepaint` 次数的 context。
class _RepaintCountingContext extends FakePaintContext {
  int repaintCount = 0;

  @override
  void requestRepaint() => repaintCount++;
}

void main() {
  /// 建一个已 mount / initState / 入树的动画对象。
  ({TestAnimatedPaintObject object, _RepaintCountingContext context}) attachedObject({bool attach = true}) {
    final context = _RepaintCountingContext();
    final indicator = TestAnimatedIndicator(key: const ExternalIndicatorKey('anim'));
    final object = indicator.createPaintObject();
    object.mount(indicator, context);
    object.doInitState();
    if (attach) object.onEnterTree();
    return (object: object, context: context);
  }

  group('vsync 归属', () {
    test('createTicker 交出可用 Ticker，入树状态下不静音', () {
      final (object: object, context: _) = attachedObject();
      final ticker = object.createTicker((_) {});
      addTearDown(ticker.dispose);

      expect(ticker.muted, isFalse);
      expect(ticker.isActive, isFalse, reason: 'createTicker 不应自行 start');

      ticker.start();
      expect(ticker.isActive, isTrue);
      ticker.stop(canceled: true);
    });

    test('可同时持有多个 Ticker', () {
      final (object: object, context: _) = attachedObject();
      final first = object.createTicker((_) {});
      final second = object.createTicker((_) {});
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      expect(first, isNot(same(second)));
      expect(first.muted, isFalse);
      expect(second.muted, isFalse);
    });
  });

  group('静音源：绘制树', () {
    test('未入树时新建的 Ticker 初始即静音', () {
      // 必须创建时就静音而非先跑一帧再补：initState 期间几何尚未有效，那一帧的位置是错的。
      final (object: object, context: _) = attachedObject(attach: false);
      final ticker = object.createTicker((_) {});
      addTearDown(ticker.dispose);

      expect(ticker.muted, isTrue);
    });

    test('出树静音已有 Ticker，重新入树解除', () {
      final (object: object, context: _) = attachedObject();
      final ticker = object.createTicker((_) {});
      addTearDown(ticker.dispose);
      expect(ticker.muted, isFalse);

      object.onExitTree();
      expect(ticker.muted, isTrue);
      expect(object.isDisposed, isFalse, reason: 'External 指标 keepAlive，出树不销毁');

      object.onEnterTree();
      expect(ticker.muted, isFalse);
    });

    test('mixin 的生命周期覆写不吞掉 super', () {
      final (object: object, context: _) = attachedObject();
      object.onExitTree();
      object.onEnterTree();

      expect(object.lifecycleCalls, ['didAttach', 'didDetach', 'didAttach']);
    });
  });

  group('静音源：TickerMode', () {
    test('tickerMode 关闭时静音，恢复后解除', () {
      final (object: object, context: context) = attachedObject();
      final ticker = object.createTicker((_) {});
      addTearDown(ticker.dispose);

      context.tickerModeListenable.value = _hidden;
      expect(ticker.muted, isTrue);

      context.tickerModeListenable.value = _visible;
      expect(ticker.muted, isFalse);
    });

    test('tickerMode 关闭期间新建的 Ticker 初始即静音', () {
      final (object: object, context: context) = attachedObject();
      context.tickerModeListenable.value = _hidden;

      final ticker = object.createTicker((_) {});
      addTearDown(ticker.dispose);
      expect(ticker.muted, isTrue);
    });

    test('forceFrames 原样透传给已有 Ticker', () {
      // 「中继转发整个 TickerModeData 而不裁成 bool」的回归网：裁掉之后宿主显式写下的
      // TickerMode(forceFrames: true) 会被静默丢掉。
      final (object: object, context: context) = attachedObject();
      final ticker = object.createTicker((_) {});
      addTearDown(ticker.dispose);
      expect(ticker.forceFrames, isFalse);

      context.tickerModeListenable.value = _forced;
      expect(ticker.forceFrames, isTrue);

      context.tickerModeListenable.value = _visible;
      expect(ticker.forceFrames, isFalse);
    });

    test('forceFrames 在创建时即生效', () {
      final (object: object, context: context) = attachedObject();
      context.tickerModeListenable.value = _forced;

      final ticker = object.createTicker((_) {});
      addTearDown(ticker.dispose);
      expect(ticker.forceFrames, isTrue);
      expect(ticker.muted, isFalse, reason: 'forceFrames 与 muted 是独立的两维');
    });

    test('forceFrames 与出树冻结互不影响', () {
      final (object: object, context: context) = attachedObject();
      final ticker = object.createTicker((_) {});
      addTearDown(ticker.dispose);

      context.tickerModeListenable.value = _forced;
      object.onExitTree();

      expect(ticker.muted, isTrue, reason: '出树仍冻结');
      expect(ticker.forceFrames, isTrue, reason: 'forceFrames 不因出树而改变');
    });

    test('两个静音源独立：只解除一个仍保持静音', () {
      final (object: object, context: context) = attachedObject();
      final ticker = object.createTicker((_) {});
      addTearDown(ticker.dispose);

      context.tickerModeListenable.value = _hidden;
      object.onExitTree();
      expect(ticker.muted, isTrue);

      // 只恢复可见性，仍在树外。
      context.tickerModeListenable.value = _visible;
      expect(ticker.muted, isTrue, reason: '仍未入树');

      object.onEnterTree();
      expect(ticker.muted, isFalse);
    });
  });

  group('释放', () {
    test('dispose 停止并释放残留 Ticker', () {
      final (object: object, context: _) = attachedObject();
      final ticker = object.createTicker((_) {})..start();
      expect(ticker.isActive, isTrue);

      object.dispose();

      expect(ticker.isActive, isFalse, reason: '兜底停止，避免残留 frame callback');
      expect(object.isDisposed, isTrue);
    });

    test('dispose 解除 tickerMode 订阅', () {
      final (object: object, context: context) = attachedObject();
      final ticker = object.createTicker((_) {});
      object.dispose();

      // 已 dispose 的对象不应再响应可见性变化；ticker 也已释放，改动它会抛。
      context.tickerModeListenable.value = _hidden;
      expect(ticker.muted, isFalse, reason: 'dispose 已解除订阅，不再同步');
    });

    test('Ticker 自行 dispose 后不再受静音同步影响', () {
      final (object: object, context: context) = attachedObject();
      final ticker = object.createTicker((_) {});
      // 模拟 AnimationController.dispose：ticker 应从创建者集合中摘除。
      ticker.dispose();

      context.tickerModeListenable.value = _hidden;
      expect(ticker.muted, isFalse, reason: '已摘除的 ticker 不该被回写');

      // 集合已空，对象自身的 dispose 不应因此出错。
      expect(object.dispose, returnsNormally);
    });

    test('dispose 后 createTicker 触发断言', () {
      final (object: object, context: _) = attachedObject();
      object.dispose();

      expect(() => object.createTicker((_) {}), throwsAssertionError);
    });
  });

  group('tick 即重绘', () {
    testWidgets('每次 tick 之后请求一次重绘', (tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      final (object: object, context: context) = attachedObject();

      final elapsedList = <Duration>[];
      final ticker = object.createTicker(elapsedList.add)..start();

      expect(context.repaintCount, 0);

      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));

      expect(elapsedList, isNotEmpty);
      expect(
        context.repaintCount,
        elapsedList.length,
        reason: 'tick 与重绘请求一一对应，实现方无需在 listener 里手动触发',
      );

      // 必须在用例体内停止，不能挂 addTearDown：flutter_test 在 body 结束时就检查
      // 是否还有 transient callback，tearDown 跑得太晚。
      ticker.stop(canceled: true);
      ticker.dispose();
    });

    testWidgets('静音期间不 tick，也不请求重绘', (tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      final (object: object, context: context) = attachedObject();

      final elapsedList = <Duration>[];
      final ticker = object.createTicker(elapsedList.add)..start();

      object.onExitTree();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));

      expect(elapsedList, isEmpty);
      expect(context.repaintCount, 0);

      ticker.stop(canceled: true);
      ticker.dispose();
    });

    testWidgets('AnimationController 经本 mixin 正常推进', (tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      final (object: object, context: context) = attachedObject();

      final animation = AnimationController(
        vsync: object,
        duration: const Duration(milliseconds: 100),
      );
      addTearDown(animation.dispose);

      expect(animation.value, 0);
      animation.forward();

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(animation.value, greaterThan(0));
      expect(animation.value, lessThan(1));
      expect(context.repaintCount, greaterThan(0));

      await tester.pump(const Duration(milliseconds: 60));
      expect(animation.value, 1);
      expect(animation.isCompleted, isTrue);
    });
  });
}
