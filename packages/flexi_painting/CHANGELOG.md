## 0.2.0
* Change `TooltipPainter.paint` under `alignment: MainAxisAlignment.spaceEvenly` to size the card like `spaceAround` and align labels right and values left toward the gap, splitting any extra width between both sides; it used to fall back to `spaceBetween` (Breaking Changes).

## 0.1.0
* Initial release: the painting primitives of `flexi_kline` as a standalone package with no dependency beyond Flutter.
* Add `IconShape`, an immutable shape description shared by canvas and widgets, with eleven built-in shapes including the circled plus `CirclePlusShape`; `ShapeImage` caches a shape as a bitmap for inline labels.
* Add `ShapeIcon`, which paints a shape as a vector widget using `IconTheme` defaults like `Icon`, and `ShapeImageProvider` for APIs that only accept an `ImageProvider`.
* Add `roundedShapeDecoration`, which combines background, border, radius, gradients and shadows into a rounded-rectangle `ShapeDecoration`, and `bubbleShapeDecoration`, which takes the same parts as explicit parameters and builds a `BubbleBorder` pointing in a given direction; `TooltipPainter.paint` takes a `decoration` for its card.
* `TooltipPainter.paint` lays each row out by `alignment` (`MainAxisAlignment`, default `spaceBetween`): the card is as wide as the widest row, except under `spaceAround`, which is repurposed to size the card by the widest label plus the widest value so the columns stay aligned; `spaceEvenly` is not supported and falls back to `spaceBetween`, and `spacing` stays the minimum label-value gap.
