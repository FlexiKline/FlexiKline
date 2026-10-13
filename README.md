# FlexiKline

[![flexi_kline](https://img.shields.io/pub/v/flexi_kline.svg?label=flexi_kline)](https://pub.dev/packages/flexi_kline)
[![flexi_kline_draw_tools](https://img.shields.io/pub/v/flexi_kline_draw_tools.svg?label=flexi_kline_draw_tools)](https://pub.dev/packages/flexi_kline_draw_tools)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

English | [简体中文](README_zh.md)

A flexible Flutter candlestick (K-line) chart framework for stock and crypto markets. Indicators, drawing tools, styles and gestures can all be replaced or extended. Runs on Android, iOS, Web, macOS, Windows and Linux.

**[Try the online demo](https://flexikline.github.io)**

## Packages

| Package | Version | Description |
| ------- | ------- | ----------- |
| [flexi_kline](packages/flexi_kline) | [![pub](https://img.shields.io/pub/v/flexi_kline.svg)](https://pub.dev/packages/flexi_kline) | Core chart framework: layout, gestures, indicators, configuration |
| [flexi_kline_draw_tools](packages/flexi_kline_draw_tools) | [![pub](https://img.shields.io/pub/v/flexi_kline_draw_tools.svg)](https://pub.dev/packages/flexi_kline_draw_tools) | Built-in drawing tools: trend lines, Fibonacci, channels and more |

## Quick start

```yaml
dependencies:
  flexi_kline: ^2.6.0
  flexi_kline_draw_tools: ^2.6.0 # optional
```

Usage, configuration and the indicator system are documented in the [flexi_kline README](packages/flexi_kline/README.md); a minimal app is in [example/main.dart](packages/flexi_kline/example/main.dart).

## Repository layout

A Dart `pub workspaces` monorepo:

```
packages/
├── flexi_kline/              core package
└── flexi_kline_draw_tools/   drawing tools package
apps/
└── demo/                     multi-platform demo (not published)
```

## Development

Requires Dart >= 3.11.0 and Flutter >= 3.41.0 (pinned in `.fvmrc`).

```bash
fvm flutter pub get          # resolves the whole workspace
fvm flutter analyze          # analyzes all members
fvm flutter test packages/flexi_kline/test packages/flexi_kline_draw_tools/test \
  --exclude-tags "exploration,benchmark"
```

Packages are versioned independently and released by tag `<package>-v<version>` (e.g. `flexi_kline-v2.6.0`), core first. See [publish.yml](.github/workflows/publish.yml).

## License

[Apache License 2.0](LICENSE)
