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

import 'package:flutter/scheduler.dart';

/// 防抖操作时长
const defaultDebounceTime = Duration(milliseconds: 320);

/// 默认节流时长
const defaultThrottleTime = Duration(milliseconds: 200);

/// 获取当前设备刷新率
double? _currentFps;
double get currentFps {
  return _currentFps ??=
      SchedulerBinding.instance.platformDispatcher.views.first.display.refreshRate;
}

/// 当前设备帧刷新率间隔
Duration? _refreshInerval;
Duration get refreshInterval {
  return _refreshInerval ??= Duration(microseconds: (1e6 / currentFps).round());
}

/// 防抖
/// 避免高频事件的重复触发，通常用于用户主动触发的场景，需要等待用户停止操作后再执行逻辑。
/// [delay] 指定时长
FutureOr<void> Function() debounce(
  FutureOr<void> Function() func, [
  Duration delay = defaultDebounceTime,
]) {
  Timer? timer;
  return () {
    timer?.cancel();
    timer = Timer(delay, func);
  };
}

FutureOr<void> Function(T) unaryDebounce<T>(
  FutureOr<void> Function(T) func, [
  Duration delay = defaultDebounceTime,
]) {
  Timer? timer;
  return (arg) {
    timer?.cancel();
    timer = Timer(delay, () => func(arg));
  };
}

FutureOr<void> Function(T1, T2) binaryDebounce<T1, T2>(
  FutureOr<void> Function(T1, T2) func, [
  Duration delay = defaultDebounceTime,
]) {
  Timer? timer;
  return (arg1, arg2) {
    timer?.cancel();
    timer = Timer(delay, () => func(arg1, arg2));
  };
}

FutureOr<void> Function(T1, T2, T3) tripleDebounce<T1, T2, T3>(
  FutureOr<void> Function(T1, T2, T3) func, [
  Duration delay = defaultDebounceTime,
]) {
  Timer? timer;
  return (arg1, arg2, arg3) {
    timer?.cancel();
    timer = Timer(delay, () => func(arg1, arg2, arg3));
  };
}

/// 节流
/// 节流的目的是 固定时间间隔内只允许一次有效触发，通常用于高频事件（如滚动、拖拽）的性能优化。
/// [delay] 指定时长
FutureOr<void> Function() throttle(
  FutureOr<void> Function() func, [
  Duration delay = defaultThrottleTime,
]) {
  Timer? timer;
  return () {
    if (timer == null || !timer!.isActive) {
      timer = Timer(delay, () => timer = null);
      func();
    }
  };
}

FutureOr<void> Function(T) unaryThrottle<T>(
  FutureOr<void> Function(T) func, [
  Duration delay = defaultThrottleTime,
]) {
  Timer? timer;
  T? latest;
  void callback(arg) {
    if (timer == null || !timer!.isActive) {
      latest = null;
      timer = Timer(delay, () {
        timer = null;
        if (latest != null) {
          callback(latest as T);
        }
      });
      func(arg);
    } else {
      latest = arg;
    }
  }

  return callback;
}

FutureOr<void> Function(T1, T2) binaryThrottle<T1, T2>(
  FutureOr<void> Function(T1, T2) func, [
  Duration delay = defaultThrottleTime,
]) {
  Timer? timer;
  (T1, T2)? latest;
  void callback(arg1, arg2) {
    if (timer == null || !timer!.isActive) {
      latest = null;
      timer = Timer(delay, () {
        timer = null;
        if (latest != null) {
          callback(latest!.$1, latest!.$2);
        }
      });
      func(arg1, arg2);
    } else {
      latest = (arg1, arg2);
    }
  }

  return callback;
}

FutureOr<void> Function(T1, T2, T3) tripleThrottle<T1, T2, T3>(
  FutureOr<void> Function(T1, T2, T3) func, [
  Duration delay = defaultThrottleTime,
]) {
  Timer? timer;
  (T1, T2, T3)? latest;
  void callback(arg1, arg2, arg3) {
    if (timer == null || !timer!.isActive) {
      latest = null;
      timer = Timer(delay, () {
        timer = null;
        if (latest != null) {
          callback(latest!.$1, latest!.$2, latest!.$3);
        }
      });
      func(arg1, arg2, arg3);
    } else {
      latest = (arg1, arg2, arg3);
    }
  }

  return callback;
}

extension FlexiKlineFunctionExt on FutureOr<void> Function() {
  FutureOr<void> Function() debounce([Duration delay = defaultDebounceTime]) {
    Timer? timer;
    return () {
      timer?.cancel();
      timer = Timer(delay, call);
    };
  }

  FutureOr<void> Function() throttle([Duration delay = defaultThrottleTime]) {
    Timer? timer;
    return () {
      if (timer == null || !timer!.isActive) {
        timer = Timer(delay, () => timer = null);
        call();
      }
    };
  }

  FutureOr<void> Function() get throttleOnFps {
    Timer? timer;
    return () {
      if (timer == null || !timer!.isActive) {
        timer = Timer(refreshInterval, () => timer = null);
        call();
      }
    };
  }
}

extension FlexiKlineUnaryFunctionExt<T> on FutureOr<void> Function(T) {
  FutureOr<void> Function(T) debounce([Duration delay = defaultDebounceTime]) {
    return unaryDebounce(this, delay);
  }

  FutureOr<void> Function(T) get throttleOnFps => unaryThrottle(this, refreshInterval);
  FutureOr<void> Function(T) throttle([Duration delay = defaultThrottleTime]) {
    return unaryThrottle(this, delay);
  }
}

extension FlexiKlineBinaryFunctionExt<T1, T2> on FutureOr<void> Function(T1, T2) {
  FutureOr<void> Function(T1, T2) debounce([Duration delay = defaultDebounceTime]) {
    return binaryDebounce(this, delay);
  }

  FutureOr<void> Function(T1, T2) get throttleOnFps => binaryThrottle(this, refreshInterval);
  FutureOr<void> Function(T1, T2) throttle([Duration delay = defaultThrottleTime]) {
    return binaryThrottle(this, delay);
  }
}

extension FlexiKlineTripleFunctionExt<T1, T2, T3> on FutureOr<void> Function(T1, T2, T3) {
  FutureOr<void> Function(T1, T2, T3) debounce([Duration delay = defaultDebounceTime]) {
    return tripleDebounce(this, delay);
  }

  FutureOr<void> Function(T1, T2, T3) get throttleOnFps => tripleThrottle(this, refreshInterval);
  FutureOr<void> Function(T1, T2, T3) throttle([Duration delay = defaultThrottleTime]) {
    return tripleThrottle(this, delay);
  }
}
