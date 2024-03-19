import 'package:decimal/decimal.dart';
import 'package:kline/src/utils/log.dart';

import 'candle_model/candle_model.dart';
import 'candle_req/candle_req.dart';

class CandleData with KlineLog {
  @override
  String get logTag => 'CandleData';

  final CandleReq req;
  List<CandleModel> _list = List.empty(growable: true);

  List<CandleModel> get list => _list;
  set list(val) {
    _list = val;
    calcuateMaxMin();
  }

  Decimal max = Decimal.zero;
  Decimal min = Decimal.zero;
  Decimal get height => max - min;
  int start = 0;
  int end = 0;

  static final CandleData empty = CandleData(
    CandleReq(instId: "", bar: ""),
    List.empty(growable: true),
  );

  CandleData(this.req, List<CandleModel> list) {
    if (list.isEmpty) {
      reset();
      return;
    }
    list = List.of(list);
  }

  String get instId => req.instId;

  void reset() {
    max = Decimal.zero;
    min = Decimal.zero;
  }

  void calcuateMaxMin() {
    CandleModel m = list.first;
    max = m.high;
    min = m.low;
    for (var i = 0; i < list.length; i++) {
      m = list[i];

      if (i == 0) {
        req.after ??= m.timestamp;
      }
      if (i == list.length - 1) {
        req.before ??= m.timestamp;
      }

      max = m.high > max ? m.high : max;
      min = m.low < min ? m.low : min;
    }
  }

  /// 合并newList到list
  void mergeCandleList(List<CandleModel> newList) {
    if (newList.isEmpty) {
      logw("mergeCandleList newList is empty!");
      return;
    }
    if (list.isEmpty) {
      logw("mergeCandleList Use newList directly!");
      list = List.of(newList);
      return;
    }

    int curAfter = list.first.timestamp; // 此时间ts之前的数据
    int curBefore = list.last.timestamp; // 此时间ts之后的数据
    assert(curAfter > curBefore, "curAfter should be greater than curBefore!");

    int newAfter = newList.first.timestamp; // 此时间ts之前的数据
    int newBefore = newList.last.timestamp; // 此时间ts之后的数据
    assert(newAfter > newBefore, "newAfter should be greater than newBefore!");

    // 根据两个数组范围[after, before], 合并去重
    if (newBefore > curAfter) {
      // newList拼接到列表前面
      list = [...newList, ...list];
    } else if (newAfter < curBefore) {
      // newList拼接到列表尾部
      list = [...list, ...newList];
    } else {
      List<CandleModel> allList = [...list, ...newList];
      allList.sort((a, b) => b.timestamp - a.timestamp); // 排序
      allList = removeDuplicate(allList);
      list = allList;
      // newList在list有重叠, 需要合并. // TODO: 后续算法优化
      // int newLen = newList.length;
      // int curLen = list.length;
      // int newIndex = 0;
      // int curIndex = 0;
      // CandleModel curData;
      // while (newIndex < newLen || curIndex < curLen) {
      //   if (newIndex == newLen) curData = newList[newIndex];
      //   if (curIndex == curLen) curData = list[curIndex];
      //   if (list[curIndex].timestamp < newList[newIndex].timestamp) {
      //     curData = list[curIndex++];
      //   } else {
      //     curData = newList[newIndex++];
      //   }
      //   // list[]
      // }
    }
  }
}

List<CandleModel> removeDuplicate(List<CandleModel> list) {
  int n = list.length;
  int fast = 1;
  int slow = 1;
  while (fast < n) {
    if (list[fast].timestamp != list[fast - 1].timestamp) {
      list[slow] = list[fast];
      ++slow;
    }
    ++fast;
  }
  return list.sublist(0, slow);
}
