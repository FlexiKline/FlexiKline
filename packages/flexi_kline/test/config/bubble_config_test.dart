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

/// [BubbleConfig] 的样式解析与序列化, 以及 [CandleIndicator] 日期气泡字段的序列化。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _red = Color(0xFFFF0000);
const _blue = Color(0xFF0000FF);

BubbleBorder _shapeOf(LabelStyle style) => style.decoration!.shape as BubbleBorder;

void main() {
  group('toLabelStyle', () {
    const config = BubbleConfig(
      text: TextAreaConfig(
        backgroundColor: _red,
        border: BorderSide(color: _blue, width: 2),
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      arrowSize: Size(12, 6),
      arrowRadius: 2,
    );

    test('箭头指向气泡所在侧的反方向, 箭头参数与边框圆角转入 BubbleBorder', () {
      for (final side in AxisDirection.values) {
        final shape = _shapeOf(config.toLabelStyle(side));
        expect(shape.direction, flipAxisDirection(side), reason: '$side');
        expect(shape.arrowSize, const Size(12, 6));
        expect(shape.arrowRadius, 2);
        expect(shape.side, const BorderSide(color: _blue, width: 2));
        expect(shape.borderRadius, const BorderRadius.all(Radius.circular(6)));
        expect(shape.gradient, isNull);
      }
    });

    test('背景色与排版沿用 text 的解析结果', () {
      final style = config.toLabelStyle(AxisDirection.up);
      final source = config.text.toLabelStyle();
      expect(style.decoration!.color, _red);
      expect(style.text, source.text);
      expect(style.padding, source.padding);
    });

    test('边框渐变随形状带入 BubbleBorder', () {
      const gradientConfig = BubbleConfig(
        text: TextAreaConfig(
          border: BorderSide(color: _blue),
          borderGradient: GradientConfig(),
        ),
      );

      final shape = _shapeOf(gradientConfig.toLabelStyle(AxisDirection.down, backgroundColor: _red));

      expect(shape.gradient, const GradientConfig().createGradient(baseColor: _blue));
    });

    test('同一实例 + 同一组主题色按方向返回 identical 的样式; 主题色变化时重新派生', () {
      final up = config.toLabelStyle(AxisDirection.up, textColor: _red);
      expect(identical(up, config.toLabelStyle(AxisDirection.up, textColor: _red)), isTrue);
      expect(identical(up, config.toLabelStyle(AxisDirection.down, textColor: _red)), isFalse);
      expect(identical(up, config.toLabelStyle(AxisDirection.up, textColor: _blue)), isFalse);
    });

    test('text 没有任何装饰时原样返回', () {
      const bare = BubbleConfig(text: TextAreaConfig());
      final style = bare.toLabelStyle(AxisDirection.up);
      expect(style.decoration, isNull);
      expect(identical(style, bare.text.toLabelStyle()), isTrue);
    });
  });

  group('序列化', () {
    test('非默认值往返', () {
      const config = BubbleConfig(
        text: TextAreaConfig(style: TextStyle(fontSize: 12), padding: EdgeInsets.all(3)),
        arrowSize: Size(12, 6),
        arrowRadius: 2,
        spacing: 6,
        placement: AxisDirection.left,
        flip: false,
      );

      final restored = BubbleConfig.fromJson(config.toJson());

      expect(restored.text.style.fontSize, 12);
      expect(restored.text.padding, const EdgeInsets.all(3));
      expect(restored.arrowSize, const Size(12, 6));
      expect(restored.arrowRadius, 2);
      expect(restored.spacing, 6);
      expect(restored.placement, AxisDirection.left);
      expect(restored.flip, isFalse);
    });

    test('空 JSON 取默认值; 未知 placement 回落 up', () {
      final restored = BubbleConfig.fromJson(const {});
      const defaults = BubbleConfig();

      expect(restored.placement, AxisDirection.up);
      expect(restored.flip, isTrue);
      expect(restored.spacing, defaults.spacing);
      expect(restored.arrowSize, defaults.arrowSize);
      expect(restored.arrowRadius, 0);
      expect(BubbleConfig.fromJson(const {'placement': 'middle'}).placement, AxisDirection.up);
    });

    test('CandleIndicator 的日期气泡字段往返, 缺键时取默认值', () {
      final indicator = CandleIndicator(
        showDateMark: false,
        dateMarkDuration: 0,
        dateMark: const BubbleConfig(placement: AxisDirection.down),
      );

      final restored = CandleIndicator.fromJson(indicator.toJson());
      expect(restored.showDateMark, isFalse);
      expect(restored.dateMarkDuration, 0);
      expect(restored.dateMark.placement, AxisDirection.down);

      final json = CandleIndicator().toJson()
        ..remove('showDateMark')
        ..remove('dateMark')
        ..remove('dateMarkDuration');
      final defaults = CandleIndicator.fromJson(json);
      expect(defaults.showDateMark, isTrue);
      expect(defaults.dateMarkDuration, 2000);
      expect(defaults.dateMark.placement, AxisDirection.up);
    });
  });
}
