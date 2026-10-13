# FlexiKline

[![flexi_kline](https://img.shields.io/pub/v/flexi_kline.svg?label=flexi_kline)](https://pub.dev/packages/flexi_kline)
[![flexi_kline_draw_tools](https://img.shields.io/pub/v/flexi_kline_draw_tools.svg?label=flexi_kline_draw_tools)](https://pub.dev/packages/flexi_kline_draw_tools)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

[English](README.md) | 简体中文

FlexiKline 是一个 Flutter 金融 K 线图表框架，指标、绘制工具、样式与手势都可以替换或扩展，适用于股票、数字货币等行情展示场景，支持 Android、iOS、Web、macOS、Windows、Linux。

**[在线体验](https://flexikline.github.io)**

## 包

| 包 | 版本 | 说明 |
| --- | --- | --- |
| [flexi_kline](packages/flexi_kline) | [![pub](https://img.shields.io/pub/v/flexi_kline.svg)](https://pub.dev/packages/flexi_kline) | 核心图表框架：布局、手势、指标、配置 |
| [flexi_kline_draw_tools](packages/flexi_kline_draw_tools) | [![pub](https://img.shields.io/pub/v/flexi_kline_draw_tools.svg)](https://pub.dev/packages/flexi_kline_draw_tools) | 内置绘图工具：趋势线、斐波那契、通道等 |

## 快速上手

```yaml
dependencies:
  flexi_kline: ^2.6.0
  flexi_kline_draw_tools: ^2.6.0 # 可选
```

用法、配置与指标系统见 [flexi_kline README](packages/flexi_kline/README_zh.md)；最小示例见 [example/main.dart](packages/flexi_kline/example/main.dart)。

## 目录结构

基于 Dart `pub workspaces` 的 monorepo：

```
packages/
├── flexi_kline/              核心包
└── flexi_kline_draw_tools/   绘图工具包
apps/
└── demo/                     全平台 demo（不发布）
```

## 开发

要求 Dart >= 3.11.0、Flutter >= 3.41.0（版本见 `.fvmrc`）。

```bash
fvm flutter pub get          # 一次解析整个 workspace
fvm flutter analyze          # 递归覆盖全部成员
fvm flutter test packages/flexi_kline/test packages/flexi_kline_draw_tools/test \
  --exclude-tags "exploration,benchmark"
```

各包版本独立维护，按 tag `<包名>-v<版本>`（如 `flexi_kline-v2.6.0`）发布，先发核心包。见 [publish.yml](.github/workflows/publish.yml)。

## License

[Apache License 2.0](LICENSE)
