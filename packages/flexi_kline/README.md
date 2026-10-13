# FlexiKline [![pub package](https://img.shields.io/pub/v/flexi_kline.svg)](https://pub.dev/packages/flexi_kline)

English | [简体中文](https://github.com/FlexiKline/FlexiKline/blob/main/packages/flexi_kline/README_zh.md)

FlexiKline is a Flutter candlestick (K-line) chart framework for stock and crypto markets. Indicators, drawing tools, styles and gestures can all be replaced or extended.

## Demo

[Try it online](https://flexikline.github.io)

## Requirements

- **Flutter SDK**: >= 3.41.0
- **Dart SDK**: >= 3.11.0

## Features

- Custom indicators: implement an indicator config and a paint object to plug one in.
- Calculation decoupled from rendering: indicator math lives in an `IndicatorCalculator`, testable on its own.
- Custom drawing tools: implement `DrawObject` to define the shape and its hit test.
- Main/sub pane layout: fullscreen and landscape switching, chart size adjustable at runtime.
- Controllable configuration: styles, params, indicators and drawings are all customizable and serialize as a whole; when `FlexiKlineConfig` is persisted is up to your app.
- Gestures: tunable fling, zoom anchor and pan smoothing; works inside scrollable containers.
- Platforms: Android, iOS, Web, macOS, Windows, Linux.

## Installation

Add the dependency to `pubspec.yaml`:

```yaml
dependencies:
  flexi_kline: ^2.6.0
```

Then run:

```bash
flutter pub get
```

## Quick start

A runnable minimal app is in [example/main.dart](example/main.dart).

### 1. Implement the configuration

`IConfiguration` provides the theme, reads and writes `FlexiKlineConfig`, and registers drawing tools. Mix in [FlexiKlineConfigurationMixin](https://github.com/FlexiKline/FlexiKline/blob/main/packages/flexi_kline/lib/src/config/default_config.dart) for the defaults.

```dart
abstract interface class IConfiguration implements IStorage {
  IFlexiKlineTheme get theme;
  FlexiKlineConfig getFlexiKlineConfig();
  void saveFlexiKlineConfig(FlexiKlineConfig config);
  Map<IDrawType, DrawObjectBuilder> get drawObjectBuilders;
}
```

`IIndicatorConfig` provides the candle, time axis and main/sub indicators. Save and call `notifyListeners()` after a param changes; an outer `ListenableBuilder` rebuilds the chart:

```dart
class MyIndicatorConfig with ChangeNotifier implements IIndicatorConfig {
  MAIndicator? _ma;
  MAIndicator get ma => _ma ??= getIndicator<MAIndicator>(maIndicatorKey, MAIndicator.fromJson) ?? MAIndicator();

  set ma(MAIndicator value) {
    _ma = value;
    saveIndicator(value);
    notifyListeners();
  }

  // Implement candle, time, mainIndicators and subIndicators the same way.
}
```

One cached configuration can be shared by portrait/landscape or several charts on a page. The framework reads it only when a Controller is constructed and on `syncFlexiKlineConfig()`; persisting is up to your call to `storeFlexiKlineConfig()`.

### 2. Create a FlexiKlineController

```dart
controller = FlexiKlineController(
  configuration: FlexiKlineConfiguration(),
  logger: LoggerImpl(tag: 'FlexiKline', debug: kDebugMode),
  subIndicatorMaxCount: defaultSubIndicatorMaxCount,
  klineDataCacheCapacity: 3,
  calculationInterval: const Duration(milliseconds: 200),
);
```

`calculationInterval` coalesces calculations from frequent `updateLatestKlineData` calls; defaults to `500ms`.

### 3. Use FlexiKlineWidget

`candle` / `time` are required base indicators; `mainIndicators` / `subIndicators` are optional overlays on the main / sub panes. Build and customize them inline like a widget tree:

```dart
FlexiKlineWidget(
  controller: controller,
  // Candle: countdown style + main pane grid lines
  candle: CandleIndicator(
    showCountdown: true,
    countdown: const TextAreaConfig(
      style: TextStyle(fontSize: 10, height: 1.2),
      textAlign: TextAlign.center,
      padding: EdgeInsets.all(2),
      borderRadius: BorderRadius.all(Radius.circular(2)),
    ),
    // Horizontal grid (Y-axis price ticks): 4 nice divisions, dashed
    horizontalGrid: const GridAxisConfig(
      mode: GridTickMode.nice(targetDivisions: 4),
      line: LineConfig(type: LineType.dashed, dashes: [4, 2]),
    ),
  ),
  // Time axis: height, position and tick format (defaults to the interval's granularity)
  time: TimeIndicator(
    height: 16,
    position: DrawPosition.bottom,
    tickFormatter: (dateTime, interval) {
      return '${dateTime.month}/${dateTime.day}';
    },
  ),
  // Main pane: MA or other main indicators
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
  // Sub panes: MACD or other sub indicators
  subIndicators: [
    MACDIndicator(
      calcParam: const MACDParam(s: 12, l: 26, m: 9),
      lineWidth: 1,
    ),
    ...
  ],
)
```

Or take them from an `IIndicatorConfig` and mix in indicators outside it (e.g. your External indicators):

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

### 4. Update data

```dart
import 'package:flexi_formatter/date_time.dart' show TimeUnit;

final spec = KlineSpec(
  symbol: 'BTC-USDT',
  interval: const FlexiTimeInterval(1, TimeUnit.day),
);

controller.switchKlineData(spec);
controller.replaceKlineData(spec, initialCandles); // first load / refresh
controller.updateLatestKlineData(spec, latestCandles); // WebSocket updates at the latest end
controller.appendHistoryKlineData(spec, olderCandles); // older history

final index = await controller.moveToDateTime(DateTime(2024, 6, 15));
```

Each update entry states its intent: `replaceKlineData` replaces everything and recomputes, `updateLatestKlineData` handles only the latest end, `appendHistoryKlineData` only appends history. `switchKlineData` returns `true` on a cache hit; updates whose `spec` doesn't match the current data are ignored.

After `moveToDateTime` succeeds, the candle indicator shows a date bubble above the target candle by default. It follows pan and zoom and disappears after `holdDuration` (default 2000ms, `0` keeps it). Configure visibility, position (`DateMarkPosition.auto` / `above` / `below`) and look via `CandleIndicator.dateMark` (`DateMarkConfig`); set `show: false` to draw your own. Override `CandlePaintObject.buildDateMarkSpan` to change only the text, or `paintDateMark` to change the drawing.

Candle merging and indicator calculation run serially in one internal pipeline. An external pipeline API is planned so apps can clean, adjust, aggregate or convert data before handing it back for rendering.

## Configuration

Everything configurable lives in one `FlexiKlineConfig`, provided by `IConfiguration.getFlexiKlineConfig()` and serializable to JSON as a whole.

### Structure

| Field | Type | Covers |
| ----- | ---- | ------ |
| `setting` | `SettingConfig` | Canvas opacity, min pane sizes, candle width range and spacing, blank ratio, Y-axis ticks, Y-axis zoom span, latest-price countdown, auto load-more |
| `grid` | `GridConfig` | Grid border (horizontal/vertical switches and line style), indicator height dragging (switch, hit distance, drag line and background) |
| `cross` | `CrossConfig` | Crosshair switch, lines and crosspoint, tick text, tooltip style and spacing, behavior over blank area |
| `draw` | `DrawConfig` | Drawing switch, lines and points, crosspoint, tick text, hit distance, magnet distance |
| `gesture` | `GestureConfig` | Long press, fling and tolerance, zoom switch and anchor, Y-axis zoom upper bound, keyboard shortcuts, zoom slider, gesture arena thresholds (pan cone, drag/zoom slop factors) |
| `mainIndicator` | `MainPaintObjectIndicator` | Main pane size, padding and the selected main indicators |
| `sub` | `Set<IIndicatorKey>` | Selected sub indicators |

`LineConfig`, `PointConfig`, `TextAreaConfig`, `TipsConfig`, `MarkConfig`, `PaintConfig`, `GradientConfig`, `TooltipConfig` and `ToleranceConfig` are style units shared by the configs above and by indicators.

Default values of every field: [default configuration JSON](./doc/default_flexi_kline_configuration.json)

### Theme

Colors are not stored in config objects; `IFlexiKlineTheme` injects them at paint time, so one config follows light/dark themes. Call `controller.onThemeChanged()` after the theme changes and paint objects rebuild their theme-derived resources.

### Durability and consistency

The two Controller methods do different jobs and are **not** inverses:

| Entry | Purpose |
| ----- | ------- |
| `controller.storeFlexiKlineConfig()` | **Durability**: hands the current `FlexiKlineConfig` to `IConfiguration` for storage, only to survive process exit |
| `controller.syncFlexiKlineConfig([config])` | **Consistency**: brings this Controller's runtime up to the current config, for syncing portrait/landscape or several charts |
| `IConfiguration.getFlexiKlineConfig()` | The framework reads the current config, only on Controller construction and `syncFlexiKlineConfig()` |
| `IConfiguration.saveFlexiKlineConfig(config)` | Writes to storage, triggered only by `storeFlexiKlineConfig()` |

`syncFlexiKlineConfig()` uses what `getFlexiKlineConfig()` returns, not a storage snapshot: returning a shared instance never touches storage, while returning a new instance requires the other side to persist first. It sends no notification (like `showMainIndicator()`); refresh any state that depends on the active set yourself.

> [!warning]
> The framework never decides when to persist `FlexiKlineConfig`: neither `dispose()` nor `onThemeChanged()` writes it. Call `storeFlexiKlineConfig()` before the page is destroyed or when the user saves. When several Controllers share one config, only its owner should persist.

Drawing overlays are outside all of this; the framework persists them automatically, see [Drawing tools](#drawing-tools).

## Indicators

### Providing indicators

The four getters of `IIndicatorConfig` feed base and optional indicators to `FlexiKlineWidget`. It parallels `IConfiguration` and extends `IStorage` to store indicator params.

| Getter | Purpose |
| ------ | ------- |
| `candle` | Candle indicator |
| `time` | Time axis indicator |
| `mainIndicators` | Optional main indicators, e.g. MA, EMA, BOLL, SAR |
| `subIndicators` | Optional sub indicators, e.g. MACD, KDJ, RSI, DMI |

### Kinds

The sealed `IIndicatorKey` distinguishes three kinds, each with its own Indicator and PaintObject base class:

| Kind | Key type | Indicator base | PaintObject base | Notes |
| ---- | -------- | -------------- | ---------------- | ----- |
| Direct | `DirectIndicatorKey` | `DirectIndicator` | `DirectPaintObject` | Paints straight from current candles and the paint context; uses no compute slot |
| Computed | `ComputedIndicatorKey` | `ComputedIndicator` | `ComputedPaintObject` | Precomputed; results are written to `FlexiCandleModel.slots` |
| External | `ExternalIndicatorKey` | `ExternalIndicator` | `ExternalPaintObject` | Driven by business data or user actions |

The `Indicator` declaration holds the serializable config; the runtime `PaintObject` is created by `createPaintObject()` when the indicator activates.

### Lifecycle

All three PaintObject kinds share the same callbacks:

| Callback | When |
| -------- | ---- |
| `initState` | Once after mount; layout is not bound yet, don't rely on `drawableRect` / `minMax` |
| `didChangeDependencies` | `spec.key` (symbol / interval) changed |
| `didUpdateIndicator` | Indicator config changed |
| `didChangeTheme` | Theme changed (attached objects only) |
| `didAttach` / `didDetach` | Entering / leaving the paint tree; geometry becomes valid on first attach |
| `dispose` | Instance destroyed |

Direct and Computed default to `autoActivate: false`: created on show, destroyed on hide, reused when `keepAlive` is true. External defaults both `autoActivate` and `keepAlive` to `true`: active once declared, destroyed when the declaration is removed.

### Paint entry points

| Method | Purpose |
| ------ | ------- |
| `paintGridLines(canvas, size)` | Grid lines of this pane (vertical first), returns the resolved positions `({List<double> dxs, List<double> dys})` |
| `computeVisibleMinMax(start, end)` | Max/min over `[start, end)`, used for Y-axis mapping |
| `paint(canvas, size)` | Main painting |
| `paintOverlay(canvas, size)` | Overlay after the main chart, e.g. latest-price marks |
| `paintCross(canvas, offset, {model})` | Extra painting while the crosshair is shown |
| `paintTips(canvas, {model, offset, tipsRect})` | Top tips bar; returns its size |

### Painting building blocks

Register paint resources reused across frames with `own()`: they reset when the PaintObject's declaration updates and dispose with it. Use `LabelPainter` for text labels: pass the key and `build` every frame; nothing is formatted or laid out while content and style are unchanged. Batch points or segments sharing a paint in a `PointBuffer` and draw them at once. The old text extensions in `extension/render/` still work alongside.

```dart
class VolumePaintObject extends DirectPaintObject<VolumeIndicator> {
  late final _label = own(LabelPainter());
  late final _bars = own(PointBuffer());

  @override
  void paint(Canvas canvas, Size size) {
    // Bars: vertical segments as wide as a bar, drawn in one drawRawPoints call.
    for (final (dx, top, bottom) in visibleBars) {
      _bars.addSegment(dx, top, dx, bottom);
    }
    _bars.flush(canvas, PointMode.lines, barPaint);

    // Label: the key must fully determine the text; build is skipped on a hit.
    final value = latestVolume;
    _label.paint(
      canvas,
      value,
      build: () => formatNumber(value),
      style: indicator.text.toLabelStyle(textColor: theme.textColor),
      anchor: chartRect.topRight,
      align: Alignment.topRight,
      bounds: drawableRect,
    );
  }
}
```

Use `ShapeImage` for small icons next to text (e.g. the last-price arrow): subclasses only implement `draw`; the base class caches bitmaps per color and releases them, and `span(color)` puts the icon into a label. Built-ins: `TriangleImage`, `ChevronImage`, `DiamondImage`, `SquareImage`, `CircleImage`, `PlusImage`, `MinusImage`, `CrossImage`, `StarImage`, `BellImage`. Subclass for other shapes (subclasses must be `final` or `base`) and reuse `roundedPolygon` (rounded convex polygon) and `strokePaint` (round-cap stroke). Shapes that size to content or must point at an anchor (bubbles, order-mark tails) use a `ShapeBorder` (e.g. `BubbleBorder`), not an image.

```dart
final class HexagonImage extends ShapeImage {
  HexagonImage(super.size);

  @override
  void draw(Canvas canvas, Size size, Color color) {
    final (w, h) = (size.width, size.height);
    // Vertices must be clockwise.
    final vertices = [
      Offset(w / 4, 0),
      Offset(w * 3 / 4, 0),
      Offset(w, h / 2),
      Offset(w * 3 / 4, h),
      Offset(w / 4, h),
      Offset(0, h / 2),
    ];
    canvas.drawPath(roundedPolygon(vertices, 0.5), Paint()..color = color);
  }
}

// Replace the last-price arrow: override CandlePaintObject.createOffViewPriceArrow.
@override
ShapeImage createOffViewPriceArrow() => ChevronImage(const Size(5, 6));
```

### Interaction entry points

All are no-ops by default; override as needed. Taps and drags are offered in descending `zIndex`, so the visually topmost object answers first.

| Method | Purpose |
| ------ | ------- |
| `handleTap(position)` | Return `true` to consume the tap; no later object is asked |
| `hitTestDragStart(position)` | Whether the position is draggable; must be side-effect free; required inside scrollable containers |
| `handleDragStart(position)` | Return `true` to claim the drag; later callbacks go only to this object |
| `handleDragUpdate(position, delta)` | During the drag |
| `handleDragEnd()` | Finished normally; commit the result |
| `handleDragCancel()` | Gesture interrupted; roll back uncommitted state |

`position` is dispatched per pane: main indicators only receive positions inside `mainRect`, sub indicators only inside `subRect`. While a drag is claimed the framework suppresses chart pan, fling, `loadMore` and crosshair updates; if the target disappears mid-drag, call `context.requestReleasePaintObject(this)` to release it.

### Direct indicators

The simplest form, reading current candles and the paint context directly. `createPaintObject()` links the declaration to its runtime object; `computeVisibleMinMax` and `paint` are the usual entry points. The built-in candle and time axis are Direct indicators.

```dart
class VolumeIndicator extends DirectIndicator {
  @override
  DirectPaintObject<VolumeIndicator> createPaintObject() => VolumePaintObject();
}

class VolumePaintObject extends DirectPaintObject<VolumeIndicator> {
  @override
  MinMax? computeVisibleMinMax(int start, int end) {
    // Walk the visible candles and return the volume max/min.
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Draw volume bars.
  }
}
```

### Computed indicators

Computed adds a precompute step to Direct: `createCalculator(dataIndex)` creates an `IndicatorCalculator` that writes into a slot, and `ComputedPaintObject` reads the result via `dataIndex`. Calculators don't depend on Flutter, Canvas or PaintObject, so they test on their own.

| Member | Purpose |
| ------ | ------- |
| `calcParam` | Calculation params; decides whether a config change needs recomputing |
| `shouldRecompute(old)` | Whether to recompute everything on a param change; compares `calcParam` by default |
| `compute(data, range, {reset})` | Computes `range` into `slots[dataIndex]`; clears the slot first when `reset` is true |

Constructor params, serialization and the algorithm are omitted below; the wiring between calculator and PaintObject is kept:

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
    // Compute range with indicator.calcParam and write into slots[dataIndex].
  }
}

class MAPaintObject extends ComputedPaintObject<MAIndicator> {
  @override
  MinMax? computeVisibleMinMax(int start, int end) {
    // Aggregate visible values from slots[dataIndex].
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Read slots[dataIndex] and draw the lines.
  }
}
```

### External indicators

External indicators are driven by business data or user actions and use no compute slot. `initState` calls `loadBusinessData()` by default; order lines, trade marks and similar shapes usually only override that and call `setState()` when data arrives.

```dart
class TradeIndicator extends ExternalIndicator {
  @override
  ExternalPaintObject<TradeIndicator> createPaintObject() => TradePaintObject();
}

class TradePaintObject extends ExternalPaintObject<TradeIndicator> {
  @override
  void loadBusinessData() {
    // Fetch orders / trades, then call setState().
  }

  @override
  void didChangeDependencies(KlineSpec oldSpec) {
    loadBusinessData();
    setState();
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Draw order lines or trade marks.
  }
}
```

## Drawing tools

Drawing tools (trend line, ray, Fibonacci, ...) extend `IDrawType` and `DrawObject` and are registered in `IConfiguration.drawObjectBuilders`, or at runtime via `controller.registerDrawObjectBuilder(type, builder)`.

The built-in tool set is provided by [flexi_kline_draw_tools](https://pub.dev/packages/flexi_kline_draw_tools).

```dart
class RayLineDrawObject extends DrawObject {
  RayLineDrawObject(super.overlay, super.config);

  @override
  bool hitTest(DrawContext context, Offset position, {bool isMove = false}) {
    // Whether [position] hits this object.
  }

  @override
  void draw(DrawContext context, Canvas canvas, Size size) {
    // Draw the finished shape.
  }
}
```

### Overridable hooks

| Hook | When | Notes |
| ---- | ---- | ----- |
| `draw(context, canvas, size)` | Finished | Required |
| `drawing(context, canvas, size)` | In progress | Draws connecting dashes and points by default; override to preview the final shape |
| `hitTest(context, position, {isMove})` | Hit test | Point-to-segment distance by default; override for rectangles, channels and the like |
| `onUpdateDrawPoint(point, offset)` | Every point change | Correct the point, e.g. snap two points to the same price |

> [!warning]
> `onUpdateDrawPoint` is the only entry for both **dragging one point** and **moving the whole shape**. Distinguish the two by `point.index` when linking points, or you may "align the anchor to itself": the coordinate always equals its old value and the shape locks in that direction.

### Persistence

Drawings are stored per symbol under their own storage key and **persisted by the framework**: finishing, confirming a point, ending a move, changing style, locking and reordering all write immediately; no `storeFlexiKlineConfig()` call is needed. `syncFlexiKlineConfig()` also syncs them across Controllers.

## License

[Apache License 2.0](./LICENSE)
