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

library;

import 'package:flexi_kline/flexi_kline.dart';
// 直接引入内部库，使框架内部的 do* 调度扩展（PaintDelegateExt）对包内测试可见。
import 'package:flexi_kline/src/framework/chart/indicator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

void main() {
  group('PaintObject 单对象生命周期', () {
    SpyExternalPaintObject mountedExternal(LifecycleLog log, {String id = 'a'}) {
      final indicator = SpyExternalIndicator(key: ExternalIndicatorKey('ext_$id'), log: log);
      final obj = indicator.createPaintObject() as SpyExternalPaintObject;
      obj.mount(indicator, FakePaintContext());
      return obj;
    }

    SpyComputedPaintObject mountedComputed(LifecycleLog log, {String id = 'c', bool keepAlive = false}) {
      final indicator = SpyComputedIndicator(key: ComputedIndicatorKey('cp_$id'), log: log, keepAlive: keepAlive);
      final obj = indicator.createPaintObject() as SpyComputedPaintObject;
      obj.mount(indicator, FakePaintContext());
      return obj;
    }

    test('doInitState 只触发一次 initState', () {
      final log = LifecycleLog();
      final obj = mountedExternal(log);

      obj.doInitState();
      obj.doInitState();

      expect(log.countOf('initState:ext_a'), 1);
    });

    test('onEnterTree 触发 didAttach，重复 enter 不重复触发', () {
      final log = LifecycleLog();
      final obj = mountedExternal(log)..doInitState();

      obj.onEnterTree();
      obj.onEnterTree();

      expect(log.countOf('didAttach:ext_a'), 1);
    });

    test('keepAlive=true：onExitTree 触发 didDetach 且不 dispose', () {
      final log = LifecycleLog();
      final obj = mountedExternal(log)
        ..doInitState()
        ..onEnterTree();

      obj.onExitTree();

      expect(log.countOf('didDetach:ext_a'), 1);
      expect(log.countOf('dispose:ext_a'), 0);
    });

    test('keepAlive=false：onExitTree 触发 didDetach 后 dispose', () {
      final log = LifecycleLog();
      final obj = mountedComputed(log)
        ..doInitState()
        ..onEnterTree();

      obj.onExitTree();

      expect(log.countOf('didDetach:cp_c'), 1);
      expect(log.countOf('dispose:cp_c'), 1);
    });

    test('Computed 复写 keepAlive=true：onExitTree 不 dispose', () {
      final log = LifecycleLog();
      final obj = mountedComputed(log, keepAlive: true)
        ..doInitState()
        ..onEnterTree();

      obj.onExitTree();

      expect(log.countOf('didDetach:cp_c'), 1);
      expect(log.countOf('dispose:cp_c'), 0);
    });

    test('未 attach 时 onExitTree 不触发 didDetach', () {
      final log = LifecycleLog();
      final obj = mountedExternal(log)..doInitState();

      obj.onExitTree();

      expect(log.countOf('didDetach:ext_a'), 0);
    });

    test('dispose 幂等，不重复执行', () {
      final log = LifecycleLog();
      final obj = mountedExternal(log)..doInitState();

      obj.dispose();
      obj.dispose();

      expect(log.countOf('dispose:ext_a'), 1);
    });
  });

  group('manager 驱动的 external 生命周期', () {
    IndicatorPaintObjectManager build(LifecycleLog log, {int subMax = 3}) {
      return IndicatorPaintObjectManager(
        configuration: FakeFlexiKlineConfiguration(),
        subIndicatorMaxCount: subMax,
      );
    }

    void mount(IndicatorPaintObjectManager m, List<Indicator> main, List<Indicator> sub, PaintContext ctx) {
      m.mountIndicators(
        candle: TestCandleIndicator(),
        time: TestTimeIndicator(),
        mainIndicators: main,
        subIndicators: sub,
        context: ctx,
      );
    }

    test('autoActivate=false 声明在 mount 时不创建对象（惰性）', () {
      final log = LifecycleLog();
      final ctx = FakePaintContext();
      final m = build(log);
      final ext = SpyExternalIndicator(key: const ExternalIndicatorKey('ext_a'), log: log, autoActivate: false);

      mount(m, [ext], const [], ctx);

      expect(log.countOf('initState:ext_a'), 0); // 未激活 → 不创建
      expect(log.countOf('didAttach:ext_a'), 0);
    });

    test('autoActivate=true 声明在 mount 时自动激活（创建 + initState + didAttach）', () {
      final log = LifecycleLog();
      final ctx = FakePaintContext();
      final m = build(log);
      final ext = SpyExternalIndicator(key: const ExternalIndicatorKey('ext_a'), log: log); // 默认 true

      mount(m, [ext], const [], ctx);

      expect(log.countOf('initState:ext_a'), 1);
      expect(log.countOf('didAttach:ext_a'), 1);
    });

    test('show 复用常驻对象触发 didAttach，不重复 initState', () {
      final log = LifecycleLog();
      final ctx = FakePaintContext();
      final m = build(log);
      final ext = SpyExternalIndicator(key: const ExternalIndicatorKey('ext_a'), log: log);
      mount(m, [ext], const [], ctx);

      m.addMainPaintObject(const ExternalIndicatorKey('ext_a'), ctx);

      expect(log.countOf('didAttach:ext_a'), 1);
      expect(log.countOf('initState:ext_a'), 1);
    });

    test('hide 后再 show：detach 保活、不 dispose、不重复 initState', () {
      final log = LifecycleLog();
      final ctx = FakePaintContext();
      final m = build(log);
      const key = ExternalIndicatorKey('ext_a');
      mount(m, [SpyExternalIndicator(key: key, log: log)], const [], ctx);

      m.addMainPaintObject(key, ctx);
      m.removeMainPaintObject(key);
      m.addMainPaintObject(key, ctx);

      expect(log.countOf('initState:ext_a'), 1);
      expect(log.countOf('didDetach:ext_a'), 1);
      expect(log.countOf('didAttach:ext_a'), 2);
      expect(log.countOf('dispose:ext_a'), 0);
    });

    test('副区容量驱逐：被挤出的 external 走保活 detach，不 dispose', () {
      final log = LifecycleLog();
      final ctx = FakePaintContext();
      final m = build(log, subMax: 1);
      const a = ExternalIndicatorKey('ext_a');
      const b = ExternalIndicatorKey('ext_b');
      mount(
        m,
        const [],
        [
          SpyExternalIndicator(key: a, log: log, autoActivate: false),
          SpyExternalIndicator(key: b, log: log, autoActivate: false)
        ],
        ctx,
      );

      m.addSubPaintObject(a, ctx);
      m.addSubPaintObject(b, ctx); // a 被挤出

      expect(log.countOf('didAttach:ext_a'), 1);
      expect(log.countOf('didDetach:ext_a'), 1);
      expect(log.countOf('dispose:ext_a'), 0);
    });

    test('controller dispose：常驻 external 各 dispose 一次，无重复', () {
      final log = LifecycleLog();
      final ctx = FakePaintContext();
      final m = build(log);
      const key = ExternalIndicatorKey('ext_a');
      mount(m, [SpyExternalIndicator(key: key, log: log)], const [], ctx);
      m.addMainPaintObject(key, ctx); // 激活，挂在主区

      m.dispose();

      expect(log.countOf('dispose:ext_a'), 1);
    });
  });

  group('updateIndicators 的 external 增删改', () {
    IndicatorPaintObjectManager build(LifecycleLog log) =>
        IndicatorPaintObjectManager(configuration: FakeFlexiKlineConfiguration());

    test('声明移除 external 时 dispose 并清出缓存', () {
      final log = LifecycleLog();
      final ctx = FakePaintContext();
      final m = build(log);
      const key = ExternalIndicatorKey('ext_a');
      final ext = SpyExternalIndicator(key: key, log: log);
      m.mountIndicators(
        candle: TestCandleIndicator(),
        time: TestTimeIndicator(),
        mainIndicators: [ext],
        subIndicators: const [],
        context: ctx,
      );

      m.updateIndicators(
        context: ctx,
        oldCandle: TestCandleIndicator(),
        newCandle: TestCandleIndicator(),
        oldTime: TestTimeIndicator(),
        newTime: TestTimeIndicator(),
        oldMainIndicators: [ext],
        newMainIndicators: const [],
        oldSubIndicators: const [],
        newSubIndicators: const [],
      );

      expect(log.countOf('dispose:ext_a'), 1);
    });

    test('同 key external 配置变化触发 didUpdateIndicator', () {
      final log = LifecycleLog();
      final ctx = FakePaintContext();
      final m = build(log);
      const key = ExternalIndicatorKey('ext_a');
      final oldExt = SpyExternalIndicator(key: key, log: log, height: 80);
      final newExt = SpyExternalIndicator(key: key, log: log, height: 120);
      m.mountIndicators(
        candle: TestCandleIndicator(),
        time: TestTimeIndicator(),
        mainIndicators: [oldExt],
        subIndicators: const [],
        context: ctx,
      );

      m.updateIndicators(
        context: ctx,
        oldCandle: TestCandleIndicator(),
        newCandle: TestCandleIndicator(),
        oldTime: TestTimeIndicator(),
        newTime: TestTimeIndicator(),
        oldMainIndicators: [oldExt],
        newMainIndicators: [newExt],
        oldSubIndicators: const [],
        newSubIndicators: const [],
      );

      expect(log.countOf('didUpdateIndicator:ext_a'), 1);
    });

    test('新增 external 声明由 updateIndicators 返回待激活 key（manager 内不创建）', () {
      final log = LifecycleLog();
      final ctx = FakePaintContext();
      final m = build(log);
      m.mountIndicators(
        candle: TestCandleIndicator(),
        time: TestTimeIndicator(),
        mainIndicators: const [],
        subIndicators: const [],
        context: ctx,
      );
      const key = ExternalIndicatorKey('ext_a');
      final ext = SpyExternalIndicator(key: key, log: log); // 默认 autoActivate=true

      final pending = m.updateIndicators(
        context: ctx,
        oldCandle: TestCandleIndicator(),
        newCandle: TestCandleIndicator(),
        oldTime: TestTimeIndicator(),
        newTime: TestTimeIndicator(),
        oldMainIndicators: const [],
        newMainIndicators: [ext],
        oldSubIndicators: const [],
        newSubIndicators: const [],
      );

      expect(pending.main, contains(key)); // 待激活
      expect(log.countOf('initState:ext_a'), 0); // manager 未创建

      // 模拟上层 show：激活后才创建。
      m.addMainPaintObject(key, ctx);
      expect(log.countOf('initState:ext_a'), 1);
    });

    test('副区 external 移除后再以同 key 新增：缓存不残留已销毁对象', () {
      final log = LifecycleLog();
      final ctx = FakePaintContext();
      final m = build(log);
      const key = ExternalIndicatorKey('ext_s');
      final ext = SpyExternalIndicator(key: key, log: log, autoActivate: false);
      m.mountIndicators(
        candle: TestCandleIndicator(),
        time: TestTimeIndicator(),
        mainIndicators: const [],
        subIndicators: [ext],
        context: ctx,
      );

      // 激活到副区绘制树。
      m.addSubPaintObject(key, ctx);

      // 声明移除 → 强制 dispose，并清出 keepAlive 缓存。
      m.updateIndicators(
        context: ctx,
        oldCandle: TestCandleIndicator(),
        newCandle: TestCandleIndicator(),
        oldTime: TestTimeIndicator(),
        newTime: TestTimeIndicator(),
        oldMainIndicators: const [],
        newMainIndicators: const [],
        oldSubIndicators: [ext],
        newSubIndicators: const [],
      );

      // 以同 key 新增全新实例并再次激活 → 应创建新对象，而非复用已销毁的。
      final freshExt = SpyExternalIndicator(key: key, log: log, autoActivate: false);
      m.updateIndicators(
        context: ctx,
        oldCandle: TestCandleIndicator(),
        newCandle: TestCandleIndicator(),
        oldTime: TestTimeIndicator(),
        newTime: TestTimeIndicator(),
        oldMainIndicators: const [],
        newMainIndicators: const [],
        oldSubIndicators: const [],
        newSubIndicators: [freshExt],
      );
      m.addSubPaintObject(key, ctx);

      expect(log.countOf('dispose:ext_s'), 1);
      expect(log.countOf('initState:ext_s'), 2);
    });
  });

  group('依赖变化通知', () {
    test('notifySpecChanged 触达 attached 与 detached 常驻对象（去重）', () {
      final log = LifecycleLog();
      final ctx = FakePaintContext();
      final m = IndicatorPaintObjectManager(configuration: FakeFlexiKlineConfiguration());
      const a = ExternalIndicatorKey('ext_a'); // 主区，激活
      const b = ExternalIndicatorKey('ext_b'); // 副区，未激活（常驻 detached）
      m.mountIndicators(
        candle: TestCandleIndicator(),
        time: TestTimeIndicator(),
        mainIndicators: [SpyExternalIndicator(key: a, log: log)],
        subIndicators: [SpyExternalIndicator(key: b, log: log)],
        context: ctx,
      );
      m.addMainPaintObject(a, ctx); // a 进树（既在树又在缓存）

      const oldSpec = KlineSpec(symbol: 'OLD', interval: invalidInterval);
      m.notifySpecChanged(oldSpec);

      expect(log.countOf('didChangeDependencies:ext_a'), 1); // 去重，不因双集合触发两次
      expect(log.countOf('didChangeDependencies:ext_b'), 1); // detached 也收到
    });
  });

  group('keepAlive Computed 复用', () {
    test('副区 hide 后再 show：复用实例、不重复 initState、不 dispose', () {
      final log = LifecycleLog();
      final ctx = FakePaintContext();
      final m = IndicatorPaintObjectManager(configuration: FakeFlexiKlineConfiguration());
      const key = ComputedIndicatorKey('cp_k');
      m.mountIndicators(
        candle: TestCandleIndicator(),
        time: TestTimeIndicator(),
        mainIndicators: const [],
        subIndicators: [SpyComputedIndicator(key: key, log: log, keepAlive: true)],
        context: ctx,
      );

      // 懒创建：声明时不创建（仅 external 才 eager）。
      expect(log.countOf('initState:cp_k'), 0);

      m.addSubPaintObject(key, ctx); // 首次 show → 创建 + initState + attach
      m.removeSubPaintObject(key); // hide → didDetach，不 dispose，入缓存
      m.addSubPaintObject(key, ctx); // 再 show → 复用

      expect(log.countOf('initState:cp_k'), 1);
      expect(log.countOf('didAttach:cp_k'), 2);
      expect(log.countOf('didDetach:cp_k'), 1);
      expect(log.countOf('dispose:cp_k'), 0);
    });

    test('keepAlive=false Computed：hide 即 dispose、再 show 重建', () {
      final log = LifecycleLog();
      final ctx = FakePaintContext();
      final m = IndicatorPaintObjectManager(configuration: FakeFlexiKlineConfiguration());
      const key = ComputedIndicatorKey('cp_n');
      m.mountIndicators(
        candle: TestCandleIndicator(),
        time: TestTimeIndicator(),
        mainIndicators: const [],
        subIndicators: [SpyComputedIndicator(key: key, log: log, keepAlive: false)],
        context: ctx,
      );

      m.addSubPaintObject(key, ctx);
      m.removeSubPaintObject(key);
      m.addSubPaintObject(key, ctx);

      expect(log.countOf('initState:cp_n'), 2); // 重建两次
      expect(log.countOf('dispose:cp_n'), 1); // hide 一次销毁
    });
  });
}
