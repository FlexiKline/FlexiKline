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

part of 'candle_model.dart';

final class CalculateData {
  CalculateData._(this.dataList);

  factory CalculateData.init(
    int indicatorCount,
  ) {
    return CalculateData._(List.filled(indicatorCount, null, growable: false));
  }

  final List<Object?> dataList;

  T? getData<T>(int index) {
    final obj = dataList.getItem(index);
    return obj is T ? obj : null;
  }

  bool setData<T>(int index, T data) {
    if (!dataList.checkIndex(index)) return false;
    dataList[index] = data;
    return true;
  }
}

extension CandleModelExt on CandleModel {
  DateTime get dateTime {
    return DateTime.fromMillisecondsSinceEpoch(ts);
  }

  String formatDateTime(TimeBar? bar) {
    return dateTime.formatByUnit(bar?.unit);
  }

  DateTime? nextUpdateDateTime(String bar) {
    final timeBar = TimeBar.convert(bar);
    if (timeBar != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        ts + timeBar.milliseconds,
        isUtc: timeBar.isUtc,
      );
    }
    return null;
  }

  bool get isLong => close >= open;

  Decimal get change => c - o;

  double get changeRate {
    if (change == Decimal.zero) return 0;
    return (change / o).toDouble();
  }

  Decimal get range => h - l;

  double rangeRate(CandleModel pre) {
    if (range == Decimal.zero) return 0;
    return (range / pre.c).toDouble();
  }

  CandleModel clone() {
    return CandleModel.fromJson(toJson());
  }
}
