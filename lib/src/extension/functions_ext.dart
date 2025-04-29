import 'dart:async';

/// 防抖操作时长
const defaultDebounceTime = Duration(milliseconds: 400);

/// 默认节流时长
const defaultThrottleTime = Duration(milliseconds: 200);

/// 手势操作节流时长
const gestureThrottleTime = Duration(milliseconds: 16);

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

extension FunctionExt on FutureOr<void> Function() {
  FutureOr<void> Function() get debounce {
    Timer? timer;
    return () {
      timer?.cancel();
      timer = Timer(defaultDebounceTime, call);
    };
  }

  FutureOr<void> Function() get throttle {
    Timer? timer;
    return () {
      if (timer == null || !timer!.isActive) {
        timer = Timer(defaultThrottleTime, () => timer = null);
        call();
      }
    };
  }
}

extension UnaryFunctionExt<T> on FutureOr<void> Function(T) {
  FutureOr<void> Function(T) get debounce => unaryDebounce(this);
  FutureOr<void> Function(T) debounceDelay(Duration delay) {
    return unaryDebounce(this, delay);
  }

  FutureOr<void> Function(T) get throttle => unaryThrottle(this);
  FutureOr<void> Function(T) throttleDelay(Duration delay) {
    return unaryThrottle(this, delay);
  }
}

extension BinaryFunctionExt<T1, T2> on FutureOr<void> Function(T1, T2) {
  FutureOr<void> Function(T1, T2) get debounce => binaryDebounce(this);
  FutureOr<void> Function(T1, T2) debounceDelay(Duration delay) {
    return binaryDebounce(this, delay);
  }

  FutureOr<void> Function(T1, T2) get throttle => binaryThrottle(this);
  FutureOr<void> Function(T1, T2) throttleDelay(Duration delay) {
    return binaryThrottle(this, delay);
  }
}
