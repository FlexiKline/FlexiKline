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

  void onTapMainIndicator(SinglePaintObjectIndicator indicator) {
    if (widget.controller.mainIndicatorKeys.contains(indicator.key)) {
      widget.controller.delIndicatorInMain(indicator.key);
    } else {
      widget.controller.addIndicatorInMain(indicator);
    }
    setState(() {});
  }

  void onTapSubIndicator(Indicator indicator) {
    if (widget.controller.subIndicatorKeys.contains(indicator.key)) {
      widget.controller.delIndicatorInSub(indicator.key);
    } else {
      widget.controller.addIndicatorInSub(indicator);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
            ...widget.controller.supportMainIndicators.map((indicator) {
              return GestureDetector(
                key: indicator.key,
                onTap: () => onTapMainIndicator(indicator),
                child: IndicatorView(
                  indicator: indicator,
                  selected: widget.controller.mainIndicatorKeys.contains(
                    indicator.key,
                  ),
                ),
              );
            }),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 10.r),
              color: Colors.black,
              width: 1.r,
              height: 20.r,
            ),
            ...widget.controller.supportSubIndicators.map((indicator) {
              return GestureDetector(
                key: indicator.key,
                onTap: () => onTapSubIndicator(indicator),
                child: IndicatorView(
                  indicator: indicator,
                  selected: widget.controller.subIndicatorKeys.contains(
                    indicator.key,
                  ),
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
    required this.indicator,
    this.selected = false,
  });

  final Indicator indicator;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      key: indicator.key,
      padding: EdgeInsets.all(8.r),
      child: Text(
        indicator.name,
        style: theme.textTheme.bodySmall?.copyWith(
          color: selected ? Colors.black : null,
          fontWeight: selected ? FontWeight.bold : null,
        ),
      ),
    );
  }
}
