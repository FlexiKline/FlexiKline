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

import 'package:flutter/material.dart';

import '../config/export.dart';

abstract interface class IFlexiKlineTheme {
  /// 缓存Key
  late String key;

  /// 实际尺寸与UI设计的比例
  double get scale;

  /// 一个像素的值
  double get pixel;

  ///根据宽度或高度中的较小值进行适配
  /// - [size] UI设计上的尺寸大小, 单位dp.
  double setPt(num size);

  //字体大小适配方法
  ///- [fontSize] UI设计上字体的大小,单位dp.
  double setSp(num fontSize);

  /// 涨跌颜色
  late Color long;
  late Color short;

  // 背景色
  late Color markBg;
  late Color cardBg;
  late Color disable;
  late Color lightBg;
  late Color transparent;
  late Color translucentBg;

  /// 分隔线
  late Color dividerLine;

  /// 文本颜色配置
  late Color t1;
  late Color t2;
  late Color t3;
  late Color tlight;
}

abstract interface class IConfiguration {
  /// FlexiKline初始或默认的主区的宽高.
  Size get initialMainSize;

  /// FlexiKline初始配置.
  FlexiKlineConfig getInitialFlexiKlineConfig();

  /// 保存[config]配置信息到本地; 通过FlexiKlineController调用.
  void saveFlexiKlineConfig(FlexiKlineConfig config);
}
