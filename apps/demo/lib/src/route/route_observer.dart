import 'package:flutter/widgets.dart';

/// 全局路由观察者，供 `ScreenLandscapeModeMixin` 监听路由变化。
///
/// 需在 `MaterialApp.navigatorObservers` 中注册（demo 已在 `MyApp` 中配置）。
final RouteObserver<PageRoute> globalRouteObserver = RouteObserver<PageRoute>();
