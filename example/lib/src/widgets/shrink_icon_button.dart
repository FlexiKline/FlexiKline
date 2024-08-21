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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

final defaultShrinkIconSize = 20.r;

class ShrinkIconButton extends ConsumerWidget {
  const ShrinkIconButton({
    super.key,
    required this.content,
    this.width,
    this.height,
    this.padding,
    this.onPressed,
    this.color,
  });

  final dynamic content;

  final double? width;
  final double? height;
  final double? padding;
  final VoidCallback? onPressed;
  final Color? color;

  double get defWidth => defaultShrinkIconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      key: key,
      onPressed: onPressed,
      padding: EdgeInsets.all(padding ?? 4.r),
      constraints: const BoxConstraints(),
      style: const ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: _buildContent(context, ref),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    if (content is IconData) {
      return Icon(
        content,
        size: math.max(width ?? defWidth, height ?? 0),
        color: color ?? theme.t1,
      );
    } else if (content is String) {
      if ((content as String).endsWith('.svg')) {
        return SvgPicture.asset(
          content,
          width: width ?? defWidth,
          height: height,
          colorFilter: ColorFilter.mode(color ?? theme.t1, BlendMode.srcIn),
        );
      } else if ((content as String).endsWith('.png')) {
        return Image.asset(
          content,
          width: width ?? defWidth,
          height: height,
          color: color ?? theme.t1,
        );
      }
    } else if (content is Widget) {
      return content;
    } else if (width != null || color != null) {
      return Container(
        key: key,
        width: width,
        height: height,
        color: color,
      );
    }
    return SizedBox.shrink(key: key);
  }
}
