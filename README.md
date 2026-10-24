# FlexiKline

[![flexi_kline](https://img.shields.io/pub/v/flexi_kline.svg?label=flexi_kline)](https://pub.dev/packages/flexi_kline)
[![flexi_kline_draw_tools](https://img.shields.io/pub/v/flexi_kline_draw_tools.svg?label=flexi_kline_draw_tools)](https://pub.dev/packages/flexi_kline_draw_tools)
[![CI](https://github.com/FlexiKline/FlexiKline/actions/workflows/ci.yml/badge.svg)](https://github.com/FlexiKline/FlexiKline/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

English | [简体中文](README_zh.md)

FlexiKline is a Flutter candlestick (K-line) chart framework for stock and crypto markets. Indicators, drawing tools, styles and gestures are all replaceable extension points, composed by your app as needed.

**[Try the online demo](https://flexikline.github.io)**

## Features

- **Indicator framework**: direct, computed and external indicators; calculation is decoupled from painting and testable on its own; indicators can animate.
- **Drawing tool framework**: implement `DrawObject` for your own shape and hit test; [flexi_kline_draw_tools](packages/flexi_kline_draw_tools) ships 19 tools.
- **Everything configurable**: styles, params, indicators and drawings serialize as a whole; when to persist is up to your app.
- **Main/sub panes**: fullscreen and landscape switching, chart size adjustable at runtime.
- **Gestures**: touch, mouse, trackpad and keyboard; pan with inertia, pinch or wheel zoom, crosshair, price-axis scaling, pane resizing; tunable, and works inside scrollable containers.
- **Platforms**: Android, iOS, Web, macOS, Windows, Linux.

## Packages

| Package | Pub | Description |
| --- | --- | --- |
| [flexi_kline](packages/flexi_kline) | [![pub](https://img.shields.io/pub/v/flexi_kline.svg)](https://pub.dev/packages/flexi_kline) | Core framework: chart widget and controller, indicator framework, crosshair and tooltip, gestures, theme and configuration |
| [flexi_kline_draw_tools](packages/flexi_kline_draw_tools) | [![pub](https://img.shields.io/pub/v/flexi_kline_draw_tools.svg)](https://pub.dev/packages/flexi_kline_draw_tools) | 19 drawing tools: lines, rectangle and channels, Fibonacci, Elliott waves |

The core package ships the candle and time-axis indicators; others such as MA and MACD are built on the indicator framework, see [Indicators](packages/flexi_kline/README.md#indicators).

## Quick start

```yaml
dependencies:
  flexi_kline: ^2.6.1
  flexi_kline_draw_tools: ^2.6.0 # optional
```

Usage, configuration and the indicator system are documented in the [flexi_kline README](packages/flexi_kline/README.md); a minimal app is in [example/main.dart](packages/flexi_kline/example/main.dart).

## Performance

Real devices, profile mode, `flexi_kline` 2.6.1: p90 of UI-thread frame time (share of frame budget in brackets).

| Device | Frame budget | Basic | Full |
| --- | ---: | ---: | ---: |
| iPhone 16 · 60Hz | 16.67 ms | 1.6 ms (10%) | 4.5 ms (27%) |
| OnePlus 15T · 60Hz | 16.67 ms | 2.0 ms (12%) | 6.1 ms (37%) |
| Honor 80 Pro · 60Hz | 16.67 ms | 4.3 ms (26%) | 9.7 ms (58%) |
| Honor 80 Pro · 120Hz | 8.33 ms | 2.6 ms (32%) | 6.5 ms (78%) |

Scenario: dragging the chart back and forth continuously. Basic: candles and time axis. Full: plus main-pane VOL and MA, and sub-pane MACD and VOLMA.

Compared with 2.5.6, the same drag takes 13%–44% less UI-thread time; raster changes little. Method and every scenario: [docs/benchmark](docs/benchmark/README.md).

## Repository layout

A Dart `pub workspaces` monorepo:

```
packages/
├── flexi_kline/              core package
└── flexi_kline_draw_tools/   drawing tools package
apps/
├── demo/                     multi-platform demo
└── benchmark/                on-device benchmark app
docs/benchmark/               benchmark results
tool/                         repository scripts
```

## License

[Apache License 2.0](LICENSE)
