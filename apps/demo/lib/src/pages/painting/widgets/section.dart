import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';

import '../../../config/my_kline_config.dart';
import '../../../config/my_kline_indicator_config.dart';
import '../../../theme/my_app_theme.dart';

/// 示例画笔: 像 PaintObject 一样用 own() 跨帧持有资源, 配置与 demo K 线页同源。
///
/// 实例由 [PaintingSection] 创建并持有一份, 不随 build 重建(重建会丢掉缓存), 退出时 [dispose];
/// 自身状态变化调 [markNeedsPaint] 重绘, 切换明暗主题自动重绘。
abstract class SectionPainter extends CustomPainter with PaintResourceOwner {
  SectionPainter(MyKlineConfig configuration, MyKlineIndicatorConfig indicatorConfig)
    : this._(configuration, indicatorConfig, _Repaint());

  SectionPainter._(this.configuration, this.indicatorConfig, this._repaint)
    : super(repaint: Listenable.merge([_repaint, myAppThemeMode]));

  final MyKlineConfig configuration;
  final MyKlineIndicatorConfig indicatorConfig;
  final _Repaint _repaint;

  /// 同框架 controller: 取一次后持有。
  late final FlexiKlineConfig flexiKlineConfig = configuration.getFlexiKlineConfig();

  /// 随明暗模式变化, 每帧现取。
  IFlexiKlineTheme get theme => configuration.theme;

  void markNeedsPaint() => _repaint.notify();

  @mustCallSuper
  void dispose() {
    disposeResources();
    _repaint.dispose();
  }

  /// 实例不换, 重绘只经 repaint 通知。
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Repaint extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// 一节示例的外壳: 标题、说明、固定高度的画布, 可选底部操作区; 持有 [create] 出的画笔。
class PaintingSection<P extends SectionPainter> extends StatefulWidget {
  const PaintingSection({
    super.key,
    required this.title,
    required this.caption,
    required this.height,
    required this.create,
    this.footer,
    this.onTap,
  });

  final String title;
  final String caption;
  final double height;
  final P Function() create;
  final Widget Function(P painter)? footer;

  /// 点击位置相对画布。
  final void Function(P painter, Offset position)? onTap;

  @override
  State<PaintingSection<P>> createState() => _PaintingSectionState<P>();
}

class _PaintingSectionState<P extends SectionPainter> extends State<PaintingSection<P>> {
  late final P _painter = widget.create();

  @override
  void dispose() {
    _painter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onTap = widget.onTap;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              widget.caption,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: widget.height,
              width: double.infinity,
              child: GestureDetector(
                onTapUp: onTap == null ? null : (details) => onTap(_painter, details.localPosition),
                child: CustomPaint(painter: _painter),
              ),
            ),
            ?widget.footer?.call(_painter),
          ],
        ),
      ),
    );
  }
}

/// 在 [anchor] 画一个红色十字, 标出标签对准的点。
void paintAnchor(Canvas canvas, Offset anchor) {
  final paint = Paint()
    ..color = Colors.red
    ..strokeWidth = 1;
  canvas
    ..drawLine(anchor.translate(-5, 0), anchor.translate(5, 0), paint)
    ..drawLine(anchor.translate(0, -5), anchor.translate(0, 5), paint);
}
