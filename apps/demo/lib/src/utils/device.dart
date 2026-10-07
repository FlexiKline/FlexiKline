import 'package:flutter/foundation.dart';

/// 平台判断工具（不依赖 `package_info_plus`）。
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
