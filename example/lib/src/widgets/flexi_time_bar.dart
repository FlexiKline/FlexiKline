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

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

typedef TimeBarItemBuilder = Widget Function(BuildContext, TimeBar);

class FlexiTimeBar extends StatelessWidget {
  const FlexiTimeBar({
    super.key,
    required this.timeBars,
    this.currTimeBar,
    this.alignment,
    this.padding,
    this.decoration,
    this.margin,
    this.onTapTimeBar,
    this.labelStyle,
    this.unselectedLabelStyle,
  });

  final AlignmentGeometry? alignment;
  final EdgeInsetsGeometry? padding;
  final Decoration? decoration;
  final EdgeInsetsGeometry? margin;

  final List<TimeBar> timeBars;
  final TimeBar? currTimeBar;
  final ValueChanged<TimeBar>? onTapTimeBar;
  final TextStyle? labelStyle;
  final TextStyle? unselectedLabelStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      alignment: alignment,
      padding: padding,
      margin: margin,
      decoration: decoration,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          ButtonBar(
            buttonPadding: EdgeInsets.zero,
            buttonHeight: 30.r,
            children: timeBars.map((bar) {
              return TextButton(
                key: ValueKey(bar),
                onPressed: () {
                  onTapTimeBar?.call(bar);
                },
                child: Text(
                  bar.bar,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: bar == currTimeBar ? Colors.black : null,
                    fontWeight: bar == currTimeBar ? FontWeight.bold : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
