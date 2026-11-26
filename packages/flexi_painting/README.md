# flexi_painting

[![pub](https://img.shields.io/pub/v/flexi_painting.svg)](https://pub.dev/packages/flexi_painting)

![Painting page](https://raw.githubusercontent.com/FlexiKline/FlexiKline.github.io/main/media/painting.png)

![Painting page recording](https://raw.githubusercontent.com/FlexiKline/FlexiKline.github.io/main/media/painting.gif)

English | [简体中文](https://github.com/FlexiKline/FlexiKline/blob/main/packages/flexi_painting/README_zh.md)

Painting primitives that extend Flutter's `painting` library for custom-drawn widgets and charts. On top of what Flutter provides, it adds cached text labels and tooltips, shaped borders and code-drawn icons that work in widgets and on a canvas, batched drawing, geometry helpers and paint resource management. It depends only on Flutter and has no chart semantics. [flexi_kline](https://pub.dev/packages/flexi_kline) is built on it and re-exports it.

## Requirements

- **Flutter SDK**: >= 3.41.0
- **Dart SDK**: >= 3.11.0

> The package does not import Flutter's `material.dart` or `cupertino.dart`. You can use it with Material, with `material_ui`, or with neither. It is tested on Flutter 3.41.0 (the minimum version) and 3.50.0, where those framework libraries are deprecated.

## Features

| Area | API | What it does |
| --- | --- | --- |
| Shaped borders | `BubbleBorder`, `GradientRoundedRectangleBorder` | Speech bubble with an arrow on any side, rounded rectangle with a gradient border. Both are `ShapeBorder`s, so `ShapeDecoration`, `ClipPath` and `Material` accept them. |
| Canvas labels | `LabelPainter`, `LabelStyle` | Text with padding and decoration. Lays text out again only when the key or the layout style changes; places by anchor and alignment inside optional bounds; `paintAround` flips to the other side of a target when it does not fit. |
| Inline images | `RawImageSpan` | Puts a decoded `ui.Image` inline in label text, sampled with its `filterQuality` (default `low`). |
| Images and tooltips | `ImagePainter`, `TooltipPainter` | Same cache-and-place model as labels; tooltip rows align like `MainAxisAlignment`, with `spacing` as the minimum label-value gap. |
| Code-drawn icons | `IconShape`, `ShapeIcon`, `ShapeImage`, `ShapeImageProvider` | Describe a shape once and use it as a vector widget (`IconTheme` defaults like `Icon`), as a cached bitmap inline in a canvas label, or wherever an `ImageProvider` is required. Built-in shapes such as `TriangleShape`, `ChevronShape`, `StarShape` take optional detail parameters such as corner radius and stroke width. |
| Batching | `PointBuffer` | Collects points or segments that share a paint and draws them with one `drawRawPoints`; the buffer is reused across frames. |
| Resources | `PaintResource`, `PaintResourceOwner` | Registers objects that live across frames so the owner can reset their caches and dispose them in one place. |

## Scope

It has no chart semantics: coordinate mapping, ticks, axes, crosshair gestures and animation belong to the chart libraries built on it. It does not parse SVG, and app-specific icons are written as shapes in the app or library that uses them.

## Usage

```yaml
dependencies:
  flexi_painting: ^0.2.0
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

Use the same shape as a widget icon and inside a canvas label:

```dart
const arrow = TriangleShape(direction: AxisDirection.up);

ShapeIcon(arrow, size: Size.square(16), color: Color(0xFF26A69A));

final arrowImage = ShapeImage(arrow, const Size(6, 6)); // one bitmap per color, dispose with its owner

label.paint(
  canvas,
  (price, color), // the color is part of the content, so it belongs in the key
  build: () => TextSpan(children: [TextSpan(text: '$price '), arrowImage.span(color)]),
  style: style,
  anchor: anchor,
);
```

Draw many bars with one call, and let the owner manage the buffers:

```dart
class Bars with PaintResourceOwner {
  late final _up = own(PointBuffer()); // allocated on first use

  void paint(Canvas canvas, Iterable<Rect> bars, Paint paint) {
    for (final r in bars) {
      _up.addSegment(r.center.dx, r.top, r.center.dx, r.bottom);
    }
    _up.flush(canvas, ui.PointMode.lines, paint); // paint.strokeWidth is the bar width
  }

  void dispose() => disposeResources();
}
```

A runnable app is in [example/main.dart](https://github.com/FlexiKline/FlexiKline/blob/main/packages/flexi_painting/example/main.dart).

## Versioning

The API may still change between `0.x` minor versions; breaking changes are marked in the [CHANGELOG](CHANGELOG.md).

## License

[Apache License 2.0](LICENSE)
