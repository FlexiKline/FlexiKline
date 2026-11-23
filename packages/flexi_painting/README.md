# flexi_painting

[![pub](https://img.shields.io/pub/v/flexi_painting.svg)](https://pub.dev/packages/flexi_painting)

English | [简体中文](https://github.com/FlexiKline/FlexiKline/blob/main/packages/flexi_painting/README_zh.md)

The low-level painting toolkit for custom-painted Flutter charts and widgets, with no dependency beyond Flutter: cached labels, tooltips, batched drawing and paint resource management for `CustomPainter`, geometry helpers, and shaped borders and code-drawn icons that work both in widgets and on a canvas. [flexi_kline](https://pub.dev/packages/flexi_kline) paints with it and re-exports it.

## Requirements

- **Flutter SDK**: >= 3.41.0
- **Dart SDK**: >= 3.11.0

> The package does not import Flutter's `material.dart` or `cupertino.dart`. You can use it with Material, with `material_ui`, or with neither. It is tested on Flutter 3.41.0 (the minimum version) and 3.50.0, where those framework libraries are deprecated.

## Features

- **Shaped borders**: `BubbleBorder` (speech bubble with an arrow on any side, optional gradient border) and `GradientRoundedRectangleBorder`. Both are `ShapeBorder`s, so `ShapeDecoration`, `ClipPath` and `Material` accept them.
- **Cached labels**: `LabelPainter` lays text out only when its key or style changes, places the label by an anchor and alignment inside optional bounds, and can flip to the opposite side of a target with `paintAround`. `RawImageSpan` puts a decoded `ui.Image` inline in the text, sampled with its `filterQuality` (default `low`).
- **Images and tooltips**: `ImagePainter` and `TooltipPainter` with the same cache-and-place model; tooltip rows are laid out by a `MainAxisAlignment`-style alignment, with `spacing` as the minimum label-value gap.
- **Code-drawn icons**: describe a shape once as an `IconShape`; show it as a widget with `ShapeIcon` (vector, `IconTheme` defaults like `Icon`), inline in a canvas label with `ShapeImage`, or through `ShapeImageProvider` where an `ImageProvider` is required.
- **Batching**: `PointBuffer` collects points or segments sharing a paint and draws them in one call.
- **Resource management**: `PaintResource` and `PaintResourceOwner` reset and dispose paint resources that live across frames.

## Scope

It has no chart semantics: coordinate mapping, ticks, axes, crosshair gestures and animation belong to the chart libraries built on it. It does not parse SVG, and app-specific icons are written as shapes in the app or library that uses them.

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
    text: TextStyle(color: Color(0xFF000000), fontSize: 12),
    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: ShapeDecoration(color: Color(0xFFFFC107), shape: BubbleBorder()),
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
