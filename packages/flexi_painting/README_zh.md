# flexi_painting

[![pub](https://img.shields.io/pub/v/flexi_painting.svg)](https://pub.dev/packages/flexi_painting)

[English](https://github.com/FlexiKline/FlexiKline/blob/main/packages/flexi_painting/README.md) | 简体中文

Flutter 自绘图表与组件的底层绘制工具，只依赖 Flutter：给 `CustomPainter` 用的跨帧缓存标签、提示框、批量绘制与资源管理，几何工具，以及 Widget 与画布通用的异形边框和代码绘制图标。[flexi_kline](https://pub.dev/packages/flexi_kline) 基于它绘制，并重新导出它。

## 版本要求

- **Flutter SDK**: >= 3.41.0
- **Dart SDK**: >= 3.11.0

> 本包不 import Flutter 的 `material.dart` 和 `cupertino.dart`。无论应用使用 Material、`material_ui`，还是都不用，都可以直接接入。已在 Flutter 3.41.0（最低支持版本）和 3.50.0 上测试通过；3.50.0 中这两个框架库已标为废弃。

## 功能

- **异形边框**：`BubbleBorder`（箭头可在任意一边的气泡，可选渐变边框）、`GradientRoundedRectangleBorder`。二者都是 `ShapeBorder`，可用于 `ShapeDecoration`、`ClipPath`、`Material`。
- **带缓存的标签**：`LabelPainter` 只在 key 或样式变化时重新排版，按锚点与对齐方式摆放，可限定在区域内；`paintAround` 放不下时翻到目标另一侧。`RawImageSpan` 把已解码的 `ui.Image` 排进文字行内。
- **图片与提示框**：`ImagePainter`、`TooltipPainter`，缓存与摆放方式同上；tooltip 行内按 `MainAxisAlignment` 风格对齐，`spacing` 保底为两列最小间距。
- **代码绘制的图标**：图形用 `IconShape` 描述一次；在 Widget 中用 `ShapeIcon` 矢量显示（与 `Icon` 一样取 `IconTheme` 默认值），在画布标签里用 `ShapeImage` 行内显示，只接受 `ImageProvider` 的地方用 `ShapeImageProvider`。
- **批量绘制**：`PointBuffer` 攒齐同一画笔的点或线段，一次画完。
- **资源管理**：`PaintResource`、`PaintResourceOwner` 负责跨帧绘制资源的重置与释放。

## 范围

不包含图表语义：坐标映射、刻度、坐标轴、十字线手势与动画由基于它的图表库负责。不解析 SVG；业务图标以图形描述的形式写在使用它的 App 或库里。

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
    text: TextStyle(color: Color(0xFF000000), fontSize: 12),
    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: ShapeDecoration(color: Color(0xFFFFC107), shape: BubbleBorder()),
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
