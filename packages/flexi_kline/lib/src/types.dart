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

import 'kline_controller.dart';
import 'model/kline_spec/kline_spec.dart';
import 'model/time_interval.dart';

/// 计算模式: 蜡烛与指标的数值类型.
///
/// [fast] 用 double, 默认. 精度是相对的(约 15~16 位有效数字), 1e-17 量级的价格同样适用, 速度远快于 [accurate].
///
/// [accurate] 用 Decimal, 用于结果要与交易所或后端逐位一致、整数累计量可能超过 2^53、
/// 或取整边界不能有 `0.30000000000000004` 这类尾数.
/// 限制: 无限小数的除法按 `FlexiFormatter.scaleOnInfinitePrecision` 位**小数**截断(默认 17), 价格低于 1e-15 时
/// 需先调小 `FlexiFormatter.setGlobalConfig(exponentMinDecimal: ...)`; 开方等运算(如 BOLL 标准差)仍是 double 精度.
@Deprecated('Will be removed in 2.8.0 together with FlexiNum; all values will use double.')
enum ComputeMode { fast, accurate }

/// 内置TooltipLabel
enum TooltipLabel { time, open, high, low, close, chg, chgRate, range, amount, turnover }

/// 按[interval]格式化时间[dateTime]
typedef DateTimeFormatter = String Function(DateTime dateTime, [ITimeInterval? interval]);

/// 更新器函数类型
/// [current] 当前值, 返回更新后的值
typedef FlexiUpdater<T> = T Function(T current);

/// Kline数据中心接口抽象类
abstract interface class IFlexiKlineDataCenter {
  /// 创建 KlineSpec, 在品种或周期变更时调用
  KlineSpec createKlineSpec([KlineSpec? last]);

  /// 创建FlexiKline控制器
  FlexiKlineController createFlexiKlineController();

  /// 刷新K线数据; [reset] 为 true 时清空已有数据重新加载
  Future<void> refreshKlineData({bool reset = false});

  /// 加载更多K线数据
  Future<void> loadMoreCandles(KlineSpec spec);
}
