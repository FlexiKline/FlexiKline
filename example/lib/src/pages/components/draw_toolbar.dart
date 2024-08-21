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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../constants/images.dart';
import '../../theme/flexi_theme.dart';
import '../../widgets/shrink_icon_button.dart';

final drawToolbarInitPosition = Offset(60.r, 200.r);

// 绘制工具栏
class DrawToolbar extends ConsumerWidget {
  const DrawToolbar({
    super.key,
    required this.controller,
  });

  final FlexiKlineController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeProvider);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(6.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 2.r, vertical: 4.r),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.drag_indicator_rounded,
            size: defaultShrinkIconSize,
          ),
          ShrinkIconButton(
            onPressed: () {},
            content: SvgRes.paintColor,
          ),
          ShrinkIconButton(
            onPressed: () {},
            content: SvgRes.lineWeight1,
          ),
          ShrinkIconButton(
            onPressed: () {},
            content: SvgRes.lineStyleLine,
          ),
          ShrinkIconButton(
            onPressed: () {},
            content: SvgRes.visualOrder,
          ),
          ShrinkIconButton(
            onPressed: () {},
            content: SvgRes.unlock,
          ),
          ShrinkIconButton(
            onPressed: () {},
            content: SvgRes.delete,
          ),
        ],
      ),
    );
  }
}
