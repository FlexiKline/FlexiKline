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
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BasicInfoView extends ConsumerWidget {
  const BasicInfoView({
    super.key,
    required this.title,
    required this.value,
    this.titleStyle,
    this.valueStyle,
    this.padding,
    this.mainAxisAlignment = MainAxisAlignment.spaceBetween,
    this.spacing = 0,
  });

  final String title;
  final String value;
  final TextStyle? titleStyle;
  final TextStyle? valueStyle;
  final EdgeInsetsGeometry? padding;
  final MainAxisAlignment mainAxisAlignment;
  final double spacing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return Container(
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.start,
            style: titleStyle ?? theme.t2s12w400,
          ),
          SizedBox(width: spacing),
          Text(
            value,
            textAlign: TextAlign.end,
            style: valueStyle ?? theme.t1s12w400,
          ),
        ],
      ),
    );
  }
}