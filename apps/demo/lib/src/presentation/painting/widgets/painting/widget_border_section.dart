import 'package:flexi_painting/flexi_painting.dart';
import 'package:flutter/material.dart';

import '../section.dart';

/// Widget 中的异形边框: 同一批 ShapeBorder 交给 [ShapeDecoration]、[ClipPath] 与 [Material]。
class WidgetBorderSection extends StatelessWidget {
  const WidgetBorderSection({super.key});

  static const _radius = BorderRadius.all(Radius.circular(6));
  static const _gradient = LinearGradient(colors: [Colors.indigo, Colors.pink]);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = TextStyle(fontSize: 12, color: colors.onPrimary);
    return DemoSection(
      title: '边框(Widget)',
      caption: '依次为: Container 的气泡装饰、渐变描边、ClipPath 按气泡裁切、Material 的气泡外形带阴影。箭头画在 body 之外, 布局时自行留出外边距。',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            // 箭头朝下伸出 6, 底部留出同样的距离。
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: ShapeDecoration(
              color: colors.primary,
              shape: const BubbleBorder(borderRadius: _radius),
            ),
            child: Text('ShapeDecoration', style: text),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const ShapeDecoration(
              shape: GradientRoundedRectangleBorder(
                side: BorderSide(width: 2),
                borderRadius: _radius,
                gradient: _gradient,
              ),
            ),
            child: Text('Gradient border', style: TextStyle(fontSize: 12, color: colors.onSurface)),
          ),
          ClipPath(
            clipper: const ShapeBorderClipper(
              shape: BubbleBorder(borderRadius: _radius, direction: AxisDirection.left),
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 6, 10, 6),
              decoration: const BoxDecoration(gradient: _gradient),
              child: const Text('ClipPath', style: TextStyle(fontSize: 12, color: Colors.white)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Material(
              color: colors.tertiary,
              elevation: 4,
              shape: const BubbleBorder(borderRadius: _radius, direction: AxisDirection.up),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text('Material', style: TextStyle(fontSize: 12, color: colors.onTertiary)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
