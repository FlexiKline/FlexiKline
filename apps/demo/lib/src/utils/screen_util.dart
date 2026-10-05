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

import 'dart:ui' show DisplayFeatureType;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../route/route_observer.dart';
import 'device.dart';

/// 判断当前设备是否为折叠屏展开状态。
///
/// 通过 [MediaQuery.displayFeatures] 检测是否存在 [DisplayFeatureType.fold]
/// 或 [DisplayFeatureType.hinge] 类型的显示特征。
/// 折叠屏收起（使用外屏）时 displayFeatures 为空，与普通手机一致。
///
/// 仅 Android 有效，其他平台始终返回 false。
bool isFoldableUnfolded(BuildContext context) {
  final features = MediaQuery.of(context).displayFeatures;
  return features.any(
    (f) => f.type == DisplayFeatureType.fold || f.type == DisplayFeatureType.hinge,
  );
}

Future<void> setScreenLandscape() async {
  if (DeviceUtil.isWeb) return;
  if (DeviceUtil.isAndroid) {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: const <SystemUiOverlay>[SystemUiOverlay.bottom],
    );
  }
  SystemChrome.setPreferredOrientations(
    const <DeviceOrientation>[
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ],
  );
}

Future<void> setScreenPortrait() async {
  if (DeviceUtil.isWeb) return;
  if (DeviceUtil.isAndroid) {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }
  await SystemChrome.setPreferredOrientations(
    const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
      // DeviceOrientation.portraitDown
    ],
  );
}

/// 进入横屏、离开恢复，并监听路由变化以支撑「横屏页压入新页面（竖屏）后返回恢复横屏」。
///
/// 需在 `MaterialApp.navigatorObservers` 中注册 [globalRouteObserver]。
mixin ScreenLandscapeModeMixin<T extends StatefulWidget> on State<T> implements RouteAware {
  @override
  void initState() {
    super.initState();
    setScreenLandscape();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final route = ModalRoute.of(context);
        if (route is PageRoute) {
          globalRouteObserver.subscribe(this, route);
        }
      }
    });
  }

  @override
  void dispose() {
    globalRouteObserver.unsubscribe(this);
    setScreenPortrait();
    super.dispose();
  }

  /// 路由变为当前路由时调用（页面显示或从其他页面返回）
  @override
  void didPush() {
    setScreenLandscape();
  }

  /// 新路由被推入，当前路由进入后台
  @override
  void didPushNext() {
    setScreenPortrait();
  }

  /// 返回到此路由时恢复横屏
  @override
  void didPopNext() {
    setScreenLandscape();
  }

  /// 页面被弹出时恢复竖屏
  @override
  void didPop() {
    setScreenPortrait();
  }
}
