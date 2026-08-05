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
  flexi_kline: ^2.3.2
```

然后运行：

```bash
flutter pub get
```

## 快速上手

### 1. 实现 IConfiguration 接口

自定义配置类，实现主题和全局配置。推荐混入 [FlexiKlineConfigurationMixin](https://github.com/FlexiKline/FlexiKline/blob/main/lib/src/config/default_config.dart) 获取默认配置。

```dart
abstract interface class IConfiguration implements IStorage {
  /// 当前配置主题
  IFlexiKlineTheme get theme;

  /// 生成FlexiKline配置
  FlexiKlineConfig generateFlexiKlineConfig([FlexiKlineConfig? origin]);

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
FlexiKlineWidget.indicator(
  controller: controller,
  indicatorConfig: indicatorConfig,
  mainBackgroundView: FlexiKlineMarkView(),
  mainForegroundViewBuilder: _buildKlineMainForgroundView,
  onDoubleTap: setFullScreen,
  drawToolbar: FlexiKlineDrawToolbar(controller: controller),
)
```

也可直接传入指标实例：

```dart
FlexiKlineWidget(
  controller: controller,
  candle: CandleIndicator(),
  time: TimeIndicator(),
  mainIndicators: [maIndicator, bollIndicator],
  subIndicators: [macdIndicator, kdjIndicator],
)
```

### 4. 更新数据

```dart
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_formatter/date_time.dart' show TimeUnit;

/// 定义 K 线规格（symbol、周期等）
final spec = KlineSpec(
  symbol: 'BTC-USDT',
  interval: const FlexiTimeInterval(1, TimeUnit.day),
);

/// 切换数据源（如切换交易对或周期）
controller.switchKlineData(spec);

/// 更新指定规格的数据
controller.updateKlineData(spec, list);

/// 跳转到指定日期（动画滚动到最近一根已加载蜡烛）。
/// Future 在动画完成后返回实际命中的蜡烛下标；无法完成时返回 null。
final index = await controller.moveToDateTime(DateTime(2024, 6, 15));
```

## 自定义指标

v2.2.0 引入了类型化的指标体系，通过 `IIndicatorKey` sealed class 区分三类指标：

| 指标类型     | Key 类型               | Indicator 基类      | PaintObject 基类      | 说明                                                            |
| ------------ | ---------------------- | ------------------- | --------------------- | --------------------------------------------------------------- |
| 直接绘制指标 | `DirectIndicatorKey`   | `DirectIndicator`   | `DirectPaintObject`   | 直接基于当前 K 线数据和绘制上下文绘制，不占 computed data index |
| 计算型指标   | `ComputedIndicatorKey` | `ComputedIndicator` | `ComputedPaintObject` | 需要提前计算，并将结果写入 `FlexiCandleModel.slots`             |
| 外部数据指标 | `ExternalIndicatorKey` | `ExternalIndicator` | `ExternalPaintObject` | 由外部数据或用户操作驱动，默认 `autoActivate: true`             |

### PaintObject 生命周期

三类指标共享同一套生命周期回调（参照 Flutter `State`）：

| 回调 | 触发时机 |
| ---- | -------- |
| `initState` | mount 后一次（此时绘制布局尚未绑定，勿依赖 `drawableRect` / `minMax`） |
| `didChangeDependencies` | `spec.key`（symbol / interval）变化 |
| `didUpdateIndicator` | 指标配置变化 |
| `didChangeTheme` | 主题变化（仅 attached 对象） |
| `didAttach` / `didDetach` | 进入 / 离开绘制树（几何首次有效） |
| `dispose` | 实例销毁 |

- **Direct / Computed**：`autoActivate` 默认 `false`；show 时创建、hide 时销毁（`keepAlive` 可保活复用）。
- **External**：`autoActivate` 默认 `true`，首次激活时创建；`initState` 默认调用 `loadBusinessData()` 加载业务数据。
- 继承 `ComputedPaintObject` 时，覆写 `didUpdateIndicator` 需调用 `super` 以触发重算。

### 示例：自定义数据指标

```dart
/// 指标 Key
const maIndicatorKey = ComputedIndicatorKey('MA', label: 'MA');

/// 指标配置
class MAIndicator extends ComputedIndicator {
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
  ComputedPaintObject<MAIndicator> createPaintObject() => MAPaintObject();

  @override
  Map<String, dynamic> toJson() {
    return {"calcParam": calcParam.map((e) => e.toJson()).toList()};
  }
}

/// 指标绘制对象
class MAPaintObject extends ComputedPaintObject<MAIndicator> {

  @override
  bool shouldRecompute(MAIndicator oldIndicator) {
    // 判断新旧指标配置的变化是否需要重新计算
  }

  @override
  void didUpdateIndicator(MAIndicator oldIndicator) {
    super.didUpdateIndicator(oldIndicator); // 必须调用 super 以触发重算
  }

  @override
  void compute(Range range, {bool reset = false}) {
    // 针对 [range] 范围内的数据进行计算（仅在数据更新时回调）
  }

  @override
  MinMax? computeVisibleMinMax(int start, int end) {
    // 返回 [start ~ end) 之间的指标最大最小值
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制指标线
  }

  @override
  void paintOverlay(Canvas canvas, Size size) {
    // 主图绘制完成后叠加绘制（如最新价标记等），与 Cross 图层无关
  }

  @override
  void paintCross(Canvas canvas, Offset offset, {FlexiCandleModel? model}) {
    // Cross 状态下绘制指标附加内容
  }

  @override
  Size? paintTips(
    Canvas canvas, {
    FlexiCandleModel? model,
    Offset? offset,
    Rect? tipsRect,
  }) {
    // 绘制顶部 Tips 信息条
  }
}
```

### 示例：自定义外部数据指标

```dart
class TradePaintObject extends ExternalPaintObject<TradeIndicator> {
  @override
  void loadBusinessData() {
    // initState 默认调用；也可 override initState / didChangeDependencies 等
  }

  @override
  void didChangeDependencies(KlineSpec oldSpec) {
    // symbol / interval 变化时重新加载
    loadBusinessData();
    setState();
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制业务 overlay
  }
}
```

## 自定义绘制工具

```dart
class RayLineDrawObject extends DrawObject {
  RayLineDrawObject(super.overlay, super.config);

  @override
  bool hitTest(DrawContext context, Offset position, {bool isMove = false}) {
    // 判断 [position] 是否命中当前绘制对象
  }

  @override
  void draw(DrawContext context, Canvas canvas, Size size) {
    // 绘制图形
  }
}
```

## 配置

完整配置参考：[FlexiKline 完整配置.json](./doc/default_flexi_kline_configuration.json)

## License

[Apache License 2.0](./LICENSE)
