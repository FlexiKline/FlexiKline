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
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FlexiPopupMenuButton<T> extends PopupMenuButton<T> {
  const FlexiPopupMenuButton({
    super.key,
    required super.itemBuilder,
    super.initialValue,
    super.onOpened,
    super.onSelected,
    super.onCanceled,
    // super.tooltip, // tooltip 会导致发生手势冲突
    super.elevation,
    super.shadowColor,
    super.surfaceTintColor,
    super.padding = EdgeInsets.zero,
    super.menuPadding = EdgeInsets.zero,
    required Widget child,
    super.splashRadius,
    super.icon, // arrowIcon
    super.iconSize, // arrowIconSize
    super.offset = Offset.zero,
    super.enabled = true,
    super.shape,
    super.color,
    super.iconColor, // arrowIconColor
    // super.enableFeedback,
    super.constraints = const BoxConstraints(),
    super.position = PopupMenuPosition.under,
    super.clipBehavior = Clip.none,
    super.useRootNavigator = false,
    super.popUpAnimationStyle,
    super.routeSettings,
    super.style,
  }) : super(child: child);

  @override
  PopupMenuButtonState<T> createState() => FlexiPopupMenuButtonState<T>();
}

class FlexiPopupMenuButtonState<T> extends PopupMenuButtonState<T> {
  bool _status = false;

  @override
  void showButtonMenu() {
    final PopupMenuThemeData popupMenuTheme = PopupMenuTheme.of(context);
    final RenderBox button = context.findRenderObject()! as RenderBox;
    final RenderBox overlay = Navigator.of(
      context,
      rootNavigator: widget.useRootNavigator,
    ).overlay!.context.findRenderObject()! as RenderBox;
    final PopupMenuPosition popupMenuPosition =
        widget.position ?? popupMenuTheme.position ?? PopupMenuPosition.over;
    late Offset offset;
    switch (popupMenuPosition) {
      case PopupMenuPosition.over:
        offset = widget.offset;
      case PopupMenuPosition.under:
        offset = Offset(0.0, button.size.height) + widget.offset;
        if (widget.child == null) {
          // Remove the padding of the icon button.
          offset -= Offset(0.0, widget.padding.vertical / 2);
        }
    }
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(offset, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero) + offset,
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    final List<PopupMenuEntry<T>> items = widget.itemBuilder(context);
    // Only show the menu if there is something to show
    if (items.isNotEmpty) {
      _status = true;
      setState(() {});
      widget.onOpened?.call();
      showMenu<T?>(
        context: context,
        elevation: widget.elevation ?? popupMenuTheme.elevation,
        shadowColor: widget.shadowColor ?? popupMenuTheme.shadowColor,
        surfaceTintColor:
            widget.surfaceTintColor ?? popupMenuTheme.surfaceTintColor,
        items: items,
        initialValue: widget.initialValue,
        position: position,
        shape: widget.shape ?? popupMenuTheme.shape,
        menuPadding: widget.menuPadding ?? popupMenuTheme.menuPadding,
        color: widget.color ?? popupMenuTheme.color,
        constraints: widget.constraints,
        clipBehavior: widget.clipBehavior,
        useRootNavigator: widget.useRootNavigator,
        popUpAnimationStyle: widget.popUpAnimationStyle,
        routeSettings: widget.routeSettings,
      ).then<void>((T? newValue) {
        _status = false;
        setState(() {});
        if (!mounted) {
          return null;
        }
        if (newValue == null) {
          widget.onCanceled?.call();
          return null;
        }
        widget.onSelected?.call(newValue);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      key: widget.key,
      onPressed: widget.enabled ? showButtonMenu : null,
      style: widget.style ??
          ButtonStyle(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: WidgetStatePropertyAll(
              widget.padding,
            ),
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.splashRadius ?? 8),
            )),
            minimumSize: WidgetStatePropertyAll(Size(30.r, 30.r)),
            maximumSize: WidgetStatePropertyAll(Size(80.r, 30.r)),
          ),
      child: _buildMenu(context),
    );
  }

  Widget _buildMenu(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        widget.child!,
        RotationTransition(
          turns: AlwaysStoppedAnimation(_status ? 0.5 : 0),
          child: widget.icon ??
              Icon(
                Icons.arrow_drop_down,
                size: widget.iconSize ?? 14.r,
                color: widget.iconColor ?? widget.color,
              ),
        ),
      ],
    );
  }
}
