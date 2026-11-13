## 0.1.0
* Initial release: the painting primitives of `flexi_kline` as a standalone package with no dependency beyond Flutter.
* Add `IconShape`, an immutable shape description shared by canvas and widgets, with eleven built-in shapes including the circled plus `CirclePlusShape`; `ShapeImage` caches a shape as a bitmap for inline labels.
* Add `ShapeIcon`, which paints a shape as a vector widget using `IconTheme` defaults like `Icon`, and `ShapeImageProvider` for APIs that only accept an `ImageProvider`.
* Add `roundedShapeDecoration`, which combines background, border, radius, gradients and shadows into a rounded-rectangle `ShapeDecoration`, and `bubbleShapeDecoration`, which turns such a decoration into a `BubbleBorder` pointing in a given direction; `TooltipPainter.paint` takes a `decoration` for its card.
