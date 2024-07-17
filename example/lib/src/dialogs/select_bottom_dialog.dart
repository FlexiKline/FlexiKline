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
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import '../theme/flexi_theme.dart';
import '../utils/dialog_manager.dart';

class SelectBottomDialog<T> extends ConsumerWidget {
  const SelectBottomDialog({
    super.key,
    required this.title,
    required this.list,
    this.current,
  });

  final String title;
  final List<T> list;
  final T? current;

  static String dialogTag(String title) => 'SelectBottomDialog-$title';

  static Future<T?> show<T>({
    required String title,
    required List<T> list,
    T? current,
  }) async {
    return DialogManager().showBottomDialog(
      dialogTag: dialogTag(title),
      builder: (context) => SelectBottomDialog(
        title: title,
        list: list,
        current: current,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return Container(
      width: ScreenUtil().screenWidth,
      margin: EdgeInsetsDirectional.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: 16.r,
              vertical: 12.r,
            ),
            child: Text(
              title,
              style: theme.t1s20w700,
            ),
          ),
          ...list.map((e) => ListTile(
                key: ValueKey(e),
                onTap: () {
                  SmartDialog.dismiss(tag: dialogTag(title), result: e);
                },
                title: Text(e.toString(), style: theme.t1s14w400),
                trailing: current == e
                    ? Icon(Icons.check_outlined, size: 24.r)
                    : null,
              )),
        ],
      ),
    );
  }
}
