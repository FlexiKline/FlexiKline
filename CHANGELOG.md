## 2.0.0
* Replace BagNum with FlexiNum for numeric representation (Breaking Changes).
* Introduce ICandleModel interface and FlexiCandleModel; unify candle model to support custom models (Breaking Changes).
* Refactor Indicator to generic class with typed key system: IIndicatorKey sealed class with DataIndicatorKey, BusinessIndicatorKey and NormalIndicatorKey subtypes (Breaking Changes).
* Split PaintObjectIndicator into DataIndicator and BusinessIndicator with corresponding DataPaintObject and BusinessPaintObject (Breaking Changes).
* Refactor paint object interfaces: rename IPaintBoundingBox to IPaintBounding, introduce IBasePainter/IComputablePainter/IBusinessPainter, add PaintObjectComputableMixin (Breaking Changes).
* Change PaintObject initialization to lazy pattern; remove context and indicator from constructors (Breaking Changes).
* Deprecate TimeBar enum and unify with ITimeBar (Breaking Changes).
* Rename supportLongPress to enableLongPress in GestureConfig (Breaking Changes).
* Add enableScale property to GestureConfig to allow disabling scale/zoom gestures.
* Resolve two-finger zoom gesture conflicts and optimize zoom experience.
* Add Y-axis smooth interpolation during pan to reduce coordinate jumps.
* Add panSmoothFactor and convergenceRatio to ToleranceConfig for configurable smoothing.
* Update inertial pan duration formula from log to sqrt for better velocity-to-duration mapping.

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
