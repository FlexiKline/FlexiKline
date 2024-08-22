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

typedef FlexiPopupMenuItemBuilder<T> = Widget Function(
  BuildContext context,
  T value,
  bool isMenuItem,
);

class FlexiPopupMenuButton<T> extends ConsumerStatefulWidget {
  const FlexiPopupMenuButton({
    super.key,
    required this.menuItems,
    required this.itemBuilder,
    this.initialValue,
    this.onSelected,
    this.tooltip,
    this.padding,
    this.menuButtonStyle,
    this.minimumSize,
    this.maximumSize,
    this.stateIconSize,
    this.menuOffset,
  }) : assert(menuItems.length != 0, 'The menuItems cannot be empty');

  final List<T> menuItems;
  final FlexiPopupMenuItemBuilder<T> itemBuilder;

  final T? initialValue;
  final PopupMenuItemSelected<T>? onSelected;
  final String? tooltip;

  final EdgeInsetsGeometry? padding;
  final ButtonStyle? menuButtonStyle;
  final Size? minimumSize;
  final Size? maximumSize;
  final double? stateIconSize;
  final Offset? menuOffset;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _FlexiPopupMenuButtonState<T>();
}

class _FlexiPopupMenuButtonState<T>
    extends ConsumerState<FlexiPopupMenuButton<T>> {
  late T _value;
  bool _status = false;
  @override
  void initState() {
    super.initState();
    _value = widget.initialValue ?? widget.menuItems.first;
  }

  void onOpened() {
    _status = true;
    setState(() {});
  }

  void onCanceled() {
    _status = false;
    setState(() {});
  }

  void onSelected(T value) {
    _status = false;
    _value = value;
    setState(() {});
    widget.onSelected?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeProvider);
    return PopupMenuButton(
      initialValue: _value,
      tooltip: widget.tooltip,
      elevation: 2,
      position: PopupMenuPosition.under,
      constraints: BoxConstraints(
        minWidth: widget.minimumSize?.width ?? 50.r,
        maxWidth: widget.maximumSize?.width ?? 50.r,
      ),
      offset: widget.menuOffset ?? Offset(-5.r, 0.r),
      menuPadding: EdgeInsets.zero,
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          widget.itemBuilder(context, _value, false),
          RotationTransition(
            turns: AlwaysStoppedAnimation(_status ? 0.5 : 0),
            child: Icon(
              Icons.arrow_drop_down,
              size: widget.stateIconSize ?? 16.r,
              color: theme.t1,
            ),
          ),
        ],
      ),
      padding: widget.padding ?? EdgeInsets.all(4.r),
      style: widget.menuButtonStyle ??
          ButtonStyle(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            minimumSize: WidgetStatePropertyAll(widget.minimumSize),
          ),
      // iconSize: defaultShrinkIconSize,
      itemBuilder: (context) {
        return widget.menuItems.map((value) {
          return PopupMenuItem(
            key: ValueKey(value),
            value: value,
            height: 32.r,
            child: widget.itemBuilder(context, value, true),
          );
        }).toList();
      },
      onOpened: onOpened,
      onCanceled: onCanceled,
      onSelected: onSelected,
    );
  }
}
