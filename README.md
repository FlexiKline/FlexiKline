# FlexiKline [![pub package](https://img.shields.io/pub/v/flexi_kline.svg)](https://pub.dev/packages/flexi_kline)

FlexiKline 是一个 Flutter 金融 K 线图表框架，指标、绘制工具、样式与手势都可以替换或扩展，适用于股票、数字货币等行情展示场景。

本仓库用 Dart 原生 `pub workspaces` 组织的 monorepo，核心包 `flexi_kline` 与绘图工具包 `flexi_kline_draw_tools` 同仓维护。

## Demo

[在线体验](https://flexikline.github.io)

## 包

| 包 | 版本 | 说明 |
| --- | --- | --- |
| [flexi_kline](packages/flexi_kline) | [![pub package](https://img.shields.io/pub/v/flexi_kline.svg)](https://pub.dev/packages/flexi_kline) | 核心 K 线图框架 |
| [flexi_kline_draw_tools](packages/flexi_kline_draw_tools) | [![pub package](https://img.shields.io/pub/v/flexi_kline_draw_tools.svg)](https://pub.dev/packages/flexi_kline_draw_tools) | 绘图工具扩展包 |

`apps/` 放不发布的应用（`apps/demo` 为全平台 demo，当前占位，后续实现）。

### flexi_kline_draw_tools

[flexi_kline](https://pub.dev/packages/flexi_kline) 的绘图工具扩展包，提供趋势线、斐波那契、平行通道等 19 种绘图工具。版本号 major 与 `flexi_kline` 对齐，之后独立演进：

| flexi_kline_draw_tools | flexi_kline | Flutter |
| ---------------------- | ----------- | ------- |
| 2.0.1                  | ^2.5.4      | >=3.35.0 |
| 2.0.0                  | ^2.5.1      | >=3.27.0 |

完整说明见 [packages/flexi_kline_draw_tools/README.md](packages/flexi_kline_draw_tools/README.md)。

## 快速上手

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  flexi_kline: ^2.5.6
```

完整用法（配置、指标系统、绘制工具、参数定制）见 [packages/flexi_kline/README.md](packages/flexi_kline/README.md)。

## 开发

环境要求：Dart SDK ≥ 3.9.0，Flutter ≥ 3.35.0（版本见根目录 `.fvmrc`）。

```bash
fvm flutter pub get          # 根目录，一次解析整个 workspace
fvm flutter analyze          # 根目录，递归覆盖全部成员
fvm flutter test packages/flexi_kline/test packages/flexi_kline_draw_tools/test \
  --exclude-tags "exploration,benchmark"
```

## 发布

各包版本独立维护，tag 规则 `<包名>-v<版本>`（如 `flexi_kline-v2.6.0`）。发布顺序恒为 core → dependents。见 `.github/workflows/publish.yml`。

## 目录结构

```
FlexiKline/
├── pubspec.yaml              ← workspace 根（name: flexi_kline_workspace，不发布）
├── packages/                 ← 可发布的包
│   ├── flexi_kline/
│   └── flexi_kline_draw_tools/
└── apps/                     ← 不发布的应用
    └── demo/                 ← 全平台 demo（占位中）
```