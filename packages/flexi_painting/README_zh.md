# flexi_painting

[![pub](https://img.shields.io/pub/v/flexi_painting.svg)](https://pub.dev/packages/flexi_painting)

[English](https://github.com/FlexiKline/FlexiKline/blob/main/packages/flexi_painting/README.md) | 简体中文

Flutter 画布绘制原语，只依赖 Flutter。用 `CustomPainter` 自绘图表、订单簿或自定义控件时补上 Flutter 缺的那部分；其中的边框也能直接当普通 Widget 的装饰用。[flexi_kline](https://pub.dev/packages/flexi_kline) 基于它绘制，并重新导出它。

## 功能

- **异形边框**：`BubbleBorder`（箭头可在任意一边的气泡，可选渐变边框）、`GradientRoundedRectangleBorder`。二者都是 `ShapeBorder`，可用于 `ShapeDecoration`、`ClipPath`、`Material`。
- **带缓存的标签**：`LabelPainter` 只在 key 或样式变化时重新排版，按锚点与对齐方式摆放，可限定在区域内；`paintAround` 放不下时翻到目标另一侧。`RawImageSpan` 把已解码的 `ui.Image` 排进文字行内。
- **图片与提示框**：`ImagePainter`、`TooltipPainter`，缓存与摆放方式同上。
- **代码绘制的图标**：`ShapeImage` 把小矢量图形栅格化并缓存，供行内使用。
- **批量绘制**：`PointBuffer` 攒齐同一画笔的点或线段，一次画完。
- **资源管理**：`PaintResource`、`PaintResourceOwner` 负责跨帧绘制资源的重置与释放。

## 用法

```yaml
dependencies:
  flexi_painting: ^0.1.0
```

```dart
final label = LabelPainter(); // 跨帧复用，随持有者一起 dispose

label.paint(
  canvas,
  price, // key 必须唯一决定文本，命中缓存时不调用 build
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

可运行的示例见 [example/main.dart](https://github.com/FlexiKline/FlexiKline/blob/main/packages/flexi_painting/example/main.dart)。

## 版本

`0.x` 期间 minor 版本之间 API 仍可能变化，破坏性变更在 [CHANGELOG](CHANGELOG.md) 中标注。

## 许可证

[Apache License 2.0](LICENSE)
