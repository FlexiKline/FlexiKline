## 2.4.0
* Separate candle merging from indicator calculation: add `KlineDataPipeline` with `idle`/`merging`/`computing` phases and a fixed calculation tick (`FlexiKlineController.calculationInterval`, default 500ms), so the two never modify one `KlineData` concurrently (Breaking Changes).
* Replace `updateKlineData(spec, list, reset:)` with three intent-specific APIs: `replaceKlineData`, `updateLatestKlineData`, `appendHistoryKlineData`; the pipeline no longer infers direction from timestamps (Breaking Changes).
* Move indicator calculation out of PaintObject into `IndicatorCalculator`: add `ComputedIndicator.createCalculator(dataIndex)` and `calcParam`; remove `compute` and `shouldRecompute` from the paint layer (Breaking Changes).
* Bind one `KlineDataPipeline` to one current `KlineData`; switching spec destroys the old pipeline and its pending queue, and data APIs no longer take a `data` argument (Breaking Changes).
* Remove `KlineData.enqueueWaitingData`, `hasWaitingData` and `waitingDataLength`; pre-mount input is now held by the pipeline, not by `KlineData` (Breaking Changes).
* Add `evictInactiveKlineDataCache()` and drop non-current cached `KlineData` when computed slot layout or indicator params change, so cached snapshots cannot carry stale indicator values.
* Fix accumulated dirty range not translating when `updateLatestKlineData` inserts a new head candle, which silently skipped recompute for incremental indicators (MA/EMA/VolMA/BOLL/KDJ/WR/CCI/OBV).
* Route cache-miss `switchKlineData` through the same path as cache-hit: it now clears the chart, resets the viewport and cancels the active cross; add `markRepaintAll` for the chart+cross+draw triple.
* Replace `IConfiguration.generateFlexiKlineConfig` with `getFlexiKlineConfig` and `saveFlexiKlineConfig`; implementations mixing in `FlexiKlineConfigurationMixin` need no change (Breaking Changes).
* Remove the `autoSave` constructor parameter and all implicit persistence (no longer written on `dispose` or `onThemeChanged`); callers must invoke `storeFlexiKlineConfig()` explicitly (Breaking Changes).
* Add `reloadFlexiKlineConfig([config])` so one controller can catch up with another, fixing landscape config changes not taking effect after returning to portrait; override `getFlexiKlineConfig` to return a cached instance for controllers sharing one runtime config.
* Fix evicting the head of a full sub-indicator queue leaving its key in the config, which made the reload diff rotate the sub queue on every call.
* Keep `PaintObject.handleTap` as a boolean consumed result and leave persistent selection state to each indicator; remove framework-held PaintObject selection interfaces (Breaking Changes).
* Add PaintObject drag gestures `handleDragStart`/`handleDragUpdate`/`handleDragEnd`/`handleDragCancel`; the first object that claims the start position owns the full gesture and suppresses chart pan, inertial pan, loadMore and Cross updates.
* Dispatch PaintObject taps and drag starts by descending `zIndex`, so the visually topmost indicator receives the first opportunity to claim an interaction (Breaking Changes).
* Dispatch main-area taps and drag starts through `MainPaintObject` using the new `reversedPaintableChildren` order; sub-area panes stay position-routed and iterate in paint order because they are geometrically exclusive, and a hit region must lie within its owning pane (Breaking Changes).
* Change `MainPaintObject.paintableChildren` to return `Iterable<PaintObject>` instead of `Set<PaintObject>`, which stops allocating a set per call in line chart mode and stops handing out the live `children` set; use `isPaintable` for membership queries (Breaking Changes).
* Cancel an active Cross after a PaintObject consumes a tap, while preserving Cross-owned tooltip taps.
* Fix main-area indicators hidden by line chart mode staying tappable through their last painted hit regions; tap dispatch now uses `paintableChildren` like the paint path.
* Add `MainPaintObject.isPaintable` and exclude unpaintable objects from tap and drag-start dispatch.
* Replace `PaintContext.requestCancelPaintObjectDrag` with `requestReleasePaintObject`, one channel a PaintObject uses to have the framework drop what it holds for that object: each binding overrides it with an identity guard, covering both leaving the paint tree and voluntarily aborting an in-flight interaction, so `onExitTree` no longer enumerates framework-side references one by one (Breaking Changes).
* Fix `FlexiStateNotifier.updateValue` notifying twice when the value actually changes; it now notifies exactly once and still notifies on in-place mutation.
* Enable `onPointerCancel` on the non-touch gesture detector to roll back an in-progress PaintObject drag, which `onPanEnd` would otherwise commit.
* Fix touch PaintObject drags missing small handles: hit-test at the recorded `PointerDown` position instead of the gesture recognition position, and carry the pre-recognition displacement into the first drag update.
* Fix the same miss on the non-touch detector for non-mouse pointers, whose pan slop is 36px: set `DragStartBehavior.down` so `onPanStart` reports the `PointerDown` position and Flutter replays the pre-recognition displacement.
* Fix touch landed gestures losing to an enclosing scroll view: resolve zoom slider, zooming move, draw drawing/editing, Cross and PaintObject ownership from the first `PointerDown`, then let the chart's scale recognizer claim before the outer `Scrollable`; blank-area drags still scroll the outer view.
* Add `PaintObject.hitTestDragStart`, a side-effect-free companion to `handleDragStart` that indicators must implement to be draggable inside a scrollable container; it runs on every `PointerDown`, including taps and long presses, so it must not mutate state, repaint or fire business callbacks.
* Add `FlexiKlineController.hitTestPaintObjectDrag` and `hitTestDrawObjectDrag`, mirroring the hit rules of `onPaintObjectDragStart` and `onDrawMoveStart` without claiming the drag.
* Fix draw objects in edit mode never winning a drag inside a scrollable container: the arena claim only asked about PaintObjects.
* Fix draw object drags missing their hit targets: hit-test at the recorded `PointerDown` position, whose offset from the recognition position (`kPanSlop`, 36px when unclaimed) far exceeds `DrawConfig.hitTestMinDistance` (10px).
* Fix pinch zoom jumping on the first frame: set `DragStartBehavior.start` on the chart's scale recognizer so `_initialSpan` is rebased on accept and `ScaleUpdateDetails.scale` starts from 1.0.
* Add `GestureConfig.dragClaimSlopFactor` (default 0.5, clamped to 0.1~0.9) expressed as a ratio of the outer hit slop rather than a pixel value, because `touchSlop` is platform-supplied and often below `kTouchSlop` on Android, where any hardcoded pixel threshold fails on some devices.
* Change a small move-then-release on a draggable object from a tap into a drag once the displacement passes the claim slop, which on touch is now half the outer hit slop instead of `kPanSlop` (Breaking Changes).
* Make the zoom slider claim on `PointerDown`, preventing taps in its dedicated region from starting Cross.
* Keep a landed gesture's owner when a second finger is added, so an in-progress draw or PaintObject drag is no longer canceled or converted to chart scale (Breaking Changes).
* Take landed-gesture positions from the tracked first pointer instead of `ScaleUpdateDetails.localFocalPoint`, so adding a second finger no longer snaps a drag to the two-pointer centroid; chart scale still uses the centroid.
* Replace touch-path `gestureArena.sweep` calls with owner-driven Scale claims, so a moved-then-released gesture is no longer reported as a tap; Tap still handles displacements below the claim slop.
* Keep dragging an in-progress drawing point from confirming it on release: confirmation stays a separate tap, matching the pre-claim behavior where `TapGestureRecognizer` stopped tracking once the drag passed its post-accept slop.
* Stop a Cross drag from dismissing the Cross on release: Cross is a mode entered and left by tapping, and panning in between only moves it (Breaking Changes).
* Drive every landed gesture through `onScaleUpdate` instead of `Listener.onPointerMove`, so Cross, zoom slider, zooming move and in-progress drawing update at most once per display frame like the other gesture paths.
* Derive landed-gesture coordinates from a fixed anchor plus the first pointer's total displacement, so frames dropped by the per-frame throttle no longer drop movement.
* Anchor a Cross drag on the authoritative `crossOffset` instead of the gesture data left by the last `onTapUp`, so the crosshair continues from where it is instead of jumping back to the last tap position.
* Yield the gesture arena on long press for Cross and in-progress drawing, the two owners long press itself does nothing for, so pausing before a drag no longer swallows the whole gesture.
* Claim the gesture arena for chart pan when a touch drag is horizontally dominant, halving its start threshold from `kPanSlop` (36px) to the outer hit slop (18px); vertical and shallow diagonal drags still yield to an enclosing scroll view, and displacements below the hit slop stay taps.
* Add `GestureConfig.panClaimRatio` (default 2, clamped to 1~10): the `|dx| > |dy| x ratio` cone deciding whether a fallback touch drag pans the chart or scrolls the outer view.
* Dispatch touch chart gestures by intent instead of pointer count: two fingers moving together horizontally now pan instead of winning the arena and doing nothing, since their span never changes and `ScaleUpdateDetails.scale` stays at 1.0 (Breaking Changes).
* Switch chart pan to chart scale mid-gesture once the finger span changes by more than `kScaleSlop`; the reverse switch is not allowed.
* Reset the pan smooth factor when a pan turns into a scale, which the scale end path never did.
* Remove `setMultiTouch` and `isMultiTouchListenable`: arena claiming replaced the need for hosts to swap in `NeverScrollableScrollPhysics`, and disabling the outer scroll view also swallowed the two-finger vertical drag it should receive (Breaking Changes).

## 2.3.2
* Add `crossOffsetListenable` so external consumers can subscribe to Cross focus changes.
* Constrain multiline `drawText` and `drawImageText` layouts to their `drawableRect`, while retaining existing single-line width behavior.
* Change `FlexiKlineController.moveToDateTime(DateTime)` to an awaitable API returning `Future<int?>`: it completes after the movement animation and returns the resolved candle index, or `null` when the request cannot complete (Breaking Changes).

## 2.3.1
* Add optional `TipsConfig.lineWidth` to override the width of the indicator line a tips represents (color still derived from `style`); when null it falls back to the indicator-level `lineWidth`.
* Add `defaultAuxiliaryLineWidth` constant (0.5) and apply it to auxiliary lines (crosshair, grid, high/low and latest-price mark lines), replacing scattered `0.5` literals and distinguishing them from data lines (`defaultIndicatorLineWidth`).
* Simplify magnifier `CircleBorder` resolution: only the border color falls back to the theme grid-line color when transparent; the configured `width` and `style` are now respected (previously `width <= 0` was forced to `1` and `BorderStyle.none` to solid). `MagnifierConfig.shapeSide` default is now `BorderSide(color: transparent, width: 0.5)`.
* Fix `TooltipConfig` JSON deserialization to default `hitTestMargin` to `2`, matching the constructor default.

## 2.3.0
* Improve `FlexiLayoutMode.fixed` canvas size resolution: resolve width and height independently (parent constraints first, `fixedSize` fallback) to cover more constraint combinations.
* Relax `initialFixedSize` assert in fixed layout mode: only `height` must be finite when provided; width can be resolved from parent constraints.
* Add `isMounted` guard in `paintChart` to prevent accessing uninitialized PaintObjects during early render frames.
* Align paint naming by drawing position: rename indicator top-bar hook `paintTooltip` to `paintTips`; Cross-layer floating box APIs (`TooltipInfo`, `TooltipConfig`, `CrossBinding.paintTooltip`) remain unchanged (Breaking Changes).
* Rename `allowPaintExtraOutsideMainRect` to `allowOverlayOutsideMainRect` in `SettingConfig` and JSON serialization (Breaking Changes).
* Add default no-op `paintTips` implementation on base `PaintObject`.
* Remove redundant `computeVisibleMinMax` and `paintTips` overrides from `TimePaintObject`.
* Add `Indicator.autoActivate` to control auto-show on mount or false→true update; Direct/Computed default `false`, External default `true`, Candle/Time/Main fixed `true`; turning to `false` does not auto-hide (Breaking Changes).
* Defer PaintObject creation to activation time: External indicators are no longer eagerly created on declaration; `keepAlive` only controls dispose-on-hide (Breaking Changes).
* `mountIndicators` now activates the deduplicated union of persisted keys and `autoActivate` declarations; `updateIndicators` returns pending activation keys for `showMainIndicator`/`showSubIndicator`.
* Fix computed slot capacity as a high-water mark so deleting middle indicators does not shrink `slots` array below surviving high-index data.
* Add `FlexiKlineController.moveToDateTime(DateTime)` with animated viewport positioning; add `KlineData.indexAtOrBefore` for nearest loaded candle lookup.
* Unify Cross tooltip rendering via `Canvas.drawTooltipInfos` for aligned two-column layout; add `TooltipInfo.onTap` with configurable `TooltipConfig.hitTestMargin` and `TooltipConfig.spacing` (Breaking Changes).
* Remove `TooltipInfo.riseOrFall` in favor of `valueStyle` at the data layer (Breaking Changes).
* Stabilize tooltip width during crossing via session-level `minContentWidth` tracking.

## 2.2.0
* Redesign widget-level indicator declaration: `FlexiKlineWidget` now accepts `candle`, `time`, `mainIndicators`, `subIndicators` directly; add `FlexiKlineWidget.indicator` named constructor for `IIndicatorConfig` (Breaking Changes).
* Simplify `IConfiguration` interface: remove `configKey`, `candleIndicatorBuilder`, `timeIndicatorBuilder`, `mainIndicatorBuilders`, `subIndicatorBuilders`; retain only `theme`, `generateFlexiKlineConfig`, `drawObjectBuilders` (Breaking Changes).
* Introduce `IIndicatorConfig` interface to decouple indicator provision from framework configuration; user-owned storage replaces built-in persistence (Breaking Changes).
* Rename indicator taxonomy: Normal→Direct, Data→Computed, Business→External; `NormalIndicatorKey`→`DirectIndicatorKey`, `DataIndicatorKey`→`ComputedIndicatorKey`, `BusinessIndicatorKey`→`ExternalIndicatorKey` (Breaking Changes).
* Rename PaintObject base classes: `DataPaintObject`→`ComputedPaintObject`, `BusinessPaintObject`→`ExternalPaintObject`, `NormalPaintObject`→`DirectPaintObject` (Breaking Changes).
* Introduce `IPaintLifecycle` interface with unified lifecycle hooks: `initState`, `didChangeDependencies`, `didAttach`, `didDetach` (Breaking Changes).
* Replace `syncAllIndicators()`/`init()` with `mountIndicators()`; rename `syncIndicators()` to `updateIndicators()` (Breaking Changes).
* Replace `LayoutMode` class hierarchy with `FlexiLayoutMode` enum (`adapt`/`fixed`); add `FlexiKlineController.initialLayoutMode` parameter (Breaking Changes).
* Replace `autoAdaptLayout` bool on `FlexiKlineWidget` with `FlexiLayoutType` enum (`adapt`/`fixed`/`normal`) (Breaking Changes).
* Split `IPaintContext` into scoped interfaces: `PaintEnvironment`, `PaintDataScope`, `PaintGeometryScope`, `PaintRuntimeScope` (Breaking Changes).
* Split `IDrawContext` into scoped interfaces: `DrawEnvironment`, `DrawDataScope`, `DrawGeometryScope`, `DrawRuntimeScope` (Breaking Changes).
* Rename `curKlineData` to `klineData`; rename `cancelCross` to `requestCancelCross` (Breaking Changes).
* Rename `FlexiKlineThemeConfigurationMixin` to `FlexiKlineConfigurationMixin` (Breaking Changes).
* Add `FlexiKlineLifecycle` enum (`initial`/`mounted`/`disposed`) with `lifecycleListenable` for controller state observation.
* Add `PaintObject.mount()` lifecycle method (mirrors Flutter `Element.mount`); inject indicator/context/logger at mount time.
* Add `isMounted` guards to controller APIs (`setCanvasSize`, `setMainSize`, `onThemeChanged`, etc.) to prevent late-field access before `mountIndicators` completes.
* Add `FlexiStateNotifier.setSilently` for build-phase value initialization without triggering subscriber `setState`.
* Move grid/chart/cross/draw repaint triggers onto `KlineBindingBase`; internalize layer repaint APIs.

## 2.1.1
* Optimize `mergeCandleList` performance: add in-place fast paths for head/tail aligned updates to reduce unnecessary list copies on hot path.
* Fix `getLoadMoreSpec()` from/to direction for loading more historical data.
* Fix combine sub-indicator (e.g. MA) min/max not refreshed after add/remove, which caused lines to be drawn at chart bottom.
* Fix candle interval chart-type lookup to use `ITimeInterval` equality instead of milliseconds comparison.
* Expose `chartZoomSlideBarRect` on `IPaintContext` and indicator paint context for custom hit-testing or overlay layout.
* Remove built-in interval constants (`interval1m`, `interval1D`, etc.) from `constant.dart`; use `FlexiTimeInterval` or custom `ITimeInterval` implementations instead (Breaking Changes).
* `KlineSpec.interval` is now required; default `limit` changed from 100 to 200.
* Default `CandleIndicator` no longer pre-configures line chart for 1s/1m intervals.

## 2.1.0
* Simplify configuration system: config color fields are now nullable, theme colors are injected at paint time via .ensure() pattern (Breaking Changes).
* Decouple theme colors from config objects: replace hardcoded color defaults with lazy injection mechanism (Breaking Changes).
* Redesign IFlexiKlineTheme: remove scale/pixel/setDp/setSp methods and BaseFlexiKlineTheme class; rename color properties for clarity (long→longColor, short→shortColor, gridLine→gridLineColor, etc.) (Breaking Changes).
* Rename timeBar parameter to interval for consistency across the codebase (Breaking Changes).
* Simplify time interval interface: introduce ITimeInterval/FlexiTimeInterval to replace TimeBar enum (Breaking Changes).
* Restructure logging system: introduce layered IFlexiLogger/FlexiLog architecture with cleaner separation of concerns (Breaking Changes).
* Update kline data structures: add KlineSpec class and KlineLoadingState enum to replace CandleReq (Breaking Changes).
* Add Color? extension methods (isValid, ensure, or) in style_ext.dart for nullable color handling.
* Add themeColor params to drawing primitives (drawLineByConfig, drawCirclePoint, drawTextArea).
* Rename TextAreaConfig.background to backgroundColor for consistency.
* Make default configs const where possible for better performance.
* Clean up configuration framework and improve serialization handling.

## 2.0.0
* Replace BagNum with FlexiNum for numeric representation (Breaking Changes).
* Introduce ICandleModel interface and FlexiCandleModel; unify candle model to support custom models (Breaking Changes).
* Refactor Indicator to generic class with typed key system: IIndicatorKey sealed class with DataIndicatorKey, BusinessIndicatorKey and NormalIndicatorKey subtypes (Breaking Changes).
* Split PaintObjectIndicator into DataIndicator and BusinessIndicator with corresponding DataPaintObject and BusinessPaintObject (Breaking Changes).
* Refactor paint object interfaces: rename IPaintBoundingBox to IPaintBounding, introduce IBasePainter/IComputablePainter/IBusinessPainter, add PaintObjectComputableMixin (Breaking Changes).
* Change PaintObject initialization to lazy pattern; remove context and indicator from constructors (Breaking Changes).
* Deprecate TimeBar enum and unify with ITimeBar (Breaking Changes).
* Rename supportLongPress to enableLongPress in GestureConfig (Breaking Changes).
* Refactor project structure: extract `TimeBar`, `LayoutMode`, `FlexiChartType`, indicator keys and paint interfaces into independent modules; rename `common.dart` files to `types.dart` / `interfaces.dart`.
* Add `FlexiUpdater<T>` typedef and `updateXxxConfig` convenience methods to SettingBinding.
* Improve type safety: replace manual casts with `whereType<IComputablePainter>()`.
* Add enableScale property to GestureConfig to allow disabling scale/zoom gestures.
* Resolve two-finger zoom gesture conflicts and optimize zoom experience.
* Add Y-axis smooth interpolation during pan to reduce coordinate jumps.
* Add panSmoothFactor and convergenceRatio to ToleranceConfig for configurable smoothing.
* Update inertial pan duration formula from log to sqrt for better velocity-to-duration mapping.
* Enhance lint rules and apply fixes across codebase.

## 1.2.1
* Refactor ChartType to FlexiChartType with improved structure and key property (Breaking Changes).
* Add negative number constants to BagNum (minusHundred, minusFifty, minusTen, minusThree, minusTwo, minusOne).
* Add time bar comparison methods (isSameAs, compareTimeBar) for ITimeBar.
* Improve chart framework serialization and object handling.
* Update flexi_formatter dependency to ^1.7.3.

## 1.2.0
* Fix multiple naming typos in public APIs (Breaking Changes).
* Add latest candle point marker for line chart.
* Refactor ChartType to sealed class; replace timeChartType/minCandleWidthChartType with timeBarChartTypes/minWidthLineType for flexible chart type configuration (Breaking Changes).
* Move hideIndicatorsInTimeChart from SettingConfig to CandleIndicator as hideIndicatorsWhenLineChart (Breaking Changes).
* Replace LinearGradient with GradientConfig for better serialization and flexibility; rename chart painting methods (Breaking Changes).


## 1.1.1
* Add listening for the painting range changes.
* Optimize the minmax of chart when no market fluctuation.
* Optimize the details of the zoom operation; Add listening to the zoom slide bar area.
* bugfix.

## 1.1.0
* Optimize the TimeBar and support flexible customization.
* Support image drawing.
* Support image and text drawing.
* Add more painting methods.
* bugfix.

## 1.0.0
* Optimize the calculation performance of indicators
* Optimize gesture detector performance.
* Optimize configuration management: load, store, update.
* Optimize KlineData structure.
* Added multiple chart types and styles for candlestick charts.
* Provide FlexiKlinePage mixin to assist development.
* Optimize indicator chart painting performance and configuration.
* Optimize scrolling animation.
* bugfix.

## 0.9.1
* Rearrange layout mode And bugfix.
* Optimize web gestures.

## 0.9.0
* Configuration management refactoring
* Optimization indicator framework
* Add keyboard event handling on non-touch devices
* Add layout mode: normal, adapt, fixed
* Add zoom chart feature
* bugfix

## 0.8.0
* New Architecture Design
* Indicator Framework Refactoring
* Adjust the height of the indicator chart by dragging the Grid line
* bugfix

## 0.7.1
* Support Draw Feature
* Optimize gesture

## 0.7.0
* Drawing overlay framework implementation
* Optimize coordinate conversion of indicator chart data
* Optimize drawing gesture processing
* Added drawing magnifying glass

## 0.6.0
* Support Desktop
* Support Web
* Refactor gesture recognition framework to adapt to Web/Desktop
* Demo for custom indicators and replacing built-in indicators.

## 0.5.0
* Support landscape mode.
* Optimize zooming functionality.
* Optimize configuration management.
* Dispose indicators when unbinding.
* Add secondary chart indicators.

## 0.4.0
* Theme switching implementation.
* Configuration framework optimization.
* Data loading interface encapsulation.
* Candle data merging algorithm optimization.
* Indicator calculation performance optimization.
* Gesture operation optimization.
* Flutter minimum supported version

## 0.3.0
* Configuration framework implementation
* Optimization of metric data calculation
* Core + framework framework optimization
* Kline implements dynamic adjustment of width and height


## 0.2.0
* New drawing architecture design.
* Indicator configuration management (serialization, local storage)
* Indicator calculation design and implementation Volume, MA, EMA, BOLL, MACD, KDJ, MAVOL

## 0.1.0
* 项目FlexiKline
* 整体框架
* 基础蜡烛图绘制
* example示例
