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

/// `TooltipConfig.toDecoration` 的兜底与记忆，以及卡片装饰字段的序列化。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart' show MainAxisAlignment;
import 'package:flutter_test/flutter_test.dart';

const _red = Color(0xFFFF0000);
const _green = Color(0xFF00FF00);
const _blue = Color(0xFF0000FF);

const _base = TooltipConfig(margin: EdgeInsets.zero, padding: EdgeInsets.zero, style: TextStyle());

void main() {
  group('toDecoration', () {
    test('未配背景色时用传入的主题色', () {
      expect(_base.toDecoration(backgroundColor: _red)!.color, _red);
    });

    test('配置的背景色优先于主题色', () {
      final config = _base.copyWith(backgroundColor: _green);
      expect(config.toDecoration(backgroundColor: _red)!.color, _green);
    });

    test('没有任何装饰时返回 null', () {
      expect(_base.toDecoration(), isNull);
    });

    test('边框与圆角进形状, 渐变边框用 GradientRoundedRectangleBorder', () {
      const radius = BorderRadius.all(Radius.circular(6));
      final plain = _base
          .copyWith(
            border: const BorderSide(color: _blue),
            borderRadius: radius,
          )
          .toDecoration();
      final shape = plain!.shape as RoundedRectangleBorder;
      expect(shape.side.color, _blue);
      expect(shape.borderRadius, radius);

      final gradient = _base
          .copyWith(
            border: const BorderSide(color: _blue),
            borderGradient: const GradientConfig(colors: [_red, _green]),
          )
          .toDecoration();
      expect(gradient!.shape, isA<GradientRoundedRectangleBorder>());
    });

    test('背景渐变替代背景色, 阴影原样带上', () {
      const shadows = [BoxShadow(color: _blue, blurRadius: 4)];
      final decoration = _base
          .copyWith(
            gradient: const GradientConfig(colors: [_red, _green]),
            shadows: shadows,
          )
          .toDecoration(backgroundColor: _red);
      expect(decoration!.color, isNull);
      expect(decoration.gradient, isNotNull);
      expect(decoration.shadows, shadows);
    });

    test('同一实例 + 同一主题色返回同一个实例, 主题色变化时重新解析', () {
      final a = _base.toDecoration(backgroundColor: _red);
      expect(identical(a, _base.toDecoration(backgroundColor: _red)), isTrue);

      final b = _base.toDecoration(backgroundColor: _blue);
      expect(identical(a, b), isFalse);
      expect(b!.color, _blue);
    });
  });

  test('卡片装饰字段 JSON 往返', () {
    final config = _base.copyWith(
      backgroundColor: _red,
      border: const BorderSide(color: _blue, width: 2),
      borderRadius: const BorderRadius.all(Radius.circular(6)),
      gradient: const GradientConfig(colors: [_red, _green]),
      borderGradient: const GradientConfig(colors: [_green, _blue]),
      shadows: const [BoxShadow(color: _blue, blurRadius: 4, offset: Offset(0, 2))],
    );

    final json = config.toJson();
    expect(json.containsKey('radius'), isFalse);
    final restored = TooltipConfig.fromJson(json);

    expect(restored.backgroundColor, config.backgroundColor);
    expect(restored.border, config.border);
    expect(restored.borderRadius, config.borderRadius);
    expect(restored.gradient?.toJson(), config.gradient?.toJson());
    expect(restored.borderGradient?.toJson(), config.borderGradient?.toJson());
    expect(restored.shadows, config.shadows);
  });

  test('布局字段 JSON 往返', () {
    // 默认: 最宽行定宽 + spaceBetween, spacing 8。
    final defaultJson = TooltipConfig.fromJson({
      ..._base.toJson(),
      'spacing': null,
      'alignment': null,
    });
    expect(defaultJson.spacing, 8);
    expect(defaultJson.alignment, MainAxisAlignment.spaceBetween);

    final custom = _base.copyWith(
      spacing: 12,
      alignment: MainAxisAlignment.spaceAround,
    );
    final restored = TooltipConfig.fromJson(custom.toJson());
    expect(restored.spacing, custom.spacing);
    expect(restored.alignment, MainAxisAlignment.spaceAround);

    final evenly = TooltipConfig.fromJson(
      custom.copyWith(alignment: MainAxisAlignment.spaceEvenly).toJson(),
    );
    expect(evenly.alignment, MainAxisAlignment.spaceEvenly);
  });
}
