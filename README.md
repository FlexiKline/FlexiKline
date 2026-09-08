# FlexiKline [![pub package](https://img.shields.io/pub/v/flexi_kline.svg)](https://pub.dev/packages/flexi_kline)

FlexiKline 是一个 Flutter 金融 K 线图表框架，指标、绘制工具、样式与手势都可以替换或扩展，适用于股票、数字货币等行情展示场景。

## Demo

[在线体验](https://flexikline.github.io) | [Android APK](https://github.com/FlexiKline/FlexiKline.github.io/blob/main/mobile/flexi_kline_app.apk)

## 版本要求

- **Flutter SDK**: >= 3.27.0
- **Dart SDK**: >= 3.6.0

## 特性

- 自定义指标：实现指标配置与绘制对象两个接口就能接入
- 计算与绘制解耦：指标计算在独立的 `IndicatorCalculator` 里，不碰渲染，可以单独测试
- 自定义绘制工具：实现 `DrawObject` 定义自己的画法与命中判定
- 主副区布局：全屏 / 横屏切换，图表宽高可动态调整
- 配置可控：样式、参数、指标、绘制都能定制，整体序列化落盘，`FlexiKlineConfig` 的写入时机由业务侧决定
- 手势操作：惯性平移、缩放锚点、平移平滑均可调；嵌在可滚动容器里也能正常拿到手势
- 多平台：Android、iOS、Web、macOS、Windows、Linux

## 安装

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  flexi_kline: ^2.5.2
```

然后运行：

```bash
flutter pub get
```

## 快速上手

### 1. 实现配置接口

`IConfiguration` 提供主题、`FlexiKlineConfig` 的读写和绘制工具注册。推荐混入 [FlexiKlineConfigurationMixin](https://github.com/FlexiKline/FlexiKline/blob/main/lib/src/config/default_config.dart) 获取默认配置。

```dart
abstract interface class IConfiguration implements IStorage {
  IFlexiKlineTheme get theme;
  FlexiKlineConfig getFlexiKlineConfig();
  void saveFlexiKlineConfig(FlexiKlineConfig config);
  Map<IDrawType, DrawObjectBuilder> get drawObjectBuilders;
}
```

`IIndicatorConfig` 提供蜡烛图、时间轴以及主副区指标。参数变化后保存并调用 `notifyListeners()`，外层的 `ListenableBuilder` 会重建图表：

```dart
class MyIndicatorConfig with ChangeNotifier implements IIndicatorConfig {
  MAIndicator? _ma;
  MAIndicator get ma => _ma ??= getIndicator<MAIndicator>(maIndicatorKey, MAIndicator.fromJson) ?? MAIndicator();

  set ma(MAIndicator value) {
    _ma = value;
    saveIndicator(value);
    notifyListeners();
  }

  // 同样实现 candle、time、mainIndicators、subIndicators。
}
```

同一份缓存配置可供横竖屏或同页多图共享；框架只在 Controller 构造和 `syncFlexiKlineConfig()` 时读取它，落盘由业务侧调用 `storeFlexiKlineConfig()` 决定。

### 2. 创建 FlexiKlineController

```dart
controller = FlexiKlineController(
  configuration: FlexiKlineConfiguration(),
  logger: LoggerImpl(tag: 'FlexiKline', debug: kDebugMode),
  subIndicatorMaxCount: defaultSubIndicatorMaxCount,
  klineDataCacheCapacity: 3,
  calculationInterval: const Duration(milliseconds: 200),
);
```

`calculationInterval` 用于合并高频 `updateLatestKlineData` 的计算任务；不传时默认 `500ms`。

### 3. 使用 FlexiKlineWidget

`candle` / `time` 为必填的基础指标，`mainIndicators` / `subIndicators` 为主区 / 副区叠加的可选指标。可以像组件树一样内联构造各指标并按需定制：

```dart
FlexiKlineWidget(
  controller: controller,
  // 蜡烛图: 倒计时样式 + 主区网格线定制
  candle: CandleIndicator(
    showCountdown: true,
    countdown: const TextAreaConfig(
      style: TextStyle(fontSize: 10, height: 1.2),
      textAlign: TextAlign.center,
      padding: EdgeInsets.all(2),
      borderRadius: BorderRadius.all(Radius.circular(2)),
    ),
    // 主区横向网格线(Y 轴价格刻度线): 4 等分 nice 取整 + 虚线样式
    horizontalGrid: const GridAxisConfig(
      mode: GridTickMode.nice(targetDivisions: 4),
      line: LineConfig(type: LineType.dashed, dashes: [4, 2]),
    ),
  ),
  // 时间轴: 自定义高度、位置与刻度格式(不传 tickFormatter 时按 interval 粒度默认格式化)
  time: TimeIndicator(
    height: 16,
    position: DrawPosition.bottom,
    tickFormatter: (dateTime, interval) {
      return '${dateTime.month}/${dateTime.day}';
    },
  ),
  // 主区叠加: MA 或其他主区指标
  mainIndicators: [
    MAIndicator(
      lineWidth: 1,
      calcParam: [
        MaParam(count: 5, color: Color(0xFFFFB74D), label: 'MA5'),
        MaParam(count: 10, color: Color(0xFF03A9F4), label: 'MA10'),
        MaParam(count: 30, color: Color(0xFF9C27B0), label: 'MA30'),
      ],
    ),
    ...
  ],
  // 副区叠加: MACD 或其他副区指标
  subIndicators: [
    MACDIndicator(
      calcParam: const MACDParam(s: 12, l: 26, m: 9),
      lineWidth: 1,
    ),
    ...
  ],
)
```

也可从一个 `IIndicatorConfig` 解构，并混入配置之外的指标（如业务侧的 External 指标）：

```dart
ListenableBuilder(
  listenable: myIndicatorConfig,
  builder: (context, _) => FlexiKlineWidget(
    controller: controller,
    candle: myIndicatorConfig.candle,
    time: myIndicatorConfig.time,
    mainIndicators: [...myIndicatorConfig.mainIndicators, ...otherIndicators],
    subIndicators: myIndicatorConfig.subIndicators,
  ),
)
```

### 4. 更新数据

```dart
import 'package:flexi_formatter/date_time.dart' show TimeUnit;

final spec = KlineSpec(
  symbol: 'BTC-USDT',
  interval: const FlexiTimeInterval(1, TimeUnit.day),
);

controller.switchKlineData(spec);
controller.replaceKlineData(spec, initialCandles); // 首次加载 / 刷新
controller.updateLatestKlineData(spec, latestCandles); // WebSocket 最新端更新
controller.appendHistoryKlineData(spec, olderCandles); // 更早的历史数据

final index = await controller.moveToDateTime(DateTime(2024, 6, 15));
```

三个更新入口各自声明意图：`replaceKlineData` 整体替换并全量重算，`updateLatestKlineData` 只处理最新端，`appendHistoryKlineData` 只追加历史端。`switchKlineData` 命中缓存时返回 `true`；传入 `spec` 与当前数据不一致的更新会被忽略。

蜡烛合并与指标计算由同一条内部流水线串行编排。后续计划开放外置流水线接口，让业务侧完成清洗、复权、聚合或换算后，再交回框架绘制。

## 配置

图表的全部可配置项都在一份 `FlexiKlineConfig` 里，由 `IConfiguration.getFlexiKlineConfig()` 提供，可整体序列化成 JSON 落盘。

### 配置组成

| 字段 | 类型 | 覆盖范围 |
| ---- | ---- | -------- |
| `setting` | `SettingConfig` | 画布透明度、主副区最小尺寸、蜡烛宽度区间与间距、留白比例、Y 轴刻度、Y 轴缩放跨度倍率、最新价倒计时、自动加载更多、Loading 样式 |
| `grid` | `GridConfig` | 网格边框（横向/纵向边框开关与线型）、指标高度拖拽（开关、命中距离、拖拽线与背景） |
| `cross` | `CrossConfig` | 十字线开关、准星线与交点、刻度文本、Tooltip 样式与间距、空白区行为 |
| `draw` | `DrawConfig` | 绘制功能开关、绘制线与点、准星、刻度文本、命中距离、磁吸距离、放大镜 |
| `gesture` | `GestureConfig` | 长按、惯性平移与容差、缩放开关与锚点、Y 轴缩放倍率上界、键盘快捷键、缩放滑竿、手势抢占阈值（平移方向锥、拖动/缩放 slop 因子） |
| `mainIndicator` | `MainPaintObjectIndicator` | 主区尺寸、padding 与当前已选中的主区指标集合 |
| `sub` | `Set<IIndicatorKey>` | 当前已选中的副区指标集合 |

`LineConfig`、`PointConfig`、`TextAreaConfig`、`TipsConfig`、`MarkConfig`、`PaintConfig`、`GradientConfig`、`TooltipConfig`、`MagnifierConfig`、`LoadingConfig`、`ToleranceConfig` 是被上述配置与各指标复用的样式单元。

所有字段的默认值参考：[FlexiKline 完整配置.json](./doc/default_flexi_kline_configuration.json)

### 主题

颜色不写死在配置对象里，由 `IFlexiKlineTheme` 在绘制时注入，同一份配置就能跟随亮 / 暗色主题切换。主题变化后调用 `controller.onThemeChanged()`，各绘制对象会重建自己的主题派生资源。

### 耐久性与一致性

两个 Controller 方法各管一件事，它们**不是**一对逆操作：

| 入口 | 说明 |
| ---- | ---- |
| `controller.storeFlexiKlineConfig()` | **耐久性**：把当前 `FlexiKlineConfig` 交给 `IConfiguration` 写入存储，只为扛住进程退出 |
| `controller.syncFlexiKlineConfig([config])` | **一致性**：把本 Controller 的运行时追平到当前配置，用于横竖屏 / 同页多图之间同步 |
| `IConfiguration.getFlexiKlineConfig()` | 框架取当前配置，只在 Controller 构造与 `syncFlexiKlineConfig()` 时调用 |
| `IConfiguration.saveFlexiKlineConfig(config)` | 实际写入存储，仅由 `storeFlexiKlineConfig()` 触发 |

`syncFlexiKlineConfig()` 取的是 `getFlexiKlineConfig()` 返回的配置而非存储快照——返回共享实例时全程不碰存储，返回新实例时对侧须先落盘本侧才读得到。它不发通知（与 `showMainIndicator()` 一致），调用方需自行刷新依赖激活集合的状态。

> [!warning]
> 框架不会自动决定 `FlexiKlineConfig` 的落盘时机：`dispose()` 与 `onThemeChanged()` 都不会写入，需业务侧在页面销毁前或用户显式保存时调用 `storeFlexiKlineConfig()`。多个 Controller 共享一份配置时，应只由配置拥有者一侧落盘。

绘制 overlay 不在以上任何一环，它由框架自动落盘，见「绘制工具」一节。

## 指标系统

### 提供指标

`IIndicatorConfig` 的四个 getter 分别向 `FlexiKlineWidget` 提供基础指标与可选指标；它与 `IConfiguration` 平行，并继承 `IStorage` 保存指标参数。

| Getter | 用途 |
| ------ | ---- |
| `candle` | 蜡烛图指标 |
| `time` | 时间轴指标 |
| `mainIndicators` | 主区可选指标，如：MA、EMA、BOLL、SAR |
| `subIndicators` | 副区可选指标，如：MACD、KDJ、RSI、DMI |

### 指标分类

框架通过 `IIndicatorKey` sealed class 区分三类指标，各自有对应的 Indicator 与 PaintObject 基类：

| 指标类型 | Key 类型 | Indicator 基类 | PaintObject 基类 | 说明 |
| -------- | -------- | -------------- | ---------------- | ---- |
| 直接绘制 | `DirectIndicatorKey` | `DirectIndicator` | `DirectPaintObject` | 直接基于当前 K 线数据与绘制上下文作画，不占计算槽位 |
| 计算型 | `ComputedIndicatorKey` | `ComputedIndicator` | `ComputedPaintObject` | 需提前计算，结果写入 `FlexiCandleModel.slots` |
| 外部数据 | `ExternalIndicatorKey` | `ExternalIndicator` | `ExternalPaintObject` | 由业务数据或用户操作驱动 |

指标声明（`Indicator`）负责可序列化配置；运行时绘制对象（`PaintObject`）在指标激活时由 `createPaintObject()` 创建。

### 生命周期

三类 PaintObject 共享同一套生命周期回调：

| 回调 | 触发时机 |
| ---- | -------- |
| `initState` | mount 后一次；此时绘制布局尚未绑定，勿依赖 `drawableRect` / `minMax` |
| `didChangeDependencies` | `spec.key`（symbol / interval）变化 |
| `didUpdateIndicator` | 指标配置变化 |
| `didChangeTheme` | 主题变化（仅 attached 对象） |
| `didAttach` / `didDetach` | 进入 / 离开绘制树，几何首次有效 |
| `dispose` | 实例销毁 |

Direct 与 Computed 的 `autoActivate` 默认 `false`；show 时创建、hide 时销毁，`keepAlive` 为真则保活复用。External 的 `autoActivate` 与 `keepAlive` 默认都是 `true`，声明即激活，移除声明才销毁。

### 绘制入口

| 方法 | 说明 |
| ---- | ---- |
| `paintGridLines(canvas, size)` | 绘制本 pane 的网格线（先竖后横），返回解析出的位置 `({List<double> dxs, List<double> dys})` |
| `computeVisibleMinMax(start, end)` | 返回 `[start, end)` 区间的最大最小值，参与 Y 轴换算 |
| `paint(canvas, size)` | 主体绘制 |
| `paintOverlay(canvas, size)` | 主图完成后的叠加绘制，如最新价标记 |
| `paintCross(canvas, offset, {model})` | Cross 状态下的附加绘制 |
| `paintTips(canvas, {model, offset, tipsRect})` | 绘制顶部 Tips 信息条并返回占用尺寸 |

### 交互入口

默认全部为空操作，按需覆写。点击与拖动按 `zIndex` 倒序询问，视觉最上层的对象优先作答。

| 方法 | 说明 |
| ---- | ---- |
| `handleTap(position)` | 返回 `true` 消费点击，框架停止询问后续对象 |
| `hitTestDragStart(position)` | 判断位置是否可拖动，必须无副作用；嵌入可滚动容器时必须实现 |
| `handleDragStart(position)` | 返回 `true` 认领拖动，后续回调只发给本对象 |
| `handleDragUpdate(position, delta)` | 拖动中 |
| `handleDragEnd()` | 正常结束并提交结果 |
| `handleDragCancel()` | 手势被打断，回滚未提交状态 |

`position` 已按大区分派：主区指标只收到 `mainRect` 内的位置，副区指标只收到 `subRect` 内的位置。认领拖动后，框架抑制图表平移、惯性平移、`loadMore` 与 Cross 更新；目标中途消失时调用 `context.requestReleasePaintObject(this)` 释放持有。

### Direct 指标

最基础的形态，直接读取当前 K 线数据与绘制上下文。`createPaintObject()` 连接声明与运行时对象；`computeVisibleMinMax` 与 `paint` 是最常见的绘制入口。内置蜡烛图与时间轴都是这一类。

```dart
class VolumeIndicator extends DirectIndicator {
  @override
  DirectPaintObject<VolumeIndicator> createPaintObject() => VolumePaintObject();
}

class VolumePaintObject extends DirectPaintObject<VolumeIndicator> {
  @override
  MinMax? computeVisibleMinMax(int start, int end) {
    // 遍历当前可见 K 线，返回成交量的最大最小值。
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制成交量柱。
  }
}
```

### Computed 指标

Computed 比 Direct 多一层预计算：`createCalculator(dataIndex)` 创建 `IndicatorCalculator` 写入槽位，`ComputedPaintObject` 通过 `dataIndex` 读取结果再绘制。计算器不依赖 Flutter、Canvas 或 PaintObject，可单独测试。

| 成员 | 说明 |
| ---- | ---- |
| `calcParam` | 计算参数，用于判断配置变化后是否需要重算 |
| `shouldRecompute(old)` | 参数变化时是否整段重算，默认比较 `calcParam` |
| `compute(data, range, {reset})` | 计算 `range` 并写入 `slots[dataIndex]`；`reset` 为真时先清空槽位 |

下面省略构造参数、序列化和具体算法，但保留计算器与 PaintObject 的接线关系：

```dart
class MAIndicator extends ComputedIndicator {
  @override
  final List<MaParam> calcParam;

  @override
  ComputedPaintObject<MAIndicator> createPaintObject() => MAPaintObject();

  @override
  IndicatorCalculator<MAIndicator> createCalculator(int dataIndex) => MACalculator(this, dataIndex);

  @override
  bool shouldRecompute(covariant MAIndicator old) => old.calcParam != calcParam;
}

class MACalculator extends IndicatorCalculator<MAIndicator> {
  MACalculator(super.indicator, super.dataIndex);

  @override
  void compute(KlineData data, Range range, {bool reset = false}) {
    // 用 indicator.calcParam 计算 range，并写入 slots[dataIndex]。
  }
}

class MAPaintObject extends ComputedPaintObject<MAIndicator> {
  @override
  MinMax? computeVisibleMinMax(int start, int end) {
    // 从 slots[dataIndex] 聚合当前可见指标值。
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 从 slots[dataIndex] 读取结果并绘制指标线。
  }
}
```

### External 指标

External 由业务数据或用户操作驱动，不占计算槽位。`initState` 默认调用 `loadBusinessData()`；挂单线、成交标记等业务图形通常只需覆写这一处，并在数据完成后调用 `setState()`。

```dart
class TradeIndicator extends ExternalIndicator {
  @override
  ExternalPaintObject<TradeIndicator> createPaintObject() => TradePaintObject();
}

class TradePaintObject extends ExternalPaintObject<TradeIndicator> {
  @override
  void loadBusinessData() {
    // 拉取挂单 / 成交数据，完成后调用 setState()。
  }

  @override
  void didChangeDependencies(KlineSpec oldSpec) {
    loadBusinessData();
    setState();
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制挂单线或成交标记。
  }
}
```

## 绘制工具

绘制工具（趋势线、射线、斐波那契等）通过 `IDrawType` 与 `DrawObject` 扩展，在 `IConfiguration.drawObjectBuilders` 中注册，也可运行期 `controller.registerDrawObjectBuilder(type, builder)` 追加。

内置绘制工具集由 [flexi_kline_draw_tools](https://pub.dev/packages/flexi_kline_draw_tools) 提供。

```dart
class RayLineDrawObject extends DrawObject {
  RayLineDrawObject(super.overlay, super.config);

  @override
  bool hitTest(DrawContext context, Offset position, {bool isMove = false}) {
    // 判断 [position] 是否命中当前绘制对象
  }

  @override
  void draw(DrawContext context, Canvas canvas, Size size) {
    // 绘制已完成的图形
  }
}
```

### 可覆写的钩子

| 钩子 | 时机 | 说明 |
| ---- | ---- | ---- |
| `draw(context, canvas, size)` | 绘制完成 | 必须实现 |
| `drawing(context, canvas, size)` | 绘制中 | 默认画连接虚线与绘制点；需要提前预览成品形态时覆写 |
| `hitTest(context, position, {isMove})` | 命中测试 | 默认按点到线段距离判定；矩形、通道一类要覆写 |
| `onUpdateDrawPoint(point, offset)` | 每次点位变化 | 校正落点，如把两点吸附到同一价位 |

> [!warning]
> `onUpdateDrawPoint` 是**拖动单个点**与**整体平移**的唯一入口。做点间联动修正时要按 `point.index` 区分这两种情形，否则容易写出「基准点对齐自己」——该坐标恒等于旧值，图形在那个方向上锁死。

### 持久化

绘制实例按 symbol 存在独立存储键下，**由框架自动落盘**：绘制完成、点位确认、移动结束、改样式、锁定、改层级都会立即写入，业务侧无需调用 `storeFlexiKlineConfig()`。跨 Controller 同步由 `syncFlexiKlineConfig()` 顺带完成。

## License

[Apache License 2.0](./LICENSE)
