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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/flexi_theme.dart';

class RightArrow extends ConsumerWidget {
  const RightArrow({
    super.key,
    this.value,
    this.style,
  });

  final String? value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    if (value != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value!,
            style: style ?? theme.t3s14w400,
          ),
          Icon(
            Icons.keyboard_arrow_right_outlined,
            color: theme.t3,
            size: 24.r,
          )
        ],
      );
    }
    return Icon(
      Icons.keyboard_arrow_right_outlined,
      color: theme.t3,
      size: 24.r,
    );
  }
}
