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

part of 'kline_data.dart';

extension RequestData on BaseData {
  String get instId => req.instId;
  int get precision => req.precision;
  String get key => req.key;
  String get reqKey => req.reqKey;
  TimeBar? get timeBar => req.timeBar;
  bool get invalid => req.instId.isEmpty;

  CandleReq updateState({RequestState state = RequestState.none}) {
    req = req.copyWith(
      after: list.lastOrNull?.ts,
      before: list.firstOrNull?.ts,
      state: state,
    );
    return req;
  }

  CandleReq getLoadMoreRequest() {
    return req.copyWith(
      after: list.lastOrNull?.ts,
      before: null,
    );
  }

  CandleReq getRefreshRequest([bool isRest = false]) {
    if (isEmpty || isRest) {
      return req.copyWith(after: null, before: null);
    }
    final model = list.secondWhereOrNull((m) => m.calcuData.dataList.hasValidData);
    return req.copyWith(
      after: null,
      before: model?.ts,
    );
  }
}
