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

import 'http_client.dart';

extension ListExt<T> on List<T> {
  T? get(int index) => (index >= 0 && index < length) ? this[index] : null;
}

CandleModel jsonToCandle(dynamic data) {
  if (data is List<dynamic>) {
    return CandleModel.fromJson({
      "timestamp": data.get(0),
      "open": data.get(1),
      "high": data.get(2),
      "low": data.get(3),
      "close": data.get(4),
      "vol": data.get(5),
      "volCcy": data.get(6),
      "volCcyQuote": data.get(7),
      "confirm": data.get(8),
    });
  } else {
    return CandleModel.fromJson(data);
  }
}

Future<ApiResult<List<CandleModel>>> getHistoryCandles(
  CandleReq req, {
  CancelToken? cancelToken,
}) {
  return httpClient.getList(
    '/api/v5/market/history-candles',
    jsonToCandle,
    queryParameters: req.toJson(),
    cancelToken: cancelToken,
  );
}
