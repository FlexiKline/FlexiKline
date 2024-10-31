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
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class FlexiPopupHorizMenuButton<T> extends ConsumerWidget {
  FlexiPopupHorizMenuButton({
    super.key,
    required this.menuTag,
    this.initialValue,
    this.onSelected,
    this.menuAlignment = Alignment.topCenter,
    required this.itemBuilder,
    required this.child,
    this.showArrow = true,
    this.padding,
    this.constraints,
    this.tooltip,
  });

  final String menuTag;
  final T? initialValue;
  final ValueChanged<T>? onSelected;
  final Alignment menuAlignment;
  final List<PopupHorizMenuItem<T>> Function(BuildContext context) itemBuilder;
  final Widget child;
  final bool showArrow;

  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;
  final String? tooltip;
  final ValueNotifier<bool> _iconStatus = ValueNotifier(false);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      key: key,
      onPressed: () => showHorizMenuDialog(context, ref),
      padding: padding ?? EdgeInsets.all(1.r),
      constraints: const BoxConstraints(),
      style: const ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      tooltip: tooltip,
      icon: _buildMenuWidget(context, ref),
    );
  }

  Widget _buildMenuWidget(BuildContext context, WidgetRef ref) {
    if (showArrow) {
      final theme = ref.read(themeProvider);
      return Container(
        constraints: constraints ??
            BoxConstraints(
              minHeight: 32.r,
              minWidth: 32.r,
            ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            child,
            ValueListenableBuilder(
              valueListenable: _iconStatus,
              builder: (context, value, child) {
                return RotationTransition(
                  turns: AlwaysStoppedAnimation(value ? 0.5 : 0),
                  child: Icon(
                    Icons.arrow_drop_down,
                    size: 14.r,
                    color: theme.t1,
                  ),
                  // child: SvgPicture.asset(
                  //   SvgRes.verticalArrow,
                  //   width: 12.r,
                  //   height: 12.r,
                  //   colorFilter: ColorFilter.mode(theme.t1, BlendMode.srcIn),
                  // ),
                );
              },
            ),
          ],
        ),
      );
    }
    return child;
  }

  void showHorizMenuDialog(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeProvider);
    SmartDialog.dismiss(tag: menuTag);
    _iconStatus.value = true;
    SmartDialog.showAttach(
      tag: menuTag,
      targetContext: context,
      maskColor: theme.transparent,
      alignment: menuAlignment,
      builder: (context) {
        return Container(
          height: 32.r,
          margin: EdgeInsets.only(bottom: 2.r),
          padding: EdgeInsets.symmetric(horizontal: 4.r, vertical: 2.r),
          decoration: BoxDecoration(
            color: theme.cardBg,
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: itemBuilder(context).map((item) {
              return IconButton(
                key: item.key ?? ValueKey(item.value),
                padding: EdgeInsets.all(item.padding ?? 4.r),
                constraints: const BoxConstraints(),
                style: ButtonStyle(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: WidgetStateProperty.all(
                    initialValue == item.value
                        ? theme.gridLine
                        : Colors.transparent,
                  ),
                ),
                tooltip: item.tooltip,
                onPressed: () {
                  onSelected?.call(item.value);
                  SmartDialog.dismiss(tag: menuTag);
                },
                icon: item.child,
              );
            }).toList(),
          ),
        );
      },
    ).then((_) {
      _iconStatus.value = false;
    });
  }
}

class PopupHorizMenuItem<T> {
  const PopupHorizMenuItem({
    this.key,
    required this.value,
    required this.child,
    this.padding,
    this.tooltip,
  });

  final Key? key;
  final T value;
  final Widget child;
  final double? padding;
  final String? tooltip;
}
