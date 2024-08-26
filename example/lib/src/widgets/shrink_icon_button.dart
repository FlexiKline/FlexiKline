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

class ShrinkIconButton extends ConsumerWidget {
  const ShrinkIconButton({
    super.key,
    required this.content,
    this.tooltip,
    this.onPressed,
    this.width,
    this.height,
    this.padding,
    this.color,
  });

  final dynamic content;
  final String? tooltip;
  final VoidCallback? onPressed;

  final double? width;
  final double? height;
  final double? padding;
  final Color? color;

  double get defWidth => 22.r;

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
      tooltip: tooltip,
      icon: _buildContent(context, ref),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    if (content is IconData) {
      return Icon(
        content,
        size: math.max(width ?? defWidth, height ?? 0),
        color: color ?? theme.t2,
      );
    } else if (content is String) {
      if (content.endsWith('.svg')) {
        return SvgPicture.asset(
          content,
          width: width ?? defWidth,
          height: height,
          colorFilter: ColorFilter.mode(color ?? theme.t1, BlendMode.srcIn),
        );
      } else if (content.endsWith('.png')) {
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
        width: width,
        height: height,
        color: color,
      );
    }
    return const SizedBox.shrink();
  }
}
