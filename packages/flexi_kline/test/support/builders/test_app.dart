// Copyright 2024 Andy.Zhao
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// 测试用根应用。
///
/// 测试不依赖 Material, 根应用用 `WidgetsApp`。`home` 需要页面路由,
/// 这里只做无过渡的单页导航, 足以承载图表测试的页面。
library;

import 'package:flutter/widgets.dart';

/// 不依赖 Material 的测试根应用.
class TestApp extends WidgetsApp {
  TestApp({super.key, required super.home}) : super(color: const Color(0xFF000000), pageRouteBuilder: _pageRoute);
}

PageRoute<T> _pageRoute<T>(RouteSettings settings, WidgetBuilder builder) {
  return PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
  );
}
