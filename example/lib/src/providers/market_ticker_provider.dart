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

import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/export.dart';
import '../repo/api.dart' as api;

final random = math.Random();

final marketTickerProvider =
    FutureProvider.autoDispose.family<MarketTicker?, String>(
  (ref, instId) async {
    final cancelToken = CancelToken();
    ref.onDispose(() {
      cancelToken.cancel();
    });
    final resp = await api.getMarketTicker(
      instId,
      cancelToken: cancelToken,
    );
    Future.delayed(
      Duration(milliseconds: random.nextInt(5000)),
      () => ref.invalidateSelf(),
    );
    if (resp.success) {
      ref.keepAlive();
      return resp.data;
    }
    return null;
  },
  name: 'marketTicker',
);
