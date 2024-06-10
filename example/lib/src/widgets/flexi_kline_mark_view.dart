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
import 'package:example/src/theme/export.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FlexiKlineMarkView extends ConsumerWidget {
  const FlexiKlineMarkView({
    super.key,
    this.showLogo = true,
    this.alignment,
    this.margin,
    this.opacity = 0.2,
  });

  final bool showLogo;
  final AlignmentGeometry? alignment;
  final EdgeInsetsGeometry? margin;
  final double opacity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return Container(
      alignment: alignment ?? AlignmentDirectional.bottomStart,
      margin: margin,
      padding: EdgeInsetsDirectional.symmetric(horizontal: 6.r),
      child: Opacity(
        opacity: opacity,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Offstage(
              offstage: !showLogo,
              child: Padding(
                padding: EdgeInsetsDirectional.only(end: 6.r),
                child: Image.asset(
                  Images.logo,
                  width: 24.r,
                  height: 24.r,
                ),
              ),
            ),
            Text(
              'FlexiKline',
              style: theme.t1s18w700,
            ),
          ],
        ),
      ),
    );
  }
}
