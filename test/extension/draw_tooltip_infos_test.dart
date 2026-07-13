// Copyright 2024 Andy.Zhao
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:ui' as ui;

import 'package:flexi_kline/src/extension/export.dart';
import 'package:flexi_kline/src/model/tooltip_info/tooltip_info.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('drawTooltipInfos 空列表返回 Size.zero 且不触发回调', () {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    var layoutCalled = false;

    final size = canvas.drawTooltipInfos(
      offset: Offset.zero,
      tooltipInfos: const [],
      onLayout: (_, __) => layoutCalled = true,
    );

    expect(size, Size.zero);
    expect(layoutCalled, isFalse);
    recorder.endRecording().dispose();
  });

  test('drawTooltipInfos 返回逐项布局区域', () {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const padding = EdgeInsets.all(4);
    const style = TextStyle(fontSize: 10, height: 1);

    Rect? bounds;
    List<Rect>? itemBounds;

    final size = canvas.drawTooltipInfos(
      offset: const Offset(0, 0),
      tooltipInfos: [
        TooltipInfo(label: 'Open', value: '1.0'),
        TooltipInfo(label: 'Close', value: '2.0'),
      ],
      defaultStyle: style,
      padding: padding,
      onLayout: (cardBounds, items) {
        bounds = cardBounds;
        itemBounds = items;
      },
    );

    expect(size.width, greaterThan(0));
    expect(bounds, isNotNull);
    expect(itemBounds, hasLength(2));
    expect(itemBounds![0].left, bounds!.left);
    expect(itemBounds![1].left, bounds!.left);
    expect(itemBounds![0].right, bounds!.right);
    expect(itemBounds![1].right, bounds!.right);
    expect(itemBounds![0].bottom, itemBounds![1].top);

    recorder.endRecording().dispose();
  });

  test('drawTooltipInfos 超宽时只约束 value 列宽度', () {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const style = TextStyle(fontSize: 10, height: 1);

    Rect? bounds;

    canvas.drawTooltipInfos(
      offset: const Offset(0, 0),
      tooltipInfos: [
        TooltipInfo(label: 'Label', value: 'VeryLongValueText'),
      ],
      defaultStyle: style,
      maxWidth: 60,
      onLayout: (cardBounds, _) => bounds = cardBounds,
    );

    expect(bounds!.width, lessThanOrEqualTo(60));

    recorder.endRecording().dispose();
  });

  test('drawTooltipInfos RTL 锚点返回实际 bounds', () {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const style = TextStyle(fontSize: 10, height: 1);

    Rect? bounds;

    canvas.drawTooltipInfos(
      offset: const Offset(100, 0),
      tooltipInfos: [
        TooltipInfo(label: 'A', value: '1'),
      ],
      drawDirection: DrawDirection.rtl,
      defaultStyle: style,
      onLayout: (cardBounds, _) => bounds = cardBounds,
    );

    expect(bounds!.right, closeTo(100, 0.01));

    recorder.endRecording().dispose();
  });
}
