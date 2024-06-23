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

import '../../providers/kline_controller_state_provider.dart';
import 'indicator_bar_item_view.dart';

class FlexiKlineIndicatorBar extends ConsumerStatefulWidget {
  const FlexiKlineIndicatorBar({
    super.key,
    this.height,
    this.alignment,
    this.padding,
    this.decoration,
    this.margin,
    required this.controller,
  });

  final double? height;
  final AlignmentGeometry? alignment;
  final EdgeInsetsGeometry? padding;
  final Decoration? decoration;
  final EdgeInsetsGeometry? margin;

  final FlexiKlineController controller;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _FlexiKliineIndicatorBarState();
}

class _FlexiKliineIndicatorBarState
    extends ConsumerState<FlexiKlineIndicatorBar> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final klineState = ref.watch(klineStateProvider(widget.controller));
    return Container(
      height: widget.height,
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
            ...klineState.supportMainIndicatorKeys.map((key) {
              return GestureDetector(
                key: key,
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  ref
                      .read(klineStateProvider(widget.controller).notifier)
                      .onTapMainIndicator(key);
                },
                child: IndicatorBarItemView(
                  indicatorKey: key,
                  selected: klineState.mainIndicatorKeys.contains(key),
                ),
              );
            }),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 10.r),
              color: theme.dividerLine,
              width: 1.r,
              height: 20.r,
            ),
            ...klineState.supportSubIndicatorKeys.map((key) {
              return GestureDetector(
                key: key,
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  ref
                      .read(klineStateProvider(widget.controller).notifier)
                      .onTapSubIndicator(key);
                },
                child: IndicatorBarItemView(
                  indicatorKey: key,
                  selected: klineState.subIndicatorKeys.contains(key),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
