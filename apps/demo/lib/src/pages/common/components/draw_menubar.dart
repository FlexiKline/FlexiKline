import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';

import '../../../widgets/circle_icon_button.dart';
import 'draw_tool_shapes.dart';

/// 绘图菜单栏: 选择绘图工具, 并控制连续绘制、磁吸、显隐、清除与退出。
class DrawMenubar extends StatelessWidget {
  const DrawMenubar({super.key, required this.controller, this.onExit});

  final FlexiKlineController controller;
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: controller.drawStateListenable,
              builder: (context, state, _) {
                final current = state.object?.type;
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  children: [
                    for (final type in controller.supportDrawTypes)
                      _Button(
                        tooltip: type.id,
                        selected: current == type,
                        onPressed: () => controller.startDraw(type),
                        icon: switch (drawToolShapes[type]) {
                          final shape? => ShapeIcon(shape),
                          null => const Icon(Icons.draw_outlined),
                        },
                      ),
                  ],
                );
              },
            ),
          ),
          VerticalDivider(width: 9, indent: 10, endIndent: 10, color: colors.outlineVariant),
          ValueListenableBuilder(
            valueListenable: controller.drawContinuousListenable,
            builder: (context, isOn, _) => _Button(
              tooltip: '连续绘制',
              selected: isOn,
              onPressed: () => controller.setDrawContinuous(!isOn),
              icon: const Icon(Icons.edit_outlined),
              selectedIcon: const Icon(Icons.edit),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: controller.drawMagnetModeListenable,
            builder: (context, mode, _) => _Button(
              tooltip: '磁吸: ${mode.name}',
              selected: !mode.isNormal,
              onPressed: () => controller.setDrawMagnetMode(mode.next),
              icon: ShapeIcon(MagnetShape(strong: mode.isStrong)),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: controller.drawVisibilityListenable,
            builder: (context, isShow, _) => _Button(
              tooltip: isShow ? '隐藏图形' : '显示图形',
              onPressed: () => controller.setDrawVisible(!isShow),
              icon: Icon(isShow ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            ),
          ),
          _Button(tooltip: '清除全部', onPressed: controller.removeAllDrawObjects, icon: const Icon(Icons.delete_outline)),
          _Button(tooltip: '退出绘图', onPressed: onExit, icon: const Icon(Icons.close_rounded)),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

/// 外包 [Center], 避免横向列表把按钮撑高成胶囊形。
class _Button extends StatelessWidget {
  const _Button({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    this.selectedIcon,
    this.selected = false,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final Widget icon;
  final Widget? selectedIcon;
  final bool selected;

  @override
  Widget build(BuildContext context) => Center(
    child: CircleIconButton(
      tooltip: tooltip,
      selected: selected,
      onPressed: onPressed,
      icon: icon,
      selectedIcon: selectedIcon,
    ),
  );
}
