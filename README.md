# FlexiKline [![pub package](https://img.shields.io/pub/v/flexi_kline.svg)](https://pub.dev/packages/flexi_kline)

FlexiKline 是一个高度灵活且可定制的 Flutter 金融 K 线图表框架，适用于股票、数字货币等行情展示场景。

## Demo

[在线体验](https://flexikline.github.io) | [Android APK](https://github.com/FlexiKline/FlexiKline.github.io/blob/main/mobile/flexi_kline_app.apk)

## 版本要求

- **Flutter SDK**: >= 3.27.0
- **Dart SDK**: >= 3.6.0

## 特性

- 自定义指标：实现指标配置与绘制对象接口，灵活扩展
- 自定义绘制工具：实现绘制工具接口，支持多种绘图场景
- 主副区布局：支持全屏 / 横屏，图表宽高可动态调整
- 配置持久化：样式、参数、指标、绘制等所有功能均可定制与持久化
- 手势操作：适配多平台，支持惯性平移、缩放位置、平移平滑等可定制操作
- 多平台支持：Android、iOS、Web、macOS、Windows、Linux

## 安装

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  flexi_kline: ^2.0.0
```

然后运行：

```bash
flutter pub get
```

## 快速上手

### 1. 实现 IConfiguration 接口

自定义配置类，实现主题、指标构建器和绘制工具的定义。推荐混入 [FlexiKlineThemeConfigurationMixin](https://github.com/FlexiKline/FlexiKline/blob/main/lib/src/config/default_config.dart) 获取默认配置。

```dart
abstract interface class IConfiguration implements IStorage {
  /// 当前配置主题
  IFlexiKlineTheme get theme;

  String get configKey;

  /// 生成FlexiKline配置
  FlexiKlineConfig generateFlexiKlineConfig([FlexiKlineConfig? origin]);

  /// 蜡烛指标配置构造器(主区)
  IndicatorBuilder<CandleBaseIndicator> get candleIndicatorBuilder;

  /// 时间指标配置构造器(副区)
  IndicatorBuilder<TimeBaseIndicator> get timeIndicatorBuilder;

  /// 主区指标配置定制
  Map<IIndicatorKey, IndicatorBuilder> get mainIndicatorBuilders;

  /// 副区指标配置定制
  Map<IIndicatorKey, IndicatorBuilder> get subIndicatorBuilders;

  /// 绘制工具定制
  Map<IDrawType, DrawObjectBuilder> get drawObjectBuilders;
}
```

### 2. 创建 FlexiKlineController

```dart
final configuration = FlexiKlineConfiguration();
controller = FlexiKlineController(
  configuration: configuration,
  logger: LoggerImpl(tag: "FlexiKline", debug: kDebugMode),
  subIndicatorMaxCount: defaultSubIndicatorMaxCount,
  klineDataCacheCapacity: 3,
);
```

### 3. 使用 FlexiKlineWidget

```dart
FlexiKlineWidget(
  controller: controller,
  mainBackgroundView: FlexiKlineMarkView(),
  mainForegroundViewBuilder: _buildKlineMainForgroundView,
  onDoubleTap: setFullScreen,
  drawToolbar: FlexiKlineDrawToolbar(controller: controller),
)
```

### 4. 更新数据

```dart
/// 切换数据源（如切换 TimeBar 时）
controller.switchKlineData(request);

/// 更新指定请求的数据
controller.updateKlineData(request, list);
```

## 自定义指标

v2.0.0 引入了类型化的指标体系，通过 `IIndicatorKey` sealed class 区分三类指标：

| 指标类型 | Key 类型 | Indicator 基类 | PaintObject 基类 | 说明 |
|---------|----------|---------------|-----------------|------|
| 普通指标 | `NormalIndicatorKey` | `NormalIndicator` | `NormalPaintObject` | 框架内置（Candle、Time 等），不占 slot |
| 数据指标 | `DataIndicatorKey` | `DataIndicator` | `DataPaintObject` | 需要 precompute，占 slot |
| 业务指标 | `BusinessIndicatorKey` | `BusinessIndicator` | `BusinessPaintObject` | 由业务数据驱动，不占 slot |

### 示例：自定义数据指标

```dart
/// 指标 Key
const maIndicatorKey = DataIndicatorKey('MA', label: 'MA');

/// 指标配置
class MAIndicator extends DataIndicator {
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
  DataPaintObject<MAIndicator> createPaintObject() => MAPaintObject();

  @override
  Map<String, dynamic> toJson() {
    return {"calcParam": calcParam.map((e) => e.toJson()).toList()};
  }
}

/// 指标绘制对象
class MAPaintObject extends DataPaintObject<MAIndicator> {

  @override
  bool shouldPrecompute(MAIndicator oldIndicator) {
    // 判断新旧指标配置的变化是否需要执行预计算
  }

  @override
  void precompute(Range range, {bool reset = false}) {
    // 针对 [range] 范围内的数据进行预计算（仅在数据更新时回调）
  }

  @override
  MinMax? initState(int start, int end) {
    // 返回 [start ~ end) 之间的指标最大最小值
  }

  @override
  void paintChart(Canvas canvas, Size size) {
    // 绘制指标线
  }

  @override
  void onCross(Canvas canvas, Offset offset) {
    // 十字线移动时回调
  }

  @override
  Size? paintTips(
    Canvas canvas, {
    CandleModel? model,
    Offset? offset,
    Rect? tipsRect,
  }) {
    // 绘制顶部 Tips 信息
  }
}
```

## 自定义绘制工具

```dart
class RayLineDrawObject extends DrawObject {
  RayLineDrawObject(super.overlay, super.config);

  @override
  bool hitTest(IDrawContext context, Offset position, {bool isMove = false}) {
    // 判断 [position] 是否命中当前绘制对象
  }

  @override
  void draw(IDrawContext context, Canvas canvas, Size size) {
    // 绘制图形
  }
}
```

## 配置

完整配置参考：[FlexiKline 完整配置.json](./doc/default_flexi_kline_configuration.json)

## License

[Apache License 2.0](./LICENSE)
