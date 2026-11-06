import 'package:flexi_painting/flexi_painting.dart';
import 'package:flutter/material.dart';

import '../section.dart';

/// 内置图形与可调参数: 每行一个图形, 第一个是默认参数, 其后是各参数的变化。
class IconShapesSection extends StatelessWidget {
  const IconShapesSection({super.key});

  /// 名字与各变体(说明, 图形)。
  static const _rows = <(String, List<(String, IconShape)>)>[
    (
      'TriangleShape',
      [
        ('默认', TriangleShape()),
        ('radius 0', TriangleShape(radius: 0)),
        ('radius 3', TriangleShape(radius: 3)),
        ('up', TriangleShape(direction: AxisDirection.up)),
      ],
    ),
    (
      'DiamondShape',
      [
        ('默认', DiamondShape()),
        ('radius 3', DiamondShape(radius: 3)),
      ],
    ),
    (
      'CircleShape',
      [
        ('默认', CircleShape()),
        ('strokeWidth 2', CircleShape(strokeWidth: 2)),
      ],
    ),
    (
      'SquareShape',
      [
        ('默认', SquareShape()),
        ('radius 6', SquareShape(radius: 6)),
        ('strokeWidth 2', SquareShape(strokeWidth: 2)),
        ('radius + stroke', SquareShape(radius: 6, strokeWidth: 2)),
      ],
    ),
    (
      'PlusShape',
      [
        ('默认', PlusShape()),
        ('thickness 3', PlusShape(thickness: 3)),
        ('radius 4', PlusShape(radius: 4)),
      ],
    ),
    (
      'CirclePlusShape',
      [
        ('默认', CirclePlusShape()),
        ('plusRatio 0.5', CirclePlusShape(plusRatio: 0.5)),
        ('plusThickness 4', CirclePlusShape(plusThickness: 4)),
      ],
    ),
    (
      'MinusShape',
      [
        ('默认', MinusShape()),
        ('thickness 3', MinusShape(thickness: 3)),
        ('radius 4', MinusShape(radius: 4)),
      ],
    ),
    (
      'ChevronShape',
      [
        ('默认', ChevronShape()),
        ('left', ChevronShape(direction: AxisDirection.left)),
        ('thickness 2', ChevronShape(thickness: 2)),
      ],
    ),
    (
      'CrossShape',
      [
        ('默认', CrossShape()),
        ('thickness 2', CrossShape(thickness: 2)),
      ],
    ),
    (
      'StarShape',
      [
        ('默认', StarShape()),
        ('points 6', StarShape(points: 6)),
        ('innerRatio 0.6', StarShape(innerRatio: 0.6)),
      ],
    ),
    (
      'BellShape',
      [('默认', BellShape())],
    ),
  ];

  /// 全部变体数, 供测试核对。
  static int get variantCount => _rows.fold(0, (sum, row) => sum + row.$2.length);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final caption = theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return DemoSection(
      title: '图标: 内置图形与参数',
      caption: '参数都有默认值; 尺寸由使用处给出, 线宽、圆角、比例等细节用参数调整。以下均为 24 的 ShapeIcon。',
      child: IconTheme(
        data: IconThemeData(size: 24, color: theme.colorScheme.primary),
        child: Column(
          children: [
            for (final (name, variants) in _rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(width: 112, child: Text(name, style: theme.textTheme.bodySmall)),
                    Expanded(
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 4,
                        children: [
                          for (final (label, shape) in variants)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ShapeIcon(shape, semanticLabel: '$name $label'),
                                Text(label, style: caption),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
