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

import 'framework/configuration.dart';
import 'kline_controller.dart';
import 'model/candle_req/candle_req.dart';
import 'model/time_bar.dart';

/// 计算模式
/// [fast] 使用(IEEE 754 二进制浮点数算术标准)计算指标数据. (用double类型计算)
/// [accurate] 使用Decimal基于十进制算术的精确计算指标数据. (用Decimal类型计算)
enum ComputeMode {
  fast,
  accurate,
}

/// 内置TooltipLabel
enum TooltipLabel {
  time,
  open,
  high,
  low,
  close,
  chg,
  chgRate,
  range,
  amount,
  turnover;
}

/// 按[timeBar]格式化时间[dateTime]
typedef DateTimeFormatter = String Function(DateTime dateTime, [ITimeBar? timeBar]);

/// 更新器函数类型
/// [current] 当前值, 返回更新后的值
typedef FlexiUpdater<T> = T Function(T current);

/// Kline数据中心接口抽象类
abstract interface class IFlexiKlineDataCenter {
  /// 请求参数
  CandleReq createRequest();

  /// 创建FlexiKline配置
  IConfiguration createFlexiKlineConfig();

  /// 创建FlexiKline控制器
  FlexiKlineController createFlexiKlineController();

  /// 刷新当前KlineController的K线数据
  /// @param [reset] 是否重置当前KlineData所有数据
  Future<void> refreshKlineData({bool reset = false});

  /// 加载更多当前KlineController的K线数据
  /// @param [request] 请求参数
  Future<void> loadMoreCandles(CandleReq request);
}
