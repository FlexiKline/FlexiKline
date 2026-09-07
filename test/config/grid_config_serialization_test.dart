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

/// 网格配置的序列化：grid 层只剩边框，刻度参数下沉到指标。
///
/// 本组守三件只会「静默变形」的事：
///
/// 一是**旧持久化配置仍要还原**。`GridAxis` 更名为 `GridBorder` 只动类型名，JSON 键
/// (`grid.horizontal.show` / `.line`) 一个没变，所以旧配置照常读回来，只有随网格线下沉的
/// `count` 被忽略。类型名换了却顺手改了键，就会让所有存过配置的宿主静默回落默认值。
///
/// 二是**指标侧「不画线」必须能往返**。`GridAxisConfig.line` 的默认值必须是 null：可空字段
/// 一旦带非空默认值，json_serializable 生成的 `?? 默认值` 就会把宿主关掉的线复活，不报错、
/// 只是配置悄悄失效。
///
/// 三是 **`GridTickMode` 的参数属于哪个模式**。sealed class 在类型上封死了这件事，序列化却
/// 要自己维持：`type` 与参数键对不上时，converter 静默交出回落值而不是抛。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

/// 前一期（2.5.0 未发布段）的 grid 配置形状：刻度参数还挂在 grid 层。
///
/// `count` 从 2.4.x 起就在，`tickMode` 是未发布段新加的；两者都随网格线下沉到指标，读到时
/// 应当被忽略而不是抛。
const _legacyGridJson = <String, dynamic>{
  'show': true,
  'horizontal': {
    'show': true,
    'count': 8,
    'tickMode': 'average',
    'line': {
      'type': 'dashed',
      'dashes': [4.0, 4.0],
      'paint': {'strokeWidth': 2.0},
    },
  },
  'vertical': {'show': false, 'count': 3},
  'isAllowDragIndicatorHeight': true,
  'dragHitTestMinDistance': 16.0,
};

void main() {
  group('v2.5.0/配置/GridConfig 序列化', () {
    test('默认值往返: 键与旧版一致', () {
      final json = const GridConfig().toJson();

      expect(json.keys, containsAll(['show', 'horizontal', 'vertical']));

      final restored = GridConfig.fromJson(json);

      expect(restored.show, true);
      expect(restored.horizontal.show, true);
      expect(restored.horizontal.line.toJson(), (json['horizontal'] as Map)['line']);
      expect(restored.vertical.show, true);
      expect(restored.isAllowDragIndicatorHeight, false);
      expect(restored.dragHitTestMinDistance, 10);
      // 全局刻度文本样式仍在 grid 层, 不随刻度参数下沉。
      expect(json.containsKey('ticksText'), isTrue);
      expect(restored.ticksText.textAlign, const GridConfig().ticksText.textAlign);
    });

    test('边框不再有 count / tickMode 键', () {
      final json = const GridConfig().toJson();

      for (final key in ['horizontal', 'vertical']) {
        final border = json[key] as Map<String, dynamic>;
        expect(border.keys, ['show', 'line'], reason: '$key 只剩边框语义');
      }
    });

    test('show 与 line 逐字往返', () {
      final json = const GridConfig(
        show: false,
        horizontal: GridBorder(show: false),
        vertical: GridBorder(line: LineConfig(type: LineType.dotted, dashes: [1, 4])),
      ).toJson();

      final restored = GridConfig.fromJson(json);

      expect(restored.show, false);
      expect(restored.horizontal.show, false);
      expect(restored.vertical.line.type, LineType.dotted);
      expect(restored.vertical.line.dashes, [1.0, 4.0]);
    });

    test('旧 JSON: 不抛, count / tickMode 忽略, show 与 line 照常还原', () {
      final restored = GridConfig.fromJson(_legacyGridJson);

      // 键未变, 所以宿主定制过的边框样式一个不丢。
      expect(restored.horizontal.show, true);
      expect(restored.horizontal.line.type, LineType.dashed);
      expect(restored.horizontal.line.dashes, [4.0, 4.0]);
      expect(restored.vertical.show, false, reason: '关掉的左右边框不得被默认值复活');
      // 与刻度无关的字段照常读取。
      expect(restored.isAllowDragIndicatorHeight, true);
      expect(restored.dragHitTestMinDistance, 16.0);
    });
  });

  group('v2.5.0/配置/GridTickMode 序列化', () {
    const converter = GridTickModeConverter();

    test('三种模式各自往返, 参数不丢', () {
      const modes = <GridTickMode>[
        GridTickMode.count(8),
        GridTickMode.size(48.5),
        GridTickMode.nice(targetDivisions: 3),
      ];

      for (final mode in modes) {
        expect(converter.fromJson(converter.toJson(mode)), mode, reason: '$mode 往返后不等价');
      }
    });

    test('参数键随模式走, 不共用一个数值字段', () {
      expect(converter.toJson(const GridTickMode.count(8)), {'type': 'count', 'divisions': 8});
      expect(converter.toJson(const GridTickMode.size(60)), {'type': 'size', 'spacing': 60.0});
      expect(converter.toJson(const GridTickMode.nice(targetDivisions: 3)), {
        'type': 'nice',
        'targetDivisions': 3,
      });
    });

    test('未知 type 与缺参数: 回落默认, 不抛', () {
      // 'average' 是未发布段那个 enum 的取值, 现在只是个未知模式。
      expect(converter.fromJson({'type': 'average'}), GridTickMode.fallback);
      expect(converter.fromJson({}), GridTickMode.fallback);
      expect(converter.fromJson({'type': 'count'}), const GridTickMode.count(5));
      expect(converter.fromJson({'type': 'nice'}), const GridTickMode.nice());
    });
  });

  group('v2.5.0/配置/GridAxisConfig 序列化', () {
    test('默认值往返: 默认不画线', () {
      final json = const GridAxisConfig().toJson();
      final restored = GridAxisConfig.fromJson(json);

      expect(restored.mode, GridTickMode.fallback);
      expect(restored.line, isNull, reason: 'null 是唯一能精确往返的默认值');
    });

    test('line 置 null 往返: 不被默认线吃掉', () {
      final json = const GridAxisConfig(
        mode: GridTickMode.size(72),
        line: LineConfig(),
      ).copyWith(line: null).toJson();

      final restored = GridAxisConfig.fromJson(json);

      expect(restored.line, isNull, reason: '不画线仍要产出位置, 但线本身不能被复活');
      expect(restored.mode, const GridTickMode.size(72));
    });

    test('line 给出时逐字往返', () {
      final json = const GridAxisConfig(
        mode: GridTickMode.count(4),
        line: LineConfig(type: LineType.dashed, dashes: [6, 2]),
      ).toJson();

      final restored = GridAxisConfig.fromJson(json);

      expect(restored.mode, const GridTickMode.count(4));
      expect(restored.line?.type, LineType.dashed);
      expect(restored.line?.dashes, [6.0, 2.0]);
    });
  });

  group('v2.5.0/配置/CandleIndicator 序列化', () {
    test('默认网格配置往返: 横 nice、竖 count, 两者都画线', () {
      final json = CandleIndicator().toJson();
      final restored = CandleIndicator.fromJson(json);

      expect(restored.horizontalGrid.mode, const GridTickMode.nice(targetDivisions: 5));
      expect(restored.verticalGrid.mode, const GridTickMode.count(5));
      expect(restored.horizontalGrid.line, isNotNull);
      expect(restored.verticalGrid.line, isNotNull);
    });

    test('自定义网格配置往返: 含 mode 参数与 line 的 null', () {
      final json = CandleIndicator(
        horizontalGrid: const GridAxisConfig(
          mode: GridTickMode.nice(targetDivisions: 9),
          line: LineConfig(),
        ),
        verticalGrid: const GridAxisConfig(mode: GridTickMode.size(80)),
      ).toJson();

      final restored = CandleIndicator.fromJson(json);

      expect(restored.horizontalGrid.mode, const GridTickMode.nice(targetDivisions: 9));
      expect(restored.horizontalGrid.line, isNotNull);
      expect(restored.verticalGrid.mode, const GridTickMode.size(80));
      expect(restored.verticalGrid.line, isNull, reason: '竖线关掉后仍要产出 dx 供副区对齐');
    });

    test('旧 JSON 无网格键: 回落新默认, 不抛', () {
      final restored = CandleIndicator.fromJson({'height': 260.0, 'zIndex': -1});

      expect(restored.height, 260.0);
      expect(restored.horizontalGrid.mode, CandleBaseIndicator.defaultHorizontalGrid.mode);
      expect(restored.verticalGrid.mode, CandleBaseIndicator.defaultVerticalGrid.mode);
    });
  });
}
