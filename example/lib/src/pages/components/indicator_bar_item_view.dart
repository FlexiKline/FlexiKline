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
import 'package:flutter_screenutil/flutter_screenutil.dart';

class IndicatorBarItemView extends ConsumerWidget {
  const IndicatorBarItemView({
    super.key,
    required this.indicatorKey,
    this.selected = false,
    this.padding,
  });

  final ValueKey indicatorKey;
  final bool selected;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return Container(
      key: indicatorKey,
      padding: padding ?? EdgeInsets.all(8.r),
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
