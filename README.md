# FlexiKline

FlexiKline是一个灵活且高度可定制化的金融Kline图表框架，旨在满足不同用户的需求. 

## Demo

[https://flexikline.github.io](https://flexikline.github.io)

## 特性

+ 内置多种常用指标, 支持添加自定义指标.
+ 内置多种绘图工具, 支持添加自定义绘制工具.
+ 支持全屏/横屏/主副区图表宽高设定与动态调整.
+ 可定制化与持久化样式, 配置, 参数(包括指标/绘制等所有功能).
+ 适配多平台手势操作, 且可定制化操作(惯性平移/缩放位置等).
+ 支持多种平台(Android, iOS, Web, MacOs, Windows, Linux).


## Sample

### 1. Custom FlexiKlineConfiguration

实现IConfiguration接口.
```dart
/// FlexiKline配置接口
abstract interface class IConfiguration {
  /// FlexiKline初始化默认的主区的宽高.
  Size get initialMainSize;

  /// 获取FlexiKline配置
  /// 1. 如果本地有缓存, 则从缓存中获取.
  /// 2. 如果本地没有缓存, 根据当前主题生成一套FlexiKline配置.
  FlexiKlineConfig getFlexiKlineConfig([covariant IFlexiKlineTheme? theme]);

  /// 保存[config]配置信息到本地.
  void saveFlexiKlineConfig(FlexiKlineConfig config);

  /// 从本地获取[instId]指定的[Overlay]缓存列表.
  Iterable<Overlay> getOverlayListConfig(String instId);

  /// 以[instId]为key, 保存[list]持久化到本地中.
  void saveOverlayListConfig(String instId, Iterable<Overlay> list);
}
```
主题配置[IFlexiKlineTheme](https://github.com/FlexiKline/FlexiKline/blob/main/lib/src/framework/configuration.dart#L24)

参考Demo实现:
[DefaultFlexiKlineConfiguration](https://github.com/FlexiKline/FlexiKline/blob/main/example/lib/src/providers/default_kline_config.dart#L120) 
[BitFlexiKlineConfiguration](https://github.com/FlexiKline/FlexiKline/blob/main/example/lib/src/providers/bit_kline_config.dart#L163)


### 2. New FlexiKlineController

```dart
  controller = FlexiKlineController(
    configuration: configuration,
    logger: LoggerImpl(
      tag: "FlexiKline",
      debug: kDebugMode,
    ),
  );

  // 添加自定义指标
  controller.addCustomMainIndicatorConfig(XxxIndicator);

  // 注册自定义绘制工具
  controller.registerDrawOverlayObjectBuilder(IDrawType, DrawObjectBuilder);
```

### 3. FlexiKlineWidget
```dart
FlexiKlineWidget(
  controller: controller,
  mainBackgroundView: FlexiKlineMarkView(),
  mainForegroundViewBuilder: _buildKlineMainForgroundView,
  onDoubleTap: setFullScreen,
  drawToolbar: FlexiKlineDrawToolbar(
    controller: controller,
  ),
),
```

### 4. UpdateKlineData
```dart
/// 根据[request]切换当前Kline图表数据源[KlineData]; 如果发生变更TimerBar时.
flexiKlineController.switchKlineData(request, useCacheFirst: true);

/// 更新[request]指定的数据
flexiKlineController.updateKlineData(request, resp.data);
```

## 如何配置

### [FlexiKline完整配置.json](./doc/default_flexi_kline_configuration.json)

待更新....


## [TODO](./TODO.md)

## Reference

[Flutter 触控板手势](https://docs.google.com/document/d/1oRvebwjpsC3KlxN1gOYnEdxtNpQDYpPtUFAkmTUe-K8/edit?resourcekey=0-pt4_T7uggSTrsq2gWeGsYQ)

PR 31593：[Mac 触控板手势macOS](https://github.com/flutter/engine/pull/31593)