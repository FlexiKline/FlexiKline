# FlexiKline

一个灵活和可定制的Flutter金融图表。

## 特性

+ 内置多种常用指标, 支持添加自定义指标.
+ 可定制化的指标样式与指标设置.
+ 支持全屏/横屏/主区图表宽高动态调整.
+ 可定制化的手势操作(惯性平移/缩放位置)
+ 支持多种平台(Android, iOS, Web, MacOs, Windows, Linux...).


## Sample

1. Custom FlexiKlineConfiguration

实现IConfiguration接口.
```dart
/// FlexiKline配置接口
abstract interface class IConfiguration {
  /// FlexiKline初始或默认的主区的宽高.
  Size get initialMainSize;

  /// 获取FlexiKline配置
  /// 1. 如果本地有缓存, 则从缓存中获取.
  /// 2. 如果本地没有缓存, 根据当前主题生成一套FlexiKline配置.
  FlexiKlineConfig getFlexiKlineConfig();

  /// 保存[config]配置信息到本地; 通过FlexiKlineController调用.
  void saveFlexiKlineConfig(FlexiKlineConfig config);

  /// 自定义主区指标列表
  Iterable<SinglePaintObjectIndicator> customMainIndicators();

  /// 自定义副区指标列表
  Iterable<Indicator> customSubIndicators();
}
```
主题配置[IFlexiKlineTheme](https://github.com/FlexiKline/FlexiKline/blob/main/lib/src/framework/configuration.dart#L24)

参考Demo实现:
[DefaultFlexiKlineConfiguration](https://github.com/FlexiKline/FlexiKline/blob/main/example/lib/src/providers/default_kline_config.dart#L120) 
[BitFlexiKlineConfiguration](https://github.com/FlexiKline/FlexiKline/blob/main/example/lib/src/providers/bit_kline_config.dart#L163)


1. New FlexiKlineController

```dart
  controller = FlexiKlineController(
    configuration: configuration,
    logger: LoggerImpl(
      tag: "FlexiKline",
      debug: kDebugMode,
    ),
  );
```

3. UpdateKlineData
```dart
/// 根据[request]切换[KlineData]数据源, 如果发生变更TimerBar.
flexiKlineController.switchKlineData(request, useCacheFirst: true);

/// 更新[request]指定的数据
flexiKlineController.updateKlineData(request, resp.data);
```

## 配置

### [FlexiKline完整配置.json](./doc/default_flexi_kline_configuration.json)

更新....


## [TODO](./TODO.md)

## Reference

[Flutter 触控板手势](https://docs.google.com/document/d/1oRvebwjpsC3KlxN1gOYnEdxtNpQDYpPtUFAkmTUe-K8/edit?resourcekey=0-pt4_T7uggSTrsq2gWeGsYQ)

PR 31593：[Mac 触控板手势macOS](https://github.com/flutter/engine/pull/31593)