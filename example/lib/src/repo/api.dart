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

import 'package:dio/dio.dart';
import 'package:flexi_kline/flexi_kline.dart';

import '../models/export.dart';
import 'http_client.dart';

List<CandleModel> dataToCandleList(dynamic data) {
  if (data is List<dynamic> && data.isNotEmpty) {
    final list = List<CandleModel>.empty(growable: true);
    for (var json in data) {
      final m = CandleModel.fromList(json);
      if (m != null) list.add(m);
    }
    return list;
  }
  return const [];
}

/// 获取K线数据。K线数据按请求的粒度分组返回，K线数据每个粒度最多可获取最近1,440条。
Future<ApiResult<List<CandleModel>>> getMarketCandles(
  CandleReq req, {
  CancelToken? cancelToken,
}) {
  return httpClient.request(
    '/api/v5/market/candles',
    dataToCandleList,
    method: HttpMethod.get,
    queryParameters: req.toJson(),
    cancelToken: cancelToken,
  );
}

/// 获取最近几年的历史k线数据(1s k线支持查询最近3个月的数据)
Future<ApiResult<List<CandleModel>>> getHistoryCandles(
  CandleReq req, {
  CancelToken? cancelToken,
}) {
  return httpClient.request(
    '/api/v5/market/history-candles',
    dataToCandleList,
    method: HttpMethod.get,
    queryParameters: req.toJson(),
    cancelToken: cancelToken,
  );
}

/// GET / 获取所有产品行情信息
Future<ApiResult<List<MarketTicker>>> getMarketTickerList({
  CancelToken? cancelToken,
}) {
  return httpClient.getList(
    '/api/v5/market/tickers',
    MarketTicker.fromJson,
    cancelToken: cancelToken,
  );
}

/// GET / 获取单个产品行情信息
Future<ApiResult<MarketTicker>> getMarketTicker(
  String instId, {
  CancelToken? cancelToken,
}) {
  return httpClient
      .getList(
        '/api/v5/market/ticker',
        MarketTicker.fromJson,
        queryParameters: {"instId": instId},
        cancelToken: cancelToken,
      )
      .then(
        (result) => ApiResult(
          code: result.code,
          msg: result.msg,
          data: result.data?.firstOrNull,
          success: result.success,
        ),
      );
}
