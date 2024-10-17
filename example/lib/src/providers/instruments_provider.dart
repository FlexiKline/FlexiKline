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

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:example/src/utils/cache_util.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/export.dart';
import '../repo/okx_api.dart' as api;

const _instrumentsCacheKey = 'instruments_cache_key';

final instrumentsMgrProvider =
    StateNotifierProvider<InstrumentsManagerNotifier, Map<String, Instrument>>(
  (ref) {
    final list = CacheUtil().getModelList(
      _instrumentsCacheKey,
      Instrument.fromJson,
    );
    Map<String, Instrument> initVal;
    if (list != null && list.isNotEmpty) {
      initVal = {for (var e in list) e.instId: e};
    } else {
      initVal = <String, Instrument>{};
    }
    return InstrumentsManagerNotifier(ref, initVal);
  },
  name: '_instrumentsManager',
);

class InstrumentsManagerNotifier
    extends StateNotifier<Map<String, Instrument>> {
  InstrumentsManagerNotifier(
    this.ref,
    Map<String, Instrument> initVal,
  ) : super(initVal);
  final Ref ref;

  CancelToken? cancelToken;
  @override
  void dispose() {
    cancelToken?.cancel();
    super.dispose();
  }

  Future<void> loadInstruments({String instType = 'SPOT'}) async {
    cancelToken = CancelToken();
    final resp = await api.getInstrumentList(
      instType: instType,
      cancelToken: cancelToken,
    );
    if (resp.success && resp.data != null && resp.data!.isNotEmpty) {
      CacheUtil().set(_instrumentsCacheKey, jsonEncode(resp.data!));
      state = {for (var e in resp.data!) e.instId: e};
    }
  }

  Instrument? getInst(String instId) => state[instId];

  int? getPrecision(String instId) => getInst(instId)?.precision;
}

final instrumentProvider =
    StateProvider.autoDispose.family<Instrument?, String>(
  (ref, instId) => ref.watch(
    instrumentsMgrProvider.select((map) => map[instId]),
  ),
  name: 'instrument',
);
