import 'dart:math' as math;

import 'package:decimal/decimal.dart';
import 'package:kline/src/utils/log.dart';

import '../model/export.dart';

/// 蜡烛图相关数据
class CandleData with KlineLog {
  @override
  String get logTag => 'CandleData';

  CandleData(this.req, List<CandleModel> list) {
    if (list.isEmpty) {
      reset();
      return;
    }
    list = List.of(list);
  }

  static final CandleData empty = CandleData(
    CandleReq(instId: "", bar: ""),
    List.empty(growable: true),
  );

  final CandleReq req;
  List<CandleModel> _list = List.empty(growable: true);

  List<CandleModel> get list => _list;

  CandleModel? get latest => list.firstOrNull;

  Decimal max = Decimal.zero;
  Decimal min = Decimal.zero;
  Decimal get dataHeight => max - min;

  /// 当前绘制区域起始下标 右
  int _start = 0;
  int get start => _start;
  set start(int val) {
    _start = val.clamp(0, list.length);
  }

  /// 当前绘制区域结束下标 左
  int _end = 0;
  int get end => _end;
  set end(int val) {
    _end = val.clamp(0, list.length);
  }

  double offset = 0;
  CandleModel? startModel;
  CandleModel? endModel;

  String get instId => req.instId;

  void debugPrintDrawParams(String tag) {
    logd(
      'DrawParams>$tag [${req.instId}-${req.bar}] > len:${list.length} start:$start, end:$end, offset:$offset, max:$max, min:$min',
    );
  }

  void reset() {
    list.clear();
    max = Decimal.zero;
    min = Decimal.zero;
    offset = 0;
    start = 0;
    end = 0;
    startModel = null;
    endModel = null;
  }

  /// 根据[start, end]下标计算最大最小值
  void calculateMaxmin() {
    if (list.isEmpty) return;
    CandleModel m = list[start];
    max = m.high;
    min = m.low;
    for (var i = start; i < end; i++) {
      m = list[i];

      if (i == 0) {
        startModel = m;
        // req.after ??= m.timestamp;
      }
      if (i == list.length - 1) {
        endModel = m;
        // req.before ??= m.timestamp;
      }

      max = m.high > max ? m.high : max;
      min = m.low < min ? m.low : min;
    }
  }

  void calculateIndex(
    double paintDxOffset,
    double candleWidth,
  ) {
    start = (paintDxOffset / candleWidth).floor();
    offset = paintDxOffset % candleWidth;
    end = list.length - 1;
    logd('calculateIndex [$start, $end] offset$offset');
  }

  /// 确保绘制区域的startEnd值已初始化并有效
  void ensureDrawScope(
    int maxCandleCount,
    double candleWidth,
    double canvasWidth, // 暂无用
  ) {
    if (list.isEmpty) {
      reset();
      return;
    }

    int len = list.length;
    if (len < maxCandleCount || end == 0) {
      // 不足一屏; 或者被重置了;
      start = 0;
      end = math.min(len, maxCandleCount);
      offset = (math.max(0, maxCandleCount - len)) * candleWidth; // 右边偏移量.
    } else {
      offset = 0;
      start = 0;
      end = maxCandleCount;
      // 满一屏
      //? ceil() ? floor()
      // int candleNums = ((canvasWidth - offset) / candleWidth).floor();

      // int curLen = start - end;
      // if (curLen < candleNums) {
      //   end = start + candleNums;
      // }
    }
  }

  /// 计算当前绘制区域的最大最小值
  void calculateDrawParams(
    int maxCandleCount,
    double candleWidth,
    double canvasWidth, // 暂无用
  ) {
    debugPrintDrawParams('before');

    ensureDrawScope(
      maxCandleCount,
      candleWidth,
      canvasWidth,
    );

    calculateMaxmin();

    debugPrintDrawParams('after');
  }

  /// 合并newList到list
  void mergeCandleList(
    List<CandleModel> newList, {
    bool replace = false,
  }) {
    if (newList.isEmpty) {
      logw("mergeCandleList newList is empty!");
      return;
    }
    if (list.isEmpty || replace) {
      logw("mergeCandleList Use newList directly! $replace");
      _list = List.of(newList);
      return;
    }

    int curAfter = list.first.timestamp; // 此时间ts之前的数据
    int curBefore = list.last.timestamp; // 此时间ts之后的数据
    assert(
      curAfter >= curBefore,
      "curAfter($curAfter) should be greater than curBefore($curBefore)!",
    );

    int newAfter = newList.first.timestamp; // 此时间ts之前的数据
    int newBefore = newList.last.timestamp; // 此时间ts之后的数据
    assert(
      newAfter >= newBefore,
      "newAfter($newAfter) should be greater than newBefore($newBefore)!",
    );

    // 根据两个数组范围[after, before], 合并去重
    if (newBefore > curAfter) {
      // newList拼接到列表前面
      _list = [...newList, ...list];
    } else if (newAfter < curBefore) {
      // newList拼接到列表尾部
      _list = [...list, ...newList];
    } else {
      List<CandleModel> allList = [...list, ...newList];
      allList.sort((a, b) => b.timestamp - a.timestamp); // 排序
      allList = removeDuplicate(allList);
      _list = allList;
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
