## 2.0.1
* Raise minimum SDK to Dart 3.9 / Flutter 3.35; bump `json_annotation` to `^4.12.0`.
* Align `analysis_options.yaml` with the core `flexi_kline` package.
* Regenerate `.g.dart` files with json_serializable 6.14.1 (null-aware elements syntax).
* Apply dart format tall style.

## 2.0.0

First release to pub.dev. The major version is aligned with `flexi_kline`; prior 0.x / 1.x versions were never published.

**Breaking changes (relative to internal 1.0.1)**

* **`ParalleChannel` → `ParallelChannel`**: Fix typo — class names `ParalleChannelDrawObject` / `ParalleChannelDrawParam`, field `paralleBgOpacity`, and file name `paralle_channel.dart` are all corrected to `Parallel`.
* **`drawObjectbuilders` → `drawObjectBuilders`**: Rename the top-level variable (capital `B`) and wrap it with `Map.unmodifiable` to prevent external mutation.
* **Unified config entry `DrawToolsConfig`**: The `static drawParam` fields on 7 `DrawObject` subclasses are now read-only getters backed by `DrawToolsConfig`. Use `DrawToolsConfig.configure()` to customise any tool's parameters in one call. `DrawToolsConfig.resetAll()` is provided for test isolation.
* **`FibRetracementDrawObject` is now independent**: No longer extends `FibExpansionDrawObject`; it has its own `drawParam` instance. Use `DrawToolsConfig.configure(fibRetracement: ...)` to customise retracement separately from expansion.
* **Remove hard-coded debug colours**: Default values of `PriceLineDrawParam.priceText` and `TrendAngleDrawParam.angleText` changed from hard-coded red to `null`, falling back to the core `DrawConfig.ticksText` theme colour.

**Other changes**

* pubspec: Point `repository` / `issue_tracker` to the main repo `FlexiKline/FlexiKline`; widen `copy_with_extension` upper bound to `<18.0.0` (covers 17.1.0).
* dartdoc: Convert all 18 draw-type constants in `common.dart` from `//` to `///`; add doc comments to public API.
* lint: Switch to `package:flutter_lints/flutter.yaml` and align rules with the core package; remove redundant `lints` dev dependency.

## 1.0.1
* Fix `horizontalTrendLine` and `horizontalRayLine` being stuck at their original price: aligning both points to `points.first.dy` made the first point align to itself, so neither dragging it nor translating the whole line could change dy.
* Fix `extendedTrendLine` drawing its line as a back-and-forth polygon, which broke dash phase and darkened translucent colors; it now draws one straight segment via `clipLineToRect`.
* Fix a division by zero in the fibonacci tools when the palette (`fibColors` / `fibFansColors`) and the line colour are both unset; colour resolution now falls back to the theme via `resolveFibColors`.
* Add the first test suite for the package (draw geometry, hit testing, move semantics, colour fallback).

## 1.0.0
* Adapts flexi_kline 1.2.0

## 0.9.0
* Adapts flexi_kline 0.9.0 new version

## 0.8.0
* Migrate the drawing tool to the new library
