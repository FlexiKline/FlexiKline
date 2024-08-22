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
import 'package:flutter_svg/svg.dart';

import '../../constants/images.dart';
import '../../theme/flexi_theme.dart';
import '../../widgets/flexi_popup_menu_button.dart';
import '../../widgets/shrink_icon_button.dart';

final drawToolbarInitPosition = Offset(60.r, 200.r);

// 绘制工具条
class FlexiKlineDrawToolbar extends ConsumerStatefulWidget {
  const FlexiKlineDrawToolbar({
    super.key,
    required this.controller,
  });

  final FlexiKlineController controller;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _FlexiKlineDrawToolbarState();
}

class _FlexiKlineDrawToolbarState extends ConsumerState<FlexiKlineDrawToolbar> {
  int lineWeight = 1;
  final List<int> lineWeightList = [1, 2, 3, 4];

  LineType lineType = LineType.solid;

  void onSelectLineWeight(int value) {
    setState(() {
      lineWeight = value;
    });
    // TODO: 通过 controller 处理lineWeight的改变.
  }

  void onSelectLineType(LineType type) {
    setState(() {
      lineType = type;
    });
    // TODO: 通过 controller 处理lineType的改变.
  }

  @override
  Widget build(BuildContext context) {
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
            size: 20.r,
          ),
          ShrinkIconButton(
            onPressed: () {},
            content: SvgRes.paintColor,
            width: 18.r,
            padding: 6.r,
          ),
          FlexiPopupMenuButton(
            initialValue: lineWeight,
            tooltip: 'Line Weight',
            menuItems: lineWeightList,
            minimumSize: Size(22.r, 22.r),
            maximumSize: Size(50.r, 22.r),
            itemBuilder: (context, value, isMenuItem) {
              return SizedBox(
                width: 22.r,
                height: 22.r,
                child: SvgPicture.asset(
                  'assets/svgs/line_weight_$value.svg',
                  colorFilter: ColorFilter.mode(theme.t1, BlendMode.srcIn),
                ),
              );
            },
            onSelected: onSelectLineWeight,
          ),
          FlexiPopupMenuButton(
            initialValue: lineType,
            tooltip: 'Line Type',
            menuItems: LineType.values,
            minimumSize: Size(22.r, 22.r),
            maximumSize: Size(50.r, 22.r),
            itemBuilder: (context, value, isMenuItem) {
              return SizedBox(
                width: 22.r,
                height: 22.r,
                child: SvgPicture.asset(
                  'assets/svgs/line_type_${value.name}.svg',
                  colorFilter: ColorFilter.mode(theme.t1, BlendMode.srcIn),
                ),
              );
            },
            onSelected: onSelectLineType,
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
