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

import 'package:example/src/theme/flexi_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

typedef IndicatorBarItemBuilder = Widget Function(BuildContext, Indicator);

class FlexiIndicatorBar extends ConsumerStatefulWidget {
  const FlexiIndicatorBar({
    super.key,
    this.alignment,
    this.padding,
    this.decoration,
    this.margin,
    required this.controller,
  });

  final AlignmentGeometry? alignment;
  final EdgeInsetsGeometry? padding;
  final Decoration? decoration;
  final EdgeInsetsGeometry? margin;

  final FlexiKlineController controller;

  // final Set<SinglePaintObjectIndicator> mainIndicators;
  // final Set<ValueKey> mainIndicatorKeys;
  // final ValueChanged<SinglePaintObjectIndicator>? onTapMainIndicator;
  // final Set<Indicator> subIndicators;
  // final Set<ValueKey> subIndicatorKeys;
  // final ValueChanged<Indicator>? onTapSubIndicator;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _FlexiIndicatorBarState();
}

class _FlexiIndicatorBarState extends ConsumerState<FlexiIndicatorBar> {
  @override
  void initState() {
    super.initState();
  }

  void onTapMainIndicator(ValueKey key) {
    if (widget.controller.mainIndicatorKeys.contains(key)) {
      widget.controller.delIndicatorInMain(key);
    } else {
      widget.controller.addIndicatorInMain(key);
    }
    setState(() {});
  }

  void onTapSubIndicator(ValueKey key) {
    if (widget.controller.subIndicatorKeys.contains(key)) {
      widget.controller.delIndicatorInSub(key);
    } else {
      widget.controller.addIndicatorInSub(key);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    return Container(
      alignment: widget.alignment ?? AlignmentDirectional.centerStart,
      padding: widget.padding,
      margin: widget.margin,
      decoration: widget.decoration,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ...widget.controller.supportMainIndicatorKeys.map((key) {
              return GestureDetector(
                key: key,
                onTap: () => onTapMainIndicator(key),
                child: IndicatorView(
                  indicatorKey: key,
                  selected: widget.controller.mainIndicatorKeys.contains(key),
                ),
              );
            }),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 10.r),
              color: theme.dividerLine,
              width: 1.r,
              height: 20.r,
            ),
            ...widget.controller.supportSubIndicatorKeys.map((key) {
              return GestureDetector(
                key: key,
                onTap: () => onTapSubIndicator(key),
                child: IndicatorView(
                  indicatorKey: key,
                  selected: widget.controller.subIndicatorKeys.contains(key),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class IndicatorView extends ConsumerWidget {
  const IndicatorView({
    super.key,
    required this.indicatorKey,
    this.selected = false,
  });

  final ValueKey indicatorKey;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return Container(
      key: indicatorKey,
      padding: EdgeInsets.all(8.r),
      child: Text(
        indicatorKey.value.toString().toUpperCase(),
        style: theme.t2s12w400.copyWith(
          color: selected ? theme.t1 : null,
          fontWeight: selected ? FontWeight.bold : null,
        ),
      ),
    );
  }
}
