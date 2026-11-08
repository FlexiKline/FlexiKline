import 'package:flexi_painting/flexi_painting.dart';
import 'package:flutter/material.dart';

/// 示例画笔: 用 own() 跨帧持有绘制资源, 只依赖 flexi_painting。
///
/// 实例由 [PaintingSection] 创建并持有一份, 不随 build 重建(重建会丢掉缓存), 退出时 [dispose];
/// 自身状态变化调 [markNeedsPaint] 重绘, 配色变化时自动重绘。
abstract class SectionPainter extends CustomPainter with PaintResourceOwner {
  SectionPainter({Listenable? repaint}) : this._(_Repaint(), repaint);

  SectionPainter._(this._repaint, Listenable? repaint)
    : super(repaint: repaint == null ? _repaint : Listenable.merge([_repaint, repaint]));

  final _Repaint _repaint;

  /// 当前 Material 配色, 由 [PaintingSection] 在 build 时写入。
  ColorScheme get colors => _colors!;
  ColorScheme? _colors;

  set colors(ColorScheme value) {
    if (_colors == value) return;
    final first = _colors == null;
    _colors = value;
    _byColors.clear();
    if (!first) markNeedsPaint();
  }

  final _byColors = <Object, Object>{};

  /// 按当前配色构建并缓存一份值(如 [LabelStyle]); 配色不变时复用, 免得每帧新建装饰触发重排。
  T byColors<T extends Object>(Object key, T Function(ColorScheme colors) build) =>
      _byColors.putIfAbsent(key, () => build(colors)) as T;

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

/// 一节示例的外壳: 标题、说明与内容。
class DemoSection extends StatelessWidget {
  const DemoSection({super.key, required this.title, required this.caption, required this.child});

  final String title;
  final String caption;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              caption,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

/// 画布示例: 固定高度的画布, 可选底部操作区; 持有 [create] 出的画笔。
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
    _painter.colors = Theme.of(context).colorScheme;
    final onTap = widget.onTap;
    return DemoSection(
      title: widget.title,
      caption: widget.caption,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
