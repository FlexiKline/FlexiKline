# flexi_kline_draw_tools

[English](README.md) | 简体中文

[flexi_kline](https://pub.dev/packages/flexi_kline) 的绘图工具扩展包，提供趋势线、斐波那契、平行通道等 19 种绘图工具。

## 版本兼容

| flexi_kline_draw_tools | flexi_kline | Flutter |
| ---------------------- | ----------- | ------- |
| 2.6.0                  | ^2.6.0      | >=3.41.0 |
| 2.0.1                  | ^2.5.4      | >=3.35.0 |
| 2.0.0                  | ^2.5.1      | >=3.27.0 |

> v2 期间版本号 major.minor 等于所需 `flexi_kline` 的最低 major.minor（如 2.6.x 需要 `^2.6.0`），自身的修复与功能只升 patch；`flexi_kline` 升级而本包无需新能力时不跟随发版。v2 稳定后只对齐 major。

## 安装

```yaml
dependencies:
  flexi_kline_draw_tools: ^2.6.0
```

## 快速上手

两种方式注册绘图工具（二选一），可运行的最小示例见 [example/main.dart](example/main.dart)：

```dart
// 方式一：函数调用
registerAllDrawObjectBuilder(controller);

// 方式二：混入配置类
class MyConfig extends FlexiKlineStorage
    with FlexiKlineConfigurationMixin, DrawObjectBuildersConfigMixin {
  // drawObjectBuilders 已自动提供
}
```

绘制还需开启 `DrawConfig.enable`；用 `controller.startDraw(trendLine)` 开始绘制。

## 支持的绘图工具

| 分组 | 工具 | 点数 |
| ---- | ---- | ---- |
| Lines | trendLine, arrowLine, extendedTrendLine, trendAngle, rayLine, horizontalTrendLine, horizontalRayLine | 2 |
| Lines | horizontalLine, verticalLine, crossLine, priceLine | 1 |
| Projection | rectangle | 2 |
| Projection | parallelChannel, parallelogram | 3 |
| Fibonacci | fibRetracement, fibFans | 2 |
| Fibonacci | fibExpansion | 3 |
| Patterns | tripleWaves | 4 |
| Patterns | pentaWaves | 6 |

> `tripleWaves` 和 `pentaWaves` 都由 `ElliottImpulseWaveDrawObject` 实现，区别仅在点数。

## 参数定制

通过 `DrawToolsConfig.configure()` 统一配置，只传入需要修改的参数：

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

各工具的参数类：

| 工具 | 参数类 | 主要字段 |
| ---- | ------ | -------- |
| ArrowLine | `ArrowLineDrawParam` | arrowsRadians, arrowsLen |
| PriceLine | `PriceLineDrawParam` | priceText, priceTextMargin |
| TrendAngle | `TrendAngleDrawParam` | angleBaseLineMinLen, angleRadSize, angleText |
| ParallelChannel | `ParallelChannelDrawParam` | parallelBgOpacity |
| Rectangle | `RectangleDrawParam` | rectangleBgOpacity |
| Parallelogram | `ParallelogramDrawParam` | bgOpacity |
| FibExpansion | `FibonacciDrawParam` | fibRates, fibColors, fibBgOpacity, fibText |
| FibRetracement | `FibonacciDrawParam` | 同上（独立实例） |
| FibFans | `FibFansDrawParam` | fibFansParams, fibFansColors, fibFansGridColor, fibText |

> 线色、线宽、虚线样式由核心包的 `Overlay.line` 控制，不在此配置。
> `priceText` 和 `angleText` 默认为 `null`，回退到核心包 `DrawConfig.ticksText` 的主题色。

## License

[Apache License 2.0](./LICENSE)
