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

/// `TextAreaConfig.toLabelStyle` 的解析与记忆，以及 `gradient` / `shadows` 的序列化。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _red = Color(0xFFFF0000);
const _green = Color(0xFF00FF00);
const _blue = Color(0xFF0000FF);

RoundedRectangleBorder _shapeOf(LabelStyle style) => style.decoration!.shape as RoundedRectangleBorder;

void main() {
  group('toLabelStyle 记忆', () {
    test('同一实例 + 同一组主题色返回同一个 LabelStyle', () {
      const config = TextAreaConfig(backgroundColor: _red);

      final a = config.toLabelStyle(textColor: _green, borderColor: _blue);
      final b = config.toLabelStyle(textColor: _green, borderColor: _blue);

      expect(identical(a, b), isTrue);
    });

    test('主题色变化时重新解析', () {
      const config = TextAreaConfig();

      final a = config.toLabelStyle(textColor: _green);
      final b = config.toLabelStyle(textColor: _blue);

      expect(identical(a, b), isFalse);
      expect(b.text.color, _blue);
      // 单项记忆: 切回去也重新解析, 但值相等。
      final c = config.toLabelStyle(textColor: _green);
      expect(identical(a, c), isFalse);
      expect(c, a);
    });

    test('不同实例（即使值相同）各自解析', () {
      // 刻意不用 const: const 会把两个值相同的配置规范化成同一实例。
      // ignore: prefer_const_constructors
      final a = TextAreaConfig(padding: EdgeInsets.all(2)).toLabelStyle();
      // ignore: prefer_const_constructors
      final b = TextAreaConfig(padding: EdgeInsets.all(2)).toLabelStyle();

      expect(identical(a, b), isFalse);
      expect(a, b);
    });

    test('copyWith 产生的新实例不命中旧记忆', () {
      const config = TextAreaConfig(backgroundColor: _red);
      final a = config.toLabelStyle();
      final b = config.copyWith(backgroundColor: _green).toLabelStyle();

      expect(identical(a, b), isFalse);
      expect(b.decoration!.color, _green);
    });
  });

  group('toLabelStyle 解析', () {
    test('配置颜色优先，主题色只兜底', () {
      const config = TextAreaConfig(
        style: TextStyle(fontSize: 10, color: _red),
        backgroundColor: _red,
        border: BorderSide(color: _red),
      );

      final style = config.toLabelStyle(textColor: _green, backgroundColor: _green, borderColor: _green);

      expect(style.text.color, _red);
      expect(style.decoration!.color, _red);
      expect(_shapeOf(style).side.color, _red);
    });

    test('配置未指定颜色时用主题色', () {
      const config = TextAreaConfig(
        style: TextStyle(fontSize: 10),
        border: BorderSide(width: 1, color: Color(0x00000000)),
      );

      final style = config.toLabelStyle(textColor: _green, backgroundColor: _blue, borderColor: _red);

      expect(style.text.color, _green);
      expect(style.decoration!.color, _blue);
      expect(_shapeOf(style).side.color, _red);
    });

    test('排版与内边距字段原样转入，缺省值落到 LabelStyle 默认值', () {
      const strut = StrutStyle(height: 1.2);
      const config = TextAreaConfig(
        textAlign: TextAlign.center,
        strutStyle: strut,
        maxLines: 2,
        minWidth: 10,
        maxWidth: 80,
        padding: EdgeInsets.all(3),
        borderRadius: BorderRadius.all(Radius.circular(2)),
      );

      final style = config.toLabelStyle();
      expect(style.textAlign, TextAlign.center);
      expect(style.strutStyle, strut);
      expect(style.maxLines, 2);
      expect(style.minWidth, 10);
      expect(style.maxWidth, 80);
      expect(style.padding, const EdgeInsets.all(3));
      expect(_shapeOf(style).borderRadius, const BorderRadius.all(Radius.circular(2)));

      final defaults = const TextAreaConfig().toLabelStyle();
      expect(defaults.minWidth, 0);
      expect(defaults.maxWidth, double.infinity);
      expect(defaults.padding, EdgeInsets.zero);
    });

    test('textWidth 并入 maxWidth，取两者较小值', () {
      expect(const TextAreaConfig(textWidth: 40).toLabelStyle().maxWidth, 40);
      expect(const TextAreaConfig(textWidth: 40, maxWidth: 30).toLabelStyle().maxWidth, 30);
      expect(const TextAreaConfig(textWidth: 40, maxWidth: 60).toLabelStyle().maxWidth, 40);
    });

    test('没有任何装饰字段时 decoration 为 null', () {
      expect(const TextAreaConfig().toLabelStyle().decoration, isNull);
      // 主题色只兜底文字时也不产生装饰。
      expect(const TextAreaConfig().toLabelStyle(textColor: _green, borderColor: _blue).decoration, isNull);
    });

    test('有 gradient 时 decoration 只带 gradient，背景色作 baseColor', () {
      const config = TextAreaConfig(backgroundColor: _red, gradient: GradientConfig());

      final decoration = config.toLabelStyle().decoration!;

      expect(decoration.color, isNull);
      expect(decoration.gradient, const GradientConfig().createGradient(baseColor: _red));
    });

    test('gradient 的背景色可来自主题兜底', () {
      const config = TextAreaConfig(gradient: GradientConfig());

      final decoration = config.toLabelStyle(backgroundColor: _blue).decoration!;

      expect(decoration.color, isNull);
      expect(decoration.gradient, const GradientConfig().createGradient(baseColor: _blue));
    });

    test('动态 gradient 缺背景色时不生效；给定 colors 的 gradient 不依赖背景色', () {
      expect(const TextAreaConfig(gradient: GradientConfig()).toLabelStyle().decoration!.gradient, isNull);

      const fixed = GradientConfig(colors: [_red, _blue]);
      final decoration = const TextAreaConfig(gradient: fixed).toLabelStyle().decoration!;
      expect(decoration.color, isNull);
      expect(decoration.gradient!.colors, const [_red, _blue]);
    });

    test('shadows 原样转入 decoration', () {
      const shadows = [BoxShadow(color: _red, blurRadius: 4, offset: Offset(1, 2))];

      final decoration = const TextAreaConfig(shadows: shadows).toLabelStyle().decoration!;

      expect(decoration.shadows, shadows);
      expect(decoration.color, isNull);
    });
  });

  group('gradient / shadows 序列化', () {
    test('JSON 往返', () {
      const config = TextAreaConfig(
        backgroundColor: _red,
        gradient: GradientConfig(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          startAlpha: 0.8,
          endAlpha: 0.1,
          stops: [0.0, 1.0],
          colors: [_red, _blue],
        ),
        shadows: [
          BoxShadow(color: _green, offset: Offset(1, 2), blurRadius: 3, spreadRadius: 1, blurStyle: BlurStyle.outer),
          BoxShadow(color: _blue, blurRadius: 6),
        ],
      );

      final restored = TextAreaConfig.fromJson(config.toJson());

      final gradient = restored.gradient!;
      expect(gradient.begin, Alignment.centerLeft);
      expect(gradient.end, Alignment.centerRight);
      expect(gradient.startAlpha, 0.8);
      expect(gradient.endAlpha, 0.1);
      expect(gradient.stops, const [0.0, 1.0]);
      expect(gradient.colors, const [_red, _blue]);
      expect(restored.shadows, config.shadows);
    });

    test('未设置时 toJson 不写这两个键', () {
      final json = const TextAreaConfig().toJson();

      expect(json.containsKey('gradient'), isFalse);
      expect(json.containsKey('shadows'), isFalse);
    });

    test('不含这两个字段的旧 JSON 照常反序列化', () {
      final legacy = const TextAreaConfig(backgroundColor: _red, padding: EdgeInsets.all(2)).toJson()
        ..remove('gradient')
        ..remove('shadows');

      final restored = TextAreaConfig.fromJson(legacy);

      expect(restored.gradient, isNull);
      expect(restored.shadows, isNull);
      expect(restored.backgroundColor, _red);
      expect(restored.padding, const EdgeInsets.all(2));
    });
  });
}
