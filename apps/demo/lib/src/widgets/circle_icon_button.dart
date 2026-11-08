import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 圆形图标按钮: 点击水波为圆形, 点击区不外扩到 48。
///
/// 选中时图标用品牌蓝, 未选中用次要文字色, 不加背景; [icon] 用 [Icon] 或 `ShapeIcon`, 二者都从 [IconTheme] 取色。
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.selectedIcon,
    this.selected = false,
    this.size = 32,
    this.iconSize = 20,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  /// 选中时替换 [icon], 如实心与描边两套图标。
  final Widget? selectedIcon;
  final bool selected;

  /// 按钮直径。
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = AppTheme.selectedOf(theme.brightness);
    final normalColor = theme.colorScheme.onSurfaceVariant;
    return IconButton(
      tooltip: tooltip,
      isSelected: selected,
      iconSize: iconSize,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(width: size, height: size),
      style: ButtonStyle(
        shape: const WidgetStatePropertyAll(CircleBorder()),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? selectedColor : normalColor,
        ),
      ),
      onPressed: onPressed,
      icon: icon,
      selectedIcon: selectedIcon,
    );
  }
}
