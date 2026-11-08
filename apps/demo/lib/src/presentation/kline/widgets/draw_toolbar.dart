import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';

import '../../../widgets/circle_icon_button.dart';
import 'draw_tool_shapes.dart';

const _paintColors = [
  Colors.blueAccent,
  Colors.redAccent,
  Colors.purpleAccent,
  Colors.greenAccent,
  Colors.orangeAccent,
];
const _strokeWidths = [1.0, 2.0, 3.0, 4.0];

/// 选中图形后的样式工具条: 颜色、线宽、线型、层级、锁定与删除。
///
/// 无选中图形时不占位。图标优先用 Flutter 自带的, 没有的(线宽、线型)用 [IconShape] 绘制。
/// 下拉菜单用 [MenuAnchor]: 默认展开在按钮下方, 下方放不下时翻到上方, 不会盖住按钮。
class DrawToolbar extends StatelessWidget {
  const DrawToolbar({super.key, required this.controller});

  final FlexiKlineController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      elevation: 2,
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 32,
        child: ValueListenableBuilder(
          valueListenable: controller.drawStateListenable,
          builder: (context, state, _) {
            final object = state.object;
            if (object == null) return const SizedBox.shrink();
            final paintColor = object.line.paint.color ?? theme.colorScheme.primary;
            final strokeWidth = object.line.paint.strokeWidth;
            final lineType = object.line.type;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(Icons.drag_indicator_rounded, size: 20),
                ),
                _Menu(
                  tooltip: '颜色',
                  icon: Icon(Icons.edit_outlined, color: paintColor),
                  menuChildren: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final color in _paintColors)
                            Builder(
                              builder: (context) => _Button(
                                tooltip: '颜色 ${_paintColors.indexOf(color) + 1}',
                                selected: color == paintColor,
                                onPressed: () {
                                  controller.changeDrawLineStyle(color: color);
                                  MenuController.maybeOf(context)?.close();
                                },
                                icon: ShapeIcon(const CircleShape(), size: const Size.square(16), color: color),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                _Menu(
                  tooltip: '线宽',
                  icon: Text('${strokeWidth.toInt()}px', style: theme.textTheme.labelSmall),
                  menuChildren: [
                    for (final width in _strokeWidths)
                      _Item(
                        icon: ShapeIcon(LineWeightShape(width)),
                        label: '${width.toInt()} px',
                        selected: width == strokeWidth,
                        onPressed: () => controller.changeDrawLineStyle(strokeWidth: width),
                      ),
                  ],
                ),
                _Menu(
                  tooltip: '线型',
                  icon: ShapeIcon(LineTypeShape(lineType)),
                  menuChildren: [
                    for (final type in LineType.values)
                      _Item(
                        icon: ShapeIcon(LineTypeShape(type)),
                        label: type.name,
                        selected: type == lineType,
                        onPressed: () => controller.changeDrawLineStyle(lineType: type),
                      ),
                  ],
                ),
                _Menu(
                  tooltip: '层级',
                  icon: const Icon(Icons.layers_outlined),
                  menuChildren: [
                    _Item(
                      icon: const Icon(Icons.vertical_align_top_rounded),
                      label: '置顶',
                      selected: controller.isDrawOnTop(),
                      onPressed: controller.moveDrawStateObjectToTop,
                    ),
                    _Item(
                      icon: const Icon(Icons.vertical_align_bottom_rounded),
                      label: '置底',
                      selected: controller.isDrawOnBottom(),
                      onPressed: controller.moveDrawStateObjectToBottom,
                    ),
                  ],
                ),
                _Button(
                  tooltip: object.lock ? '解锁' : '锁定',
                  selected: object.lock,
                  onPressed: () => controller.setDrawLockState(!object.lock),
                  icon: Icon(object.lock ? Icons.lock_outline_rounded : Icons.lock_open_rounded),
                ),
                _Button(tooltip: '删除', onPressed: controller.removeDrawObject, icon: const Icon(Icons.delete_outline)),
                const SizedBox(width: 2),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 点击展开下拉菜单的工具条按钮。
class _Menu extends StatelessWidget {
  const _Menu({required this.tooltip, required this.icon, required this.menuChildren});

  final String tooltip;
  final Widget icon;
  final List<Widget> menuChildren;

  /// 菜单项样式: 行高 28、12 号字、16 的图标; 固定标准密度, 桌面端默认的紧凑密度会再压低 8。
  static const _itemStyle = ButtonStyle(
    minimumSize: WidgetStatePropertyAll(Size(0, 28)),
    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 8)),
    iconSize: WidgetStatePropertyAll(16),
    textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12)),
    visualDensity: VisualDensity.standard,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  @override
  Widget build(BuildContext context) => MenuButtonTheme(
    data: const MenuButtonThemeData(style: _itemStyle),
    child: MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: const MenuStyle(padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 4))),
      menuChildren: menuChildren,
      builder: (context, menu, _) => _Button(
        tooltip: tooltip,
        selected: menu.isOpen,
        onPressed: () => menu.isOpen ? menu.close() : menu.open(),
        icon: icon,
      ),
    ),
  );
}

/// 下拉菜单项; 当前取值在末尾打勾。
class _Item extends StatelessWidget {
  const _Item({required this.icon, required this.label, required this.selected, required this.onPressed});

  final Widget icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => MenuItemButton(
    leadingIcon: icon,
    trailingIcon: selected ? const Icon(Icons.check_rounded, size: 14) : null,
    onPressed: onPressed,
    child: Text(label),
  );
}

/// 工具条按钮, 尺寸与菜单栏一致。
class _Button extends StatelessWidget {
  const _Button({required this.tooltip, required this.onPressed, required this.icon, this.selected = false});

  final String tooltip;
  final VoidCallback? onPressed;
  final Widget icon;
  final bool selected;

  @override
  Widget build(BuildContext context) => CircleIconButton(
    tooltip: tooltip,
    selected: selected,
    onPressed: onPressed,
    icon: icon,
  );
}
