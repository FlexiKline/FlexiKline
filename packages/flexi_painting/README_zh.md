# flexi_painting

[![pub](https://img.shields.io/pub/v/flexi_painting.svg)](https://pub.dev/packages/flexi_painting)

![绘制页面](https://raw.githubusercontent.com/FlexiKline/FlexiKline.github.io/main/media/painting.png)

![绘制页面录屏](https://raw.githubusercontent.com/FlexiKline/FlexiKline.github.io/main/media/painting.gif)

[English](https://github.com/FlexiKline/FlexiKline/blob/main/packages/flexi_painting/README.md) | 简体中文

在 Flutter `painting` 库之上扩展的绘制原语，用于自绘组件与图表。在 Flutter 已有能力之外，补充带缓存的文字标签与提示框、可用于 Widget 与画布的异形边框和代码绘制图标、批量绘制、几何工具，以及跨帧绘制资源管理。只依赖 Flutter，不含图表语义。[flexi_kline](https://pub.dev/packages/flexi_kline) 基于它绘制，并重新导出它。

## 版本要求

- **Flutter SDK**: >= 3.41.0
- **Dart SDK**: >= 3.11.0

> 本包不 import Flutter 的 `material.dart` 和 `cupertino.dart`。无论应用使用 Material、`material_ui`，还是都不用，都可以直接接入。已在 Flutter 3.41.0（最低支持版本）和 3.50.0 上测试通过；3.50.0 中这两个框架库已标为废弃。

## 功能

| 能力 | API | 说明 |
| --- | --- | --- |
| 异形边框 | `BubbleBorder`、`GradientRoundedRectangleBorder` | 箭头可在任意一边的气泡、渐变边框的圆角矩形。二者都是 `ShapeBorder`，可用于 `ShapeDecoration`、`ClipPath`、`Material`。 |
| 画布标签 | `LabelPainter`、`LabelStyle` | 带内边距与背景的文字。只在 key 或排版样式变化时重新排版；按锚点与对齐方式摆放，可限定在区域内；`paintAround` 放不下时翻到目标另一侧。 |
| 行内图片 | `RawImageSpan` | 把已解码的 `ui.Image` 排进标签文字行内，按 `filterQuality` 采样（默认 `low`）。 |
| 图片与提示框 | `ImagePainter`、`TooltipPainter` | 缓存与摆放方式同标签；tooltip 行内按 `MainAxisAlignment` 风格对齐，`spacing` 保底为两列最小间距。 |
| 代码绘制的图标 | `IconShape`、`ShapeIcon`、`ShapeImage`、`ShapeImageProvider` | 图形描述一次，可作矢量 Widget（与 `Icon` 一样取 `IconTheme` 默认值）、画布标签里的行内缓存位图，或用在只接受 `ImageProvider` 的地方。`TriangleShape`、`ChevronShape`、`StarShape` 等内置图形可选传圆角、线宽等细节参数。 |
| 批量绘制 | `PointBuffer` | 攒齐同一画笔的点或线段，一次 `drawRawPoints` 画完；缓冲跨帧复用。 |
| 资源管理 | `PaintResource`、`PaintResourceOwner` | 登记跨帧持有的对象，由持有者统一重置缓存与释放。 |

## 范围

不包含图表语义：坐标映射、刻度、坐标轴、十字线手势与动画由基于它的图表库负责。不解析 SVG；业务图标以图形描述的形式写在使用它的 App 或库里。

## 用法

```yaml
dependencies:
  flexi_painting: ^0.2.0
```

```dart
final label = LabelPainter(); // 跨帧复用，随持有者一起 dispose

label.paint(
  canvas,
  price, // key 必须唯一决定文本，命中缓存时不调用 build
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

同一个图形既作 Widget 图标，也放进画布标签：

```dart
const arrow = TriangleShape(direction: AxisDirection.up);

ShapeIcon(arrow, size: Size.square(16), color: Color(0xFF26A69A));

final arrowImage = ShapeImage(arrow, const Size(6, 6)); // 每种颜色一张位图，随持有者 dispose

label.paint(
  canvas,
  (price, color), // 颜色也决定内容，要放进 key
  build: () => TextSpan(children: [TextSpan(text: '$price '), arrowImage.span(color)]),
  style: style,
  anchor: anchor,
);
```

一次调用画完一批柱子，缓冲交给持有者管理：

```dart
class Bars with PaintResourceOwner {
  late final _up = own(PointBuffer()); // 首次使用时才分配

  void paint(Canvas canvas, Iterable<Rect> bars, Paint paint) {
    for (final r in bars) {
      _up.addSegment(r.center.dx, r.top, r.center.dx, r.bottom);
    }
    _up.flush(canvas, ui.PointMode.lines, paint); // paint.strokeWidth 即柱宽
  }

  void dispose() => disposeResources();
}
```

可运行的示例见 [example/main.dart](https://github.com/FlexiKline/FlexiKline/blob/main/packages/flexi_painting/example/main.dart)。

## 版本

`0.x` 期间 minor 版本之间 API 仍可能变化，破坏性变更在 [CHANGELOG](CHANGELOG.md) 中标注。

## 许可证

[Apache License 2.0](LICENSE)
