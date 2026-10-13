# flexi_kline_draw_tools

English | [简体中文](https://github.com/FlexiKline/FlexiKline/blob/main/packages/flexi_kline_draw_tools/README_zh.md)

Drawing tools for [flexi_kline](https://pub.dev/packages/flexi_kline): trend lines, Fibonacci, parallel channels and more.

## Compatibility

| flexi_kline_draw_tools | flexi_kline | Flutter |
| ---------------------- | ----------- | ------- |
| 2.6.0                  | ^2.6.0      | >=3.41.0 |
| 2.0.1                  | ^2.5.4      | >=3.35.0 |
| 2.0.0                  | ^2.5.1      | >=3.27.0 |

> During v2, major.minor matches the minimum required `flexi_kline` major.minor (2.6.x needs `^2.6.0`); fixes and features of this package only bump patch, and it is not re-released when `flexi_kline` upgrades without needing new capabilities. After v2 stabilizes only major is aligned.

## Installation

```yaml
dependencies:
  flexi_kline_draw_tools: ^2.6.0
```

## Quick start

Register the tools in one of two ways. A runnable minimal app is in [example/main.dart](example/main.dart).

```dart
// Option 1: function call
registerAllDrawObjectBuilder(controller);

// Option 2: mix into your configuration
class MyConfig extends FlexiKlineStorage
    with FlexiKlineConfigurationMixin, DrawObjectBuildersConfigMixin {
  // drawObjectBuilders is provided
}
```

Drawing also requires `DrawConfig.enable`; start a tool with `controller.startDraw(trendLine)`.

## Tools

| Group | Tools | Points |
| ----- | ----- | ------ |
| Lines | trendLine, arrowLine, extendedTrendLine, trendAngle, rayLine, horizontalTrendLine, horizontalRayLine | 2 |
| Lines | horizontalLine, verticalLine, crossLine, priceLine | 1 |
| Projection | rectangle | 2 |
| Projection | parallelChannel, parallelogram | 3 |
| Fibonacci | fibRetracement, fibFans | 2 |
| Fibonacci | fibExpansion | 3 |
| Patterns | tripleWaves | 4 |
| Patterns | pentaWaves | 6 |

> `tripleWaves` and `pentaWaves` are both implemented by `ElliottImpulseWaveDrawObject`; they differ only in point count.

## Customization

Configure everything through `DrawToolsConfig.configure()`, passing only what you change:

```dart
DrawToolsConfig.configure(
  arrowLine: const ArrowLineDrawParam(arrowsLen: 20),
  rectangle: const RectangleDrawParam(rectangleBgOpacity: 0.2),
  priceLine: const PriceLineDrawParam(
    priceText: TextAreaConfig(
      style: TextStyle(color: Color(0xFFFF0000), fontSize: 11),
    ),
  ),
);
```

Param classes per tool:

| Tool | Param class | Main fields |
| ---- | ----------- | ----------- |
| ArrowLine | `ArrowLineDrawParam` | arrowsRadians, arrowsLen |
| PriceLine | `PriceLineDrawParam` | priceText, priceTextMargin |
| TrendAngle | `TrendAngleDrawParam` | angleBaseLineMinLen, angleRadSize, angleText |
| ParallelChannel | `ParallelChannelDrawParam` | parallelBgOpacity |
| Rectangle | `RectangleDrawParam` | rectangleBgOpacity |
| Parallelogram | `ParallelogramDrawParam` | bgOpacity |
| FibExpansion | `FibonacciDrawParam` | fibRates, fibColors, fibBgOpacity, fibText |
| FibRetracement | `FibonacciDrawParam` | Same as above (separate instance) |
| FibFans | `FibFansDrawParam` | fibFansParams, fibFansColors, fibFansGridColor, fibText |

> Line color, width and dash style come from the core package's `Overlay.line`, not from here.
> `priceText` and `angleText` default to `null` and fall back to the theme color of the core package's `DrawConfig.ticksText`.

## License

[Apache License 2.0](./LICENSE)
