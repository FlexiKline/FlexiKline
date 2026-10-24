# FlexiKline

[![flexi_kline](https://img.shields.io/pub/v/flexi_kline.svg?label=flexi_kline)](https://pub.dev/packages/flexi_kline) [![flexi_kline_draw_tools](https://img.shields.io/pub/v/flexi_kline_draw_tools.svg?label=flexi_kline_draw_tools)](https://pub.dev/packages/flexi_kline_draw_tools) [![CI](https://github.com/FlexiKline/FlexiKline/actions/workflows/ci.yml/badge.svg)](https://github.com/FlexiKline/FlexiKline/actions/workflows/ci.yml) [![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

[English](README.md) | 简体中文

FlexiKline 是面向股票、数字货币行情的 Flutter K 线图表框架。指标、绘制工具、样式和手势都是可替换的扩展点，业务侧按需组合。

**[在线体验](https://flexikline.github.io)**

## 特性

- **指标框架**：直绘、预计算、外部数据三类指标；计算与绘制解耦，可单独测试；指标支持动画。
- **绘制工具框架**：实现 `DrawObject` 定义图形与命中判定；[flexi_kline_draw_tools](packages/flexi_kline_draw_tools) 内置 19 种工具。
- **一切可配置**：样式、参数、指标、绘制整体序列化，写入时机由业务侧决定。
- **主副区布局**：全屏 / 横屏切换，图表宽高可动态调整。
- **手势**：支持触摸、鼠标、触控板与键盘；惯性平移、双指或滚轮缩放、十字线、价格轴缩放、副区高度调整；参数可调，可嵌入滚动容器。
- **多平台**：Android、iOS、Web、macOS、Windows、Linux。

## 包

| 包 | Pub | 说明 |
| --- | --- | --- |
| [flexi_kline](packages/flexi_kline) | [![pub](https://img.shields.io/pub/v/flexi_kline.svg)](https://pub.dev/packages/flexi_kline) | 核心框架：图表 Widget 与 Controller、指标框架、十字线与 tooltip、手势、主题与配置 |
| [flexi_kline_draw_tools](packages/flexi_kline_draw_tools) | [![pub](https://img.shields.io/pub/v/flexi_kline_draw_tools.svg)](https://pub.dev/packages/flexi_kline_draw_tools) | 19 种绘图工具：线、矩形与通道、斐波那契、艾略特波浪 |

核心包自带蜡烛与时间轴指标；MA、MACD 等其他指标基于指标框架实现，写法见[指标系统](packages/flexi_kline/README_zh.md#指标系统)。

## 快速上手

```yaml
dependencies:
  flexi_kline: ^2.6.1
  flexi_kline_draw_tools: ^2.6.0 # 可选
```

用法、配置与指标系统见 [flexi_kline README](packages/flexi_kline/README_zh.md)；最小示例见 [example/main.dart](packages/flexi_kline/example/main.dart)。

## 性能

真机 profile 模式，`flexi_kline` 2.6.1，UI 线程帧耗时 p90（括号内为占帧预算的比例）。

| 设备 | 帧预算 | 基础 | 完整 |
| --- | ---: | ---: | ---: |
| iPhone 16 · 60Hz | 16.67 ms | 1.6 ms（10%） | 4.5 ms（27%） |
| 一加 15T · 60Hz | 16.67 ms | 2.0 ms（12%） | 6.1 ms（37%） |
| 荣耀 80 Pro · 60Hz | 16.67 ms | 4.3 ms（26%） | 9.7 ms（58%） |
| 荣耀 80 Pro · 120Hz | 8.33 ms | 2.6 ms（32%） | 6.5 ms（78%） |

场景：在图表上持续来回拖动。基础：蜡烛与时间轴；完整：另含主图 VOL、MA 与副图 MACD、VOLMA。

相比 2.5.6，同样的拖动 UI 线程耗时降低 13%～44%，raster 变化不大。方法和全部场景见 [docs/benchmark](docs/benchmark/README.md)。

## 目录结构

基于 Dart `pub workspaces` 的 monorepo：

```
packages/
├── flexi_kline/              核心包
└── flexi_kline_draw_tools/   绘图工具包
apps/
├── demo/                     全平台 demo
└── benchmark/                真机 benchmark app
docs/benchmark/               benchmark 结果
tool/                         仓库脚本
```

## License

[Apache License 2.0](LICENSE)
