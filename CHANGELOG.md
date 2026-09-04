## 2.5.0
* Pan the chart with horizontally dominant scroll signals (Web trackpad two-finger slide, `Shift` + wheel) on non-touch devices; `PointerScrollEvent.scrollDelta.dx` was previously discarded entirely, so a horizontal slide either did nothing or triggered a slight zoom from its small `dy`.
* Add `onChartPanStep(double dxDelta)` for one-shot horizontal panning; unlike `onChartMove` it runs the loadMore check itself, since signal events have no end event to hang it on.
* Dispatch each scroll signal to exactly one action: horizontally dominant events (`|dx| >= |dy| × 2`) pan, everything else zooms, so a diagonal slide no longer both pans and zooms. Horizontal scroll over the price axis is not consumed and passes through to an enclosing `Scrollable`.
* Allow trackpad two-finger horizontal slide to pan the chart without being misidentified as a pinch zoom; the pinching threshold is now based on cumulative deviation from 1.0 (`> 0.05`) instead of per-frame change (`> 0.01`).
* Exit Y-axis zoom with ESC key or right-click on non-touch devices; ESC prioritises exiting zoom over exiting draw mode when both are active. Keyboard focus is now automatically requested when entering zoom or draw state.
* Cancel the cross cursor when starting to drag a draw object in editing mode; cross resumes naturally when the user moves the mouse after the drag ends.
* Bound the reachable Y-axis zoom span in both directions, and clamp out-of-range candidates instead of rejecting them; rejection left the range unchanged, so a wheel event that could not clear the bound in one step deadlocked the wheel permanently, reverse direction included.
* Add `SettingConfig.minZoomSpanRatio` (default 0.05) and `SettingConfig.maxZoomSpanRatio` (default 20), expressing how far the Y axis can be zoomed as multiples of the visible price span captured when the user took over the axis.
* Fix repeated touch drags on the price-axis slider compressing the visible price range without limit: the bound now applies to both input chains through a single write point.
* Fix the visible price range becoming non-finite after repeated zoom-out, which also disabled vertical panning and left exiting zoom as the only way back.
* Fix the Y-axis zoom bound depending on whether touch or the scroll wheel zoomed first; zoom is now tracked as a cumulative factor instead of a span snapshot read from the live range.
* Derive Y-axis scroll sensitivity from `GestureConfig.maxZoomPerGesture` and the main chart height so the same travel produces the same zoom factor on both input chains; `GestureConfig.signalScaleFactor` now affects X-axis scaling only (Breaking Changes).
* Clamp `candleMinWidth` to at least 1: a zero lower bound let touch scaling land `candleWidth` exactly on 0, and with no `candleFixedSpacing` the derived spacing collapsed too, leaving `candleActualWidth` at 0 and the candle-count estimation non-convergent.
* Resize sub panes by hovering the divider line (`resizeRow` cursor) and dragging directly on non-touch devices, replacing the long-press interaction inherited from touch devices.
* Remove long-press gesture handling from non-touch devices; `gestureConfig.enableLongPress` no longer has effect on mouse/trackpad input (Breaking Changes).
* Fix trackpad pinch simultaneously panning the chart on native platforms; `DragGestureRecognizer` consumed `PointerPanZoomUpdateEvent.panDelta` as drag input in parallel with the `Listener` scale path. A per-session `pinching` flag now suppresses pan in `onPanStart` and `onPanUpdate` once the scale change exceeds the threshold.
* Add `onChartZoomStep(double coeff)` for incremental Y-axis zoom; each signal event multiplies the current visible range by a ratio factor, with no session or anchor required.
* Add `GestureConfig.signalScaleFactor` (default 200, matching Flutter's `kDefaultMouseScrollToScaleFactor`) to control mouse scroll-to-zoom sensitivity, and `GestureConfig.scaleSessionTimeout` (default 800ms) for the X-axis scale session idle window.
* Rewrite `onPointerSignal` to register with `GestureBinding.pointerSignalResolver` instead of consuming events directly, so the chart placed inside a `Scrollable` no longer simultaneously triggers page scroll; unify scroll and `PointerScaleEvent` (Web trackpad pinch) to a single ratio-based factor via `exp(-dy / signalScaleFactor)`.
* Replace the two `Future.delayed(1000ms)` timers in the signal path with a single resettable `Timer` per scale session; rapid consecutive scrolls no longer get their session cut short mid-stream.
* Change `onChartScale` signal branch from additive (`candleWidth + data.scale`) to multiplicative (`candleWidth * data.scale`) for ratio-based consistency with `_resolveSignalFactor`.
* Remove the `delta` named parameter from `GestureData.zoom`; its only caller was the now-removed scroll-zoom dead code, and touch-side callers already use the positional-only form (Breaking Changes).
* Rename `scaledSingal` to `scaledSignal` in `algorithm_util.dart` to fix the typo; the function is in the public export surface via `lib/flexi_kline.dart` (Breaking Changes).
* Add `hitTestGridResize(Offset)` on the controller: a side-effect-free query that shares the same hit-test loop as `onGridResizeStart`, enabling hover-time cursor feedback without triggering a repaint.
* Change the hover cursor over a hittable `PaintObject` from `precise` to `grab` on non-touch devices, signalling that the element can be dragged.
* Move `_zoomMinMax`, `setZoomMinMax`, `clearZoomMinMax` and `hasZoomMinMax` from `PaintObjectGeometryStateMixin` to `MainPaintObject`; zoom state is now owned solely by the main paint object (Breaking Changes).
* Combine children proxy the parent `minMax` via `PaintObject.minMax` override instead of receiving explicit `setMinMax` / `setZoomMinMax` dispatches; the two dispatch loops and the `_smoothMinMax`-pollution cleanup in `delegate.dart` are removed (Breaking Changes).
* Separate smooth display value from the auto-computed target: `smoothMinMax()` writes only `_smoothMinMax` and never calls `setMinMax`, so `_minMax` always holds the pure convergence target from `computeVisibleMinMax`.
* Guard `dyFactor` against non-positive `chartRect.height`: return 0 instead of computing a negative factor that mirrors the Y axis; `dyToValue` returns null when `dyFactor` is zero to avoid division by zero.
* Cache the eight default `Paint` objects in `PaintStyleMixin` so they are created once and reused across frames; bar paints update only `strokeWidth` each access to track `candleWidth` changes. `didChangeTheme` clears the cache so colours rebuild on the next frame.
* Move `didChangeTheme` declaration from `PaintObject` to `IndicatorObject` with `@mustCallSuper`, allowing mixins on `IndicatorObject` (like `PaintStyleMixin`) to override it for cache cleanup.
* Remove `_tmpPadding`, `setPadding` and the `padding` parameter from `doUpdateLayout`; `padding` now returns `indicator.padding` directly, and combine children proxy `_parent!.padding` to stay aligned with the main area (Breaking Changes).
* Add `MinMax.scaleAroundCenter` and `MinMax.shift` to scale a price range around its centre and to shift it as a whole.
* Add `setZoomMinMax`, `clearZoomMinMax` and `hasZoomMinMax` on paint objects, carrying a user-controlled Y-axis range that takes precedence over the automatic one; it applies to the main coordinate system and its combine children, while `PaintMode.alone` children keep fitting the visible data.
* Scale the visible price range on Y-axis zoom instead of shrinking the chart area through `padding`: `padding` keeps its declared value and `mainChartRect` stays put, so panning while zoomed no longer re-fits the Y axis and candles keep their relative positions (Breaking Changes).
* Derive the zoom factor from the range snapshot taken when the slider is pressed, so dragging back to the start restores the original range instead of drifting.
* Exit zoom on gesture end only when the gesture produced no scale at all, replacing the padding-equality check that used to stand in for it.
* Remove the `mainMinSize` guards from `onChartZoomUpdate` and the proportional padding compensation applied on main-area resize: zoom no longer touches pixel geometry, so a manual range survives a resize unchanged.
* Shift the visible price range on vertical drag while the Y axis is user-controlled, instead of moving the chart area through `padding`; the span is preserved and the guard now reads the model state rather than the gesture type, so `onChartMove` consumes `dy` whenever `isChartZooming` holds (Breaking Changes).
* Remove `FlexiGestureOwner.zoomingMove`: a drag in the main area while zoomed is now owned by `chartPan`, which serves both axes, so it also gains the horizontal inertial pan it previously lacked (Breaking Changes).
* Claim a purely vertical drag for the chart while the Y axis is user-controlled, where the direction test in `resolveChartFallback` no longer applies; the claim now waits for the outer `hitSlop` instead of the earlier `claimSlop` the removed owner used.
* Remove `mainOriginPadding` and stop switching the Cross tooltip offset between it and `mainPadding`: the two are identical now that zoom leaves `padding` alone, and the main area no longer has a runtime padding distinct from its declared one (Breaking Changes).
* Hand the Y axis back to automatic fitting when the symbol changes, while a change of interval keeps the range the user set; the test is `KlineSpec.symbol`, since `spec.key` also encodes the interval.
* Keep the main-area clip at `mainRect` while the Y axis is user-controlled: the clip was only widened to let interpolated ranges overflow during a smoothed pan, which cannot happen while zoomed, so zoomed-in candles no longer bleed into the sub panes.
* Replace `GestureConfig.zoomSpeed` with `maxZoomPerGesture`, the maximum factor one price-axis drag may magnify or compress the visible range; the coefficient now stays within `[1 / maxZoomPerGesture, maxZoomPerGesture]` regardless of main-area height. The old field amplified the coefficient after the softening term, which put its only safe value at the default 1: anything higher could drive the coefficient to zero or below, inverting the range and throwing from the `valueToDy` clamp (Breaking Changes).
* Remove the `isConvert` parameter of `onChartZoomStart`: every caller passed false, and the conversion it applied matched neither documented coordinate space. `setChartZoomSlideBarRect` now states that the rect must be in canvas coordinates and asserts that it overlaps `mainRect` (Breaking Changes).
* Rename `GestureConfig.isManualSetZoomRect` to `useCustomZoomRect`, keeping its meaning and polarity: true means the host owns the zoom slider rect and the candle indicator stops reporting one. The serialized key changes with it, so a stored config that set the old key falls back to the default and reverts to the auto-reported rect until it is saved again (Breaking Changes).
* Keep the chart in its zoomed state when a zoom gesture starts outside the slider or before a price range exists, instead of clearing `isChartZooming` while the zoom range stayed applied — that combination hid the reset button while the Y axis remained locked. Handing the Y axis back is now only possible through `exitChartZoom`.
* Add `Rect.distanceFromBottom`, replacing the private helper that measured a dy against the main chart area (renamed from the unused `invertedToDistane`); it returns null for a non-positive height, since an inverted rect makes the underlying `clamp` throw (Breaking Changes).

## 2.4.1
* Fix the blank band above the candles left after hiding main-area indicators, which survived config reload and data refresh and could only be cleared by rebuilding the controller.
* Move the main-area tips height out of `padding` into a dedicated geometry input consumed by `topRect`: the tips area follows activation and declaration changes on the next paint with no explicit reset, and `padding` keeps its declared value throughout (Breaking Changes).
* Remove the `MainPaintObject.paintTips` override that returned `topRect.size`: it had no caller and closed a feedback loop between the tips height and the padding it derived from (Breaking Changes).

## 2.4.0
* Fix a permanent blank band above the candles after main-area indicators are hidden: tips-driven `padding.top` now resets whenever the activation set or indicator declarations change, then regrows on the next frame.
* Serialize candle merging and indicator calculation through one data pipeline bound to the current `KlineData`, driven by a fixed calculation tick (`FlexiKlineController.calculationInterval`, default 500ms): the two phases never modify one `KlineData` concurrently, and switching spec destroys the old pipeline together with its pending queue (Breaking Changes).
* Replace `updateKlineData(spec, list, reset:)` with `replaceKlineData`, `updateLatestKlineData` and `appendHistoryKlineData`, so the caller declares intent instead of the pipeline inferring direction from timestamps (Breaking Changes).
* Move indicator calculation out of PaintObject into `IndicatorCalculator`: `ComputedIndicator` now requires `createCalculator(dataIndex)` and answers `shouldRecompute` from `calcParam`, while `ComputedPaintObject` only reads slots and paints (Breaking Changes).
* Remove `KlineData.enqueueWaitingData`, `hasWaitingData` and `waitingDataLength`; pre-mount input is held by the pipeline instead of by `KlineData` (Breaking Changes).
* Add `evictInactiveKlineDataCache()` and drop non-current cached `KlineData` when computed slot layout or indicator params change, so a cached snapshot cannot carry stale indicator values.
* Fix the accumulated dirty range not translating when `updateLatestKlineData` inserts a new head candle, which silently skipped recompute for incremental indicators (MA/EMA/VolMA/BOLL/KDJ/WR/CCI/OBV).
* Route a cache-miss `switchKlineData` through the same path as a cache hit: it now clears the chart, resets the viewport and cancels the active cross; `markRepaintAll` covers the chart+cross+draw repaint triple.
* Replace `IConfiguration.generateFlexiKlineConfig` with `getFlexiKlineConfig` and `saveFlexiKlineConfig`; implementations mixing in `FlexiKlineConfigurationMixin` need no change (Breaking Changes).
* Remove the `autoSave` constructor parameter and all implicit persistence, which no longer happens on `dispose` or `onThemeChanged`: callers must invoke `storeFlexiKlineConfig()` explicitly or user adjustments are silently lost (Breaking Changes).
* Add `reloadFlexiKlineConfig([config])` so one controller can catch up with another, fixing landscape config changes not taking effect after returning to portrait; override `getFlexiKlineConfig` to return a cached instance when several controllers share one runtime config.
* Fix evicting the head of a full sub-indicator queue leaving its key in the config, which made the reload diff rotate the sub queue on every call.
* Add PaintObject drag hooks `handleDragStart`/`handleDragUpdate`/`handleDragEnd`/`handleDragCancel` plus the side-effect-free `hitTestDragStart` an indicator must also implement to be draggable inside a scrollable container: the first object claiming the landing position owns the whole gesture, and the framework suppresses chart pan, inertial pan, `loadMore` and Cross updates for its duration.
* Add `FlexiKlineController.hitTestPaintObjectDrag` and `hitTestDrawObjectDrag`, mirroring the hit rules of `onPaintObjectDragStart` and `onDrawMoveStart` without claiming the drag.
* Dispatch PaintObject taps and drag starts by position and descending `zIndex` so the visually topmost object answers first: main-area hits iterate the new `MainPaintObject.reversedPaintableChildren`, `MainPaintObject.handleTap` is gone, and a hit region must lie within its owning pane (Breaking Changes).
* Change `MainPaintObject.paintableChildren` to return `Iterable<PaintObject>` instead of `Set<PaintObject>`, which stops allocating a set per call in line chart mode and stops handing out the live `children` set; use the new `isPaintable` for membership queries (Breaking Changes).
* Fix main-area indicators hidden by line chart mode staying tappable through their last painted hit regions: tap and drag-start dispatch now exclude unpaintable objects like the paint path does.
* Cancel an active Cross after a PaintObject consumes a tap, while preserving Cross-owned tooltip taps.
* Add `PaintContext.requestReleasePaintObject`, one channel a PaintObject uses to have the framework drop what it holds for that object, covering both leaving the paint tree and voluntarily aborting an in-flight interaction, so `onExitTree` no longer enumerates framework-side references one by one (Breaking Changes).
* Fix `FlexiStateNotifier.updateValue` notifying twice when the value actually changes; it now notifies exactly once and still notifies on in-place mutation.
* Resolve touch gesture ownership once from the first `PointerDown` — draw drawing/editing, Cross, PaintObject, zoom slider and zooming move — and claim the gesture arena before an enclosing `Scrollable`, which a landed gesture could never win because single-finger pan slop is by definition twice the outer hit slop; hit tests and drag baselines both use the `PointerDown` position instead of the recognition position a slop away, so small targets are reachable again (`DrawConfig.hitTestMinDistance` is 10px against a 36px `kPanSlop`) and the first drag update covers the pre-recognition displacement. Blank-area drags still scroll the outer view.
* Set `DragStartBehavior.down` on the non-touch detector so `onPanStart` reports the `PointerDown` position for non-mouse pointers, and enable `onPointerCancel` there so a cancelled drag rolls back instead of being committed by `onPanEnd`.
* Replace touch-path `gestureArena.sweep` calls with owner-driven Scale claims: a move-then-release on a claimed target is now a drag rather than a tap once the displacement passes the claim slop, which on touch is half the outer hit slop instead of `kPanSlop`; smaller displacements stay taps (Breaking Changes).
* Drive every landed gesture through `onScaleUpdate` instead of `Listener.onPointerMove`, deriving coordinates from a fixed anchor plus the first pointer's total displacement so the per-frame throttle cannot drop movement; a Cross drag anchors on the authoritative `crossOffset` rather than the gesture data left by the last `onTapUp`, and long press yields the arena for Cross and in-progress drawing, the two owners long press itself does nothing for.
* Keep a landed gesture's owner and its first-pointer coordinates when a second finger joins, instead of cancelling the gesture or snapping it to the two-pointer centroid; chart scale still uses the centroid (Breaking Changes).
* Dispatch chart pan and scale by intent instead of pointer count — finger span first, then a `|dx| > |dy| × panClaimRatio` direction cone — so two fingers moving together horizontally pan instead of winning the arena and doing nothing, and a horizontally dominant drag claims at the outer hit slop (18px) instead of `kPanSlop` (36px) while vertical and shallow diagonal drags yield to an enclosing scroll view (Breaking Changes).
* Switch chart pan to chart scale mid-gesture once the finger span changes by more than `kScaleSlop`, resetting the pan smooth factor on the way; the reverse switch is refused because span stops being a usable baseline once scaling began.
* Claim the arena for chart scale on any pointer's displacement rather than only the first pointer's, compared against the quantity the outer `Scrollable` uses (`spanDelta × 2 > hitSlop × scaleClaimSlopFactor`), which fixes vertical pinch losing to an enclosing scroll view and having made two-finger zoom appear to require a horizontal grip.
* Add `GestureConfig.panClaimRatio` (default 2, clamped to 1~10), `dragClaimSlopFactor` (default 0.5, clamped to 0.1~0.9) and `scaleClaimSlopFactor` (default 1, clamped to 0.5~4); the two slop factors are ratios of the outer hit slop rather than pixel values, because `touchSlop` is platform-supplied and often below `kTouchSlop` on Android where a hardcoded threshold fails on some devices.
* Remove `setMultiTouch` and `isMultiTouchListenable`: arena claiming replaced the need for hosts to swap in `NeverScrollableScrollPhysics`, and disabling the outer scroll view also swallowed the two-finger vertical drag it should receive (Breaking Changes).
* Separate the pointer session from the recognizer segment, which `ScaleGestureRecognizer` splits on every pointer count change: commit a scale segment's `candleWidth` on every scale end, but keep inertial pan and `loadMore` for the end of the whole session so lifting one finger no longer starts inertia mid-gesture, and accumulate `PointerCancel` across the session so a cancelled chart pan skips inertial pan and a cancelled PaintObject drag rolls back (Breaking Changes).
* Take over an in-flight inertial pan on the next touch instead of swallowing that gesture, which the previous "last gesture not finished" guard dropped after a fling (Breaking Changes).
* Resolve `ScalePosition.auto` once per pointer session, so lifting one finger of a pinch and spreading again no longer moves the scale anchor from `middle` to `left`.
* Restore the pan smooth factor when a position animation is interrupted, which `animateToPosition`'s completion callback never did: the leftover value kept the Y-axis min/max interpolating and clipped overlays to `canvasRect` instead of `mainRect`.
* Reorder landed gesture ownership so the zoom slider and zooming move yield to draw, Cross and PaintObject, and gate the zoom slider's `PointerDown` claim on the same chain: dragging with the crosshair shown no longer moves the chart and leaves the crosshair stuck, and starting a zoom requires leaving Cross first (Breaking Changes).
* Stop a Cross drag from dismissing the Cross on release, and stop dragging an in-progress drawing point from confirming it: both are entered and left by tapping, and panning in between only moves them (Breaking Changes).
* Stop a chart fallback gesture from calling draw callbacks after a failed draw claim degraded it to chart pan, so dragging blank space with an overlay selected pans the chart instead of moving every point of that overlay (Breaking Changes).
* Fix pinch zoom jumping on the first frame: set `DragStartBehavior.start` on the chart's scale recognizer so `_initialSpan` is rebased on accept and `ScaleUpdateDetails.scale` starts from 1.0.

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
