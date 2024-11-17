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

part of 'indicator.dart';

/// [PaintObject]管理
/// 主要负责:
/// 1. 初始加载Kline时从配置中根据Indicator配置实例化[PaintObject].
/// 2. 将当前Kline的PaintObject关联Indicator持久化到本地
/// 3. 为ChartController提供待绘制的[PaintObject]列表.
/// 4. 管理主区与副区[PaintObject]的顺序/切换/更新/
/// 5. 管理所有[Indicator]配置, 当发生更新时重建[PaintObject]
/// 6. 提供定制[Indicator]的定制功能
final class IndicatorPaintObjectManager with KlineLog {
  IndicatorPaintObjectManager({
    required this.configuration,
    ILogger? logger,
  }) {
    loggerDelegate = logger;
  }

  final IConfiguration configuration;

  @override
  String get logTag => 'IndicatorPaintObjectManager';
}
