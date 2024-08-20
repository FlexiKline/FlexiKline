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

import 'package:example/src/constants/images.dart';
import 'package:example/src/theme/flexi_theme.dart';
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../widgets/no_thumb_scroll_behavior.dart';
import '../../widgets/shrink_icon_button.dart';

class FlexiKlineDrawToolsBar extends ConsumerStatefulWidget {
  const FlexiKlineDrawToolsBar({
    super.key,
    required this.controller,
  });

  final FlexiKlineController controller;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _FlexiKlineDrawToolsBarState();
}

class _FlexiKlineDrawToolsBarState
    extends ConsumerState<FlexiKlineDrawToolsBar> {
  final RegExp _exp = RegExp(r'(?<=[a-z])[A-Z]');

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
                child: Row(
                  children: DrawType.values.map((type) {
                    return ShrinkIconButton(
                      key: ValueKey(type),
                      onPressed: () {},
                      content:
                          'assets/svgs/${type.name.replaceAllMapped(_exp, (m) => '_${m.group(0)}').toLowerCase()}.svg',
                    );
                  }).toList(),
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
          ShrinkIconButton(
            onPressed: () {},
            // content: SvgRes.continuousDrawing,
            // content: Icons.dynamic_feed_rounded,
            content: Icons.auto_awesome_motion_rounded,
          ),
          ShrinkIconButton(
            onPressed: () {},
            content: SvgRes.magnetMode,
          ),
          ShrinkIconButton(
            onPressed: () {},
            content: Icons.visibility_outlined,
            // iconData: Icons.visibility_off_outlined,
          ),
          ShrinkIconButton(
            onPressed: () {},
            content: Icons.cleaning_services_rounded,
          ),
          ShrinkIconButton(
            onPressed: () {},
            content: Icons.login_rounded,
          ),
          // ShrinkIconButton(
          //   onPressed: () {},
          //   content: Text(
          //     'Exit',
          //     style: theme.t1s14w400,
          //   ),
          //   // content: 'Exit',
          // ),
        ],
      ),
    );
  }
}
