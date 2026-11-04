# flexi_painting

[![pub](https://img.shields.io/pub/v/flexi_painting.svg)](https://pub.dev/packages/flexi_painting)

English | [简体中文](https://github.com/FlexiKline/FlexiKline/blob/main/packages/flexi_painting/README_zh.md)

Canvas painting primitives for Flutter, with no dependency beyond Flutter. They fill the gaps when you paint charts, order books or custom controls in a `CustomPainter`, and the borders also work as ordinary widget decorations. [flexi_kline](https://pub.dev/packages/flexi_kline) paints with them and re-exports them.

## Features

- **Shaped borders**: `BubbleBorder` (speech bubble with an arrow on any side, optional gradient border) and `GradientRoundedRectangleBorder`. Both are `ShapeBorder`s, so `ShapeDecoration`, `ClipPath` and `Material` accept them.
- **Cached labels**: `LabelPainter` lays text out only when its key or style changes, places the label by an anchor and alignment inside optional bounds, and can flip to the opposite side of a target with `paintAround`. `RawImageSpan` puts a decoded `ui.Image` inline in the text.
- **Images and tooltips**: `ImagePainter` and `TooltipPainter` with the same cache-and-place model.
- **Code-drawn icons**: `ShapeImage` rasterizes a small vector shape and caches the image for inline use.
- **Batching**: `PointBuffer` collects points or segments sharing a paint and draws them in one call.
- **Resource management**: `PaintResource` and `PaintResourceOwner` reset and dispose paint resources that live across frames.

## Usage

```yaml
dependencies:
  flexi_painting: ^0.1.0
```

```dart
final label = LabelPainter(); // keep it across frames, dispose it with its owner

label.paint(
  canvas,
  price, // the key must fully determine the text; build is skipped on a hit
  build: () => price.toStringAsFixed(2),
  style: const LabelStyle(
    text: TextStyle(color: Colors.black, fontSize: 12),
    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: ShapeDecoration(color: Colors.amber, shape: BubbleBorder()),
  ),
  anchor: Offset(dx, dy),
  align: Alignment.bottomCenter,
  bounds: Offset.zero & size,
);
```

A runnable app is in [example/main.dart](https://github.com/FlexiKline/FlexiKline/blob/main/packages/flexi_painting/example/main.dart).

## Versioning

The API may still change between `0.x` minor versions; breaking changes are marked in the [CHANGELOG](CHANGELOG.md).

## License

[Apache License 2.0](LICENSE)
