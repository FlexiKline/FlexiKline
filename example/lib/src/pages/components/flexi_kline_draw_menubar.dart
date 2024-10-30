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
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../widgets/no_thumb_scroll_behavior.dart';
import '../../widgets/shrink_icon_button.dart';

// 绘制工具菜单栏
class FlexiKlineDrawMenubar extends ConsumerStatefulWidget {
  const FlexiKlineDrawMenubar({
    super.key,
    required this.controller,
  });

  final FlexiKlineController controller;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _FlexiKlineDrawMenubarState();
}

class _FlexiKlineDrawMenubarState extends ConsumerState<FlexiKlineDrawMenubar> {
  // final RegExp _exp = RegExp(r'(?<=[a-z])[A-Z]');

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    return Container(
      alignment: AlignmentDirectional.centerStart,
      padding: EdgeInsetsDirectional.symmetric(horizontal: 8.r),
      child: Row(
        children: [
          Expanded(
            child: ScrollConfiguration(
              behavior: NoThumbScrollBehavior().copyWith(scrollbars: false),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: ValueListenableBuilder(
                  valueListenable: widget.controller.drawStateLinstener,
                  builder: (context, state, child) {
                    final drawType = state.object?.type;
                    return Row(
                      children: widget.controller.supportDrawTypes.map((type) {
                        return ShrinkIconButton(
                          key: ValueKey(type),
                          onPressed: () {
                            widget.controller.startDraw(type);
                          },
                          content: 'assets/svgs/${type.id}.svg',
                          color: drawType == type ? theme.t1 : theme.t2,
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
          ),
          Container(
            color: theme.dividerLine,
            width: 1.r,
            height: 18.r,
            margin: EdgeInsets.symmetric(horizontal: 4.r),
          ),
          ValueListenableBuilder(
            valueListenable: widget.controller.drawContinuousListener,
            builder: (context, isOn, child) => ShrinkIconButton(
              onPressed: () {
                widget.controller.setDrawContinuous(!isOn);
              },
              // content: SvgRes.continuousDrawing,
              // content: Icons.dynamic_feed_rounded,
              content: Icons.auto_awesome_motion_rounded,
              color: isOn ? theme.t1 : theme.t2,
            ),
          ),
          ValueListenableBuilder(
            valueListenable: widget.controller.drawMagnetModeListener,
            builder: (context, mode, child) => ShrinkIconButton(
              onPressed: () {
                widget.controller.setDrawMagnetMode(mode.next);
              },
              color: mode.isNormal ? theme.t2 : Colors.blueAccent,
              content: 'assets/svgs/magnet_mode_${mode.name}.svg',
            ),
          ),
          ValueListenableBuilder(
            valueListenable: widget.controller.drawVisibilityListener,
            builder: (context, isShow, child) => ShrinkIconButton(
              onPressed: () {
                widget.controller.setDrawVisibility(!isShow);
              },
              content: isShow
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              // iconData: Icons.visibility_off_outlined,
            ),
          ),
          ShrinkIconButton(
            onPressed: () {
              widget.controller.deleteAllDrawObject();
            },
            content: Icons.cleaning_services_rounded,
          ),
          ShrinkIconButton(
            onPressed: () {},
            content: Icons.login_rounded,
          ),
        ],
      ),
    );
  }
}
