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

import 'dart:math' as math;

import 'package:example/src/theme/flexi_theme.dart';
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FlexiKlineSizeSlider extends ConsumerStatefulWidget {
  const FlexiKlineSizeSlider({
    super.key,
    required this.controller,
    this.maxSize,
    this.axis = Axis.vertical,
    this.divisions,
    this.onStateChanged,
  });

  final FlexiKlineController controller;
  final Size? maxSize;
  final Axis axis;
  // 限制滑动按[10~100]平均分
  final int? divisions;
  final ValueChanged<bool>? onStateChanged;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _FlexiKlineSizeSliderState();
}

class _FlexiKlineSizeSliderState extends ConsumerState<FlexiKlineSizeSlider> {
  FlexiKlineController get controller => widget.controller;

  late final int divisions;
  late Size maxSize;

  double get minValue {
    return widget.axis == Axis.vertical
        ? controller.mainMinSize.height
        : controller.mainMinSize.width;
  }

  double get maxValue {
    return widget.axis == Axis.vertical ? maxSize.height : maxSize.width;
  }

  /// 当前Kline的主区大小对应Slider的值.
  Size get curSize => controller.mainRect.size;

  double get curValue {
    return widget.axis == Axis.vertical ? curSize.height : curSize.width;
  }

  @override
  void initState() {
    super.initState();
    maxSize = widget.maxSize ?? Size(ScreenUtil().screenWidth, 800);
    maxSize = Size(
      math.max(curSize.width, maxSize.width),
      math.max(curSize.height, maxSize.height),
    );
    divisions = widget.divisions?.clamp(10, 100) ?? 100;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    return Slider(
      value: curValue,
      min: minValue,
      max: maxValue,
      divisions: divisions,
      thumbColor: theme.t1,
      overlayColor: MaterialStatePropertyAll(theme.transparent),
      onChangeStart: (value) {
        widget.onStateChanged?.call(true);
      },
      onChangeEnd: (value) {
        widget.onStateChanged?.call(false);
      },
      onChanged: (value) {
        setState(() {
          if (widget.axis == Axis.vertical) {
            widget.controller.setMainSize(Size(curSize.width, value));
          } else {
            widget.controller.setMainSize(Size(value, curSize.height));
          }
        });
      },
    );
  }
}
