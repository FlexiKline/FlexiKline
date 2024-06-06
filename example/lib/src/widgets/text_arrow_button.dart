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

class TextArrowButton extends ConsumerWidget {
  const TextArrowButton({
    super.key,
    this.style,
    this.onPressed,
    required this.text,
    this.textStyle,
    this.iconSize,
    this.iconColor,
    required this.iconStatus,
  });

  final ButtonStyle? style;
  final VoidCallback? onPressed;

  final String text;
  final TextStyle? textStyle;
  final double? iconSize;
  final Color? iconColor;
  final ValueNotifier<bool> iconStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return TextButton(
      style: style ??
          const ButtonStyle(
            padding: MaterialStatePropertyAll(EdgeInsets.zero),
          ),
      onPressed: onPressed,
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
                  size: iconSize,
                  color: iconColor ?? theme.t1,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
