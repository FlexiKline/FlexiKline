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

class TextArrowButton extends ConsumerWidget {
  const TextArrowButton({
    super.key,
    this.onPressed,
    required this.text,
    this.background,
    this.textStyle,
    this.iconSize,
    this.iconColor,
    required this.iconStatus,
  });

  final VoidCallback? onPressed;

  final Color? background;
  final String text;
  final TextStyle? textStyle;
  final double? iconSize;
  final Color? iconColor;
  final ValueNotifier<bool> iconStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsetsDirectional.only(
          start: 6.r,
          end: 2.r,
          top: 4.r,
          bottom: 4.r,
        ),
        margin: EdgeInsetsDirectional.only(start: 6.r),
        alignment: AlignmentDirectional.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(5.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: textStyle ?? theme.t1s14w500,
            ),
            ValueListenableBuilder(
              valueListenable: iconStatus,
              builder: (context, value, child) {
                return RotationTransition(
                  turns: AlwaysStoppedAnimation(value ? 0.5 : 0),
                  child: Icon(
                    Icons.arrow_drop_down,
                    size: iconSize ?? 18.r,
                    color: iconColor ?? theme.t1,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
