# FlexiKline

FlexiKline是一个灵活且高度可定制化的金融Kline图表框架，旨在满足不同用户的需求. 

## Demo

[https://flexikline.github.io](https://flexikline.github.io)

## 特性

+ 自定义指标(实现指标配置与绘制对象接口).
+ 自定义绘制工具(实现绘制工具接口).
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
  /// 当前配置主题
  IFlexiKlineTheme get theme;

  /// FlexiKline初始化默认的主区的宽高.
  Size get initialMainSize;

  /// 获取FlexiKline配置
  /// 1. 如果本地有缓存, 则从缓存中获取.
  /// 2. 如果本地没有缓存, 根据当前主题生成一套FlexiKline配置.
  FlexiKlineConfig getFlexiKlineConfig();

  /// 保存[config]配置信息到本地.
  void saveFlexiKlineConfig(FlexiKlineConfig config);

  /// 蜡烛指标配置构造器(主区)
  IndicatorBuilder get candleIndicatorBuilder;

  /// 时间指标配置构造器(副区)
  IndicatorBuilder get timeIndicatorBuilder;

  /// 主区指标配置定制
  Map<IIndicatorKey, IndicatorBuilder> mainIndicatorBuilders();

  /// 副区指标配置定制
  Map<IIndicatorKey, IndicatorBuilder> subIndicatorBuilders();

  /// 绘制工具定制
  Map<IDrawType, DrawObjectBuilder> drawObjectBuilders();

  /// 从本地获取[instId]对应的绘制实例数据列表.
  Iterable<Overlay> getDrawOverlayList(String instId);

  /// 以[instId]为key, 持久化绘制实例列表[list]到本地中.
  void saveDrawOverlayList(String instId, Iterable<Overlay> list);
}
```
主题配置[IFlexiKlineTheme](https://github.com/FlexiKline/FlexiKline/blob/main/lib/src/framework/configuration.dart#L24)

推荐混入[FlexiKlineThemeConfigurationMixin](https://github.com/FlexiKline/FlexiKline/blob/main/lib/src/config/default_config.dart#L168)实现


### 2. New FlexiKlineController

```dart
controller = FlexiKlineController(
  configuration: configuration,
  logger: LoggerImpl(
    tag: "FlexiKline",
    debug: kDebugMode,
  ),
);
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

## 自定义指标
```dart
/// MA 移动平均指标线指标配置
class MAIndicator extends SinglePaintObjectIndicator {
  MAIndicator({
    super.zIndex = 0,
    required super.height,
    super.padding = defaultMainIndicatorPadding,
    required this.calcParam,
    required this.tipsPadding,
    required this.lineWidth,
  }) : super(key: maIndicatorKey);

  final List<MaParam> calcParam;
  final EdgeInsets tipsPadding;
  final double lineWidth;

  @override
  SinglePaintObjectBox createPaintObject(IPaintContext context) {
    return MAPaintObject(context: context, indicator: this);
  }
}

/// MA指标绘制对象
class MAPaintObject<T extends MAIndicator> extends SinglePaintObjectBox<T> {

  @override
  void precompute(Range range, {bool reset = false}) {
    // TODO: 针对[range]范围内的数据进行预计算(仅在数据更新时回调)
  }

  @override
  MinMax? initState({required int start, required int end}) {
    // TODO: 返回[start ~ end)之间的数据范围, 即最大最小的MA指标值.
  }

  @override
  void paintChart(Canvas canvas, Size size) {
    // TODO: 绘制MA移动平均指标线
    ...
    paintTips(canvas, model: klineData.latest);
  }

  @override
  void onCross(Canvas canvas, Offset offset) {
    // TODO: 当十字线移动时回调
    ...
    paintTips(canvas, offset: offset);
  }

  @override
  Size? paintTips(
    Canvas canvas, {
    CandleModel? model,
    Offset? offset,
    Rect? tipsRect, // Tips限定的绘制区域
  }) {
    // TODO: 绘制顶部MA Tips信息
  }
}
```

## 自定义绘制工具
```dart
/// 射线
class RayLineDrawObject extends DrawObject {
  RayLineDrawObject(super.overlay, super.config);

  @override
  bool hitTest(IDrawContext context, Offset position, {bool isMove = false}) {
    // TODO: 判断[position]是否命中当前射线
  }

  @override
  void draw(IDrawContext context, Canvas canvas, Size size) {
    // TODO: 绘制射线
  }
}
```

## 如何配置

### [FlexiKline完整配置.json](./doc/default_flexi_kline_configuration.json)

待更新....


## [TODO](./TODO.md)

## Reference

[Flutter 触控板手势](https://docs.google.com/document/d/1oRvebwjpsC3KlxN1gOYnEdxtNpQDYpPtUFAkmTUe-K8/edit?resourcekey=0-pt4_T7uggSTrsq2gWeGsYQ)

PR 31593：[Mac 触控板手势macOS](https://github.com/flutter/engine/pull/31593)