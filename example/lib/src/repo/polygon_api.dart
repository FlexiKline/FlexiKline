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

import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flexi_kline/flexi_kline.dart';

import '../models/export.dart';
import 'http_client.dart';

late final HttpClient polygonHttpClient;

void initPolygonHttpClient({
  String baseUrl = "https://api.polygon.io",
  String? apiKey,
}) {
  final initHeaders = <String, dynamic>{};
  if (apiKey != null) {
    initHeaders['Authorization'] = 'Bearer $apiKey';
  }
  polygonHttpClient = HttpClient(
    baseUrl: baseUrl,
    headers: initHeaders,
    responseConvertor: _convertToPolygonApiResult,
  );
}

ApiResult<T> _convertToPolygonApiResult<T>(
  RequestOptions options,
  dynamic respData,
  DataConvert<T> convert,
) {
  final code = respData['status'];
  final msg = respData['error'] ?? '';
  final success = code == 'DELAYED' || code == 'OK' || code == 'ok';
  String dataKey = 'results';
  if (success) {
    return ApiResult(
      code: '$code',
      msg: msg,
      success: success,
      data: convert(respData[dataKey]),
      extra: respData,
    );
  } else {
    return ApiResult(
      code: '$code',
      msg: msg,
      success: success,
      data: null,
      extra: respData,
    );
  }
}

List<CandleModel> _dataToCandleList(dynamic data) {
  if (data is List<dynamic> && data.isNotEmpty) {
    final list = List<CandleModel>.empty(growable: true);
    for (int i = data.length - 1; i >= 0; i--) {
      final json = data[i];
      list.add(CandleModel(
        ts: json['t'],
        o: Decimal.parse(json['o'].toString()),
        h: Decimal.parse(json['h'].toString()),
        l: Decimal.parse(json['l'].toString()),
        c: Decimal.parse(json['c'].toString()),
        v: Decimal.parse(json['n'].toString()),
        vc: Decimal.parse(json['v'].toString()),
        vcq: Decimal.parse(json['vw'].toString()),
      ));
    }
    return list;
  }
  return const [];
}

Future<ApiResult<List<CandleModel>>> getHistoryKlineData(
  CandleReq req, {
  CancelToken? cancelToken,
}) {
  final stocksTicker = req.instId;
  final multiplier = req.timeBar?.multiplier;
  final timespan = req.timeBar?.timespan.name;
  final from = req.after;
  final to = req.before;
  return polygonHttpClient.request(
    '/v2/aggs/ticker/$stocksTicker/range/$multiplier/$timespan/$from/$to',
    _dataToCandleList,
    method: HttpMethod.get,
    queryParameters: {},
    cancelToken: cancelToken,
  );
}

Future<ApiResult<List<StockTicker>>> getStockTickerList({
  String searchTxt = '',
  CancelToken? cancelToken,
}) {
  return polygonHttpClient.getList(
    '/v3/reference/tickers?active=true&limit=100',
    StockTicker.fromJson,
    queryParameters: {"search": searchTxt},
    cancelToken: cancelToken,
  );
}
