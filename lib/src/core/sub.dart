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

import 'dart:ui';

import '../model/export.dart';

import 'binding_base.dart';
import 'interface.dart';
import 'setting.dart';

mixin SubBinding
    on KlineBindingBase, SettingBinding
    implements ISubChart, IState, ISubState {
  @override
  void initBinding() {
    super.initBinding();
    logd('init sub');
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose');
  }

  @override
  void paintSubChart(Canvas canvas, Size size) {
    /// 绘制 Volume
    paintVolChart(canvas, size, 0);
  }

  /// 绘制 Volume
  void paintVolChart(Canvas canvas, Size size, int index) {
    final data = curKlineData;
    if (data.list.isEmpty) return;
    int start = data.start;
    int end = data.end;

    final offset = startCandleDx - candleWidthHalf;
    final dyBottom = indicatorDrawBottom(index);
    for (var i = start; i < end; i++) {
      final model = data.list[i];
      final dx = offset - (i - start) * candleActualWidth;
      final isLong = model.close >= model.open;

      final dy = volToDy(model.vol, index);

      canvas.drawLine(
        Offset(dx, dy),
        Offset(dx, dyBottom),
        isLong ? volBarLongPaint : volBarShortPaint,
      );
    }
  }
}
