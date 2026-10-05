import 'package:flutter/foundation.dart';

/// 平台判断工具（精简自 example 的 DeviceUtil，去掉 `package_info_plus` 依赖）。
final class DeviceUtil {
  DeviceUtil._();

  /// 是否 Web 平台。
  static bool get isWeb => kIsWeb;

  /// 是否 Android。
  static bool get isAndroid => !isWeb && defaultTargetPlatform == TargetPlatform.android;

  /// 是否 iOS。
  static bool get isIOS => !isWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// 是否移动端（Android / iOS）。
  static bool get isMobile => isAndroid || isIOS;
}
