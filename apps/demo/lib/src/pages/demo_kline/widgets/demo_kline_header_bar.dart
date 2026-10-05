import 'package:flutter/material.dart';

import '../../../utils/device.dart';

/// 周期切换栏：五档周期用 [TabBar] 呈现，右侧按需追加「绘图工具」「横屏」按钮。
class DemoKlineHeaderBar extends StatelessWidget {
  const DemoKlineHeaderBar({
    super.key,
    this.onToggleDraw,
    this.onOpenLandscape,
    required this.klineIntervalBar,
  });

  /// 为 null 时隐藏「绘图工具」按钮。
  final VoidCallback? onToggleDraw;

  /// 为 null 时隐藏「横屏」按钮。
  final VoidCallback? onOpenLandscape;

  /// 周期切换栏。
  final Widget klineIntervalBar;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        spacing: 8,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Flexible(
            child: klineIntervalBar,
          ),
          const VerticalDivider(width: 0.5, indent: 12, endIndent: 12),
          if (onToggleDraw != null)
            IconButton(
              tooltip: '绘图工具',
              icon: const Icon(Icons.draw),
              onPressed: onToggleDraw,
            ),
          if (onOpenLandscape != null && DeviceUtil.isMobile)
            IconButton(
              tooltip: '横屏',
              icon: const Icon(Icons.screen_rotation),
              onPressed: onOpenLandscape,
            ),
        ],
      ),
    );
  }
}
