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

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

final class DeviceUtil {
  DeviceUtil._();

  /// 是否触摸设备
  static bool get isTouch => isTargetMobile;

  /// 是否非触摸设备
  static bool get isNonTouch => !isTargetMobile;

  static bool get isDesktop => !isWeb && (isWindows || isLinux || isMacOS);

  static bool get isMobile => isAndroid || isIOS;

  static bool get isWeb => kIsWeb;

  static bool get isWindows => isWeb ? false : Platform.isWindows;

  static bool get isLinux => isWeb ? false : Platform.isLinux;

  static bool get isMacOS => isWeb ? false : Platform.isMacOS;

  static bool get isAndroid => isWeb ? false : Platform.isAndroid;

  static bool get isFuchsia => isWeb ? false : Platform.isFuchsia;

  static bool get isIOS => isWeb ? false : Platform.isIOS;

  static bool get isTargetMobile =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  static Future<PackageInfo> getPackageInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo;
  }

  static Future<String> appName() async {
    PackageInfo packageInfo = await getPackageInfo();
    return packageInfo.appName;
  }

  static Future<String> packageName() async {
    PackageInfo packageInfo = await getPackageInfo();
    return packageInfo.packageName;
  }

  static Future<String> version() async {
    PackageInfo packageInfo = await getPackageInfo();
    return packageInfo.version;
  }

  static Future<String> buildNumber() async {
    PackageInfo packageInfo = await getPackageInfo();
    return packageInfo.buildNumber;
  }

  static Future<String> buildSignature() async {
    PackageInfo packageInfo = await getPackageInfo();
    return packageInfo.buildSignature;
  }

  static Future<String?> installerStore() async {
    PackageInfo packageInfo = await getPackageInfo();
    return packageInfo.installerStore;
  }
}
