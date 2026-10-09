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

/// [PaintResourceOwner] 在 PaintObject / DrawObject / KlineBindingBase 上的 reset 与释放时机。
library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
// PaintDelegateExt 被根导出 hide, 测 do* 调度需直接引入。
import 'package:flexi_kline/src/framework/chart/indicator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

/// reset / dispose 与生命周期回调记进同一个 [LifecycleLog], 可断言先后。
class _SpyResource implements PaintResource {
  _SpyResource(this.log, this.name);

  final LifecycleLog log;
  final String name;

  @override
  void reset() => log.events.add('reset:$name');

  @override
  void dispose() => log.events.add('dispose:$name');
}

/// keepAlive 的 external 对象; [resource] 懒登记。
class _OwnerExternalPaintObject extends SpyExternalPaintObject {
  _OwnerExternalPaintObject(this.log);

  final LifecycleLog log;

  int created = 0;

  late final resource = own(_create());

  _SpyResource _create() {
    created++;
    return _SpyResource(log, 'res');
  }
}

/// 非 keepAlive 的 computed 对象。
class _OwnerComputedPaintObject extends SpyComputedPaintObject {
  _OwnerComputedPaintObject(LifecycleLog log) {
    own(_SpyResource(log, 'res'));
  }
}

class _OwnerDrawObject extends TestDrawObject {
  _OwnerDrawObject(super.overlay, super.config, LifecycleLog log) {
    own(_SpyResource(log, 'draw'));
  }
}

void main() {
  group('PaintObject', () {
    SpyExternalIndicator externalIndicator(LifecycleLog log) =>
        SpyExternalIndicator(key: const ExternalIndicatorKey('ext_a'), log: log);

    _OwnerExternalPaintObject mountedExternal(LifecycleLog log) =>
        _OwnerExternalPaintObject(log)..mount(externalIndicator(log), FakePaintContext());

    _OwnerComputedPaintObject mountedComputed(LifecycleLog log) {
      final indicator = SpyComputedIndicator(key: const ComputedIndicatorKey('cp_a'), log: log);
      return _OwnerComputedPaintObject(log)..mount(indicator, FakePaintContext());
    }

    test('doDidUpdateIndicator 先 reset 资源、再回调 didUpdateIndicator，且 indicator 已换新', () {
      final log = LifecycleLog();
      final obj = mountedExternal(log);
      obj.resource;
      final next = externalIndicator(log);

      obj.doDidUpdateIndicator(next);

      expect(log.events, ['reset:res', 'didUpdateIndicator:ext_a']);
      expect(identical(obj.indicator, next), isTrue);
    });

    test('dispose 释放已登记资源', () {
      final log = LifecycleLog();
      final obj = mountedComputed(log);

      obj.dispose();

      expect(log.countOf('dispose:res'), 1);
      expect(log.countOf('reset:res'), 0);
    });

    test('重复 dispose 只释放一次', () {
      final log = LifecycleLog();
      final obj = mountedComputed(log);

      obj.dispose();
      obj.dispose();

      expect(log.countOf('dispose:res'), 1);
    });

    test('keepAlive 对象出树只 detach，不释放资源', () {
      final log = LifecycleLog();
      final obj = mountedExternal(log)
        ..doInitState()
        ..onEnterTree();
      obj.resource;

      obj.onExitTree();

      expect(log.countOf('didDetach:ext_a'), 1);
      expect(log.countOf('dispose:res'), 0);
      expect(log.countOf('reset:res'), 0);

      obj.dispose();
      expect(log.countOf('dispose:res'), 1);
    });

    test('非 keepAlive 对象出树时随 dispose 释放资源', () {
      final log = LifecycleLog();
      final obj = mountedComputed(log)
        ..doInitState()
        ..onEnterTree();

      obj.onExitTree();

      expect(log.countOf('dispose:res'), 1);
    });

    test('late final own() 首次访问才创建并登记，未访问时 reset / dispose 都不涉及它', () {
      final log = LifecycleLog();
      final obj = mountedExternal(log);
      final next = externalIndicator(log);

      obj.doDidUpdateIndicator(next);
      expect(obj.created, 0);
      expect(log.countOf('reset:res'), 0);

      expect(identical(obj.resource, obj.resource), isTrue);
      expect(obj.created, 1);

      obj.doDidUpdateIndicator(next);
      expect(log.countOf('reset:res'), 1);

      obj.dispose();
      expect(log.countOf('dispose:res'), 1);
    });

    test('disposeResources 之后首次 own() 触发断言', () {
      final obj = mountedExternal(LifecycleLog())..dispose();

      expect(() => obj.resource, throwsAssertionError);
    });
  });

  group('DrawObject', () {
    _OwnerDrawObject create(LifecycleLog log) {
      final overlay = Overlay.fromType(key: 'k', type: testDrawLineType, line: const LineConfig());
      return _OwnerDrawObject(overlay, const DrawConfig(), log);
    }

    test('dispose 释放资源，重复 dispose 安全', () {
      final log = LifecycleLog();
      final obj = create(log);

      obj.dispose();
      obj.dispose();

      expect(log.countOf('dispose:draw'), 1);
    });

    test('resetInteraction 不 reset 资源（DrawObject 无声明更新入口）', () {
      final log = LifecycleLog();
      final obj = create(log);

      obj.resetInteraction();

      expect(log.countOf('reset:draw'), 0);
      expect(log.countOf('dispose:draw'), 0);
    });
  });

  group('KlineBindingBase', () {
    const spec = KlineSpec(symbol: 'OWNER', interval: FlexiTimeInterval(1, TimeUnit.minute));

    testWidgets('controller dispose 时在两个 manager 之后释放 Binding 资源', (tester) async {
      final log = LifecycleLog();
      final scenario = ControllerScenario();
      await scenario.initWithData(spec, genFlatCandleList(count: 20));
      final controller = scenario.controller;

      scenario.candle.object!.own(_SpyResource(log, 'candle'));
      controller.own(_SpyResource(log, 'binding'));

      controller.dispose();

      expect(log.events, ['dispose:candle', 'dispose:binding']);

      // 释放后已注销, 再调是空操作。
      controller.disposeResources();
      expect(log.countOf('dispose:binding'), 1);
    });
  });
}
