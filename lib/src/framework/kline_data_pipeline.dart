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

library;

import 'dart:async';
import 'dart:collection';

import '../data/kline_data.dart';
import '../model/export.dart';
import 'chart/indicator.dart' show IndicatorCalculator, IndicatorPaintObjectManager;
import 'logger.dart';

enum _PipelinePhase { idle, merging, computing }

enum _UpdateKind { replace, updateLatest, appendHistory }

/// 串行编排蜡烛合并与指标计算，并按固定节拍计算 latest 更新.
final class KlineDataPipeline with FlexiLog {
  KlineDataPipeline(
    this.data,
    this.manager, {
    required this.onCandlesMerged,
    required this.onComputed,
    this.interval = const Duration(milliseconds: 500),
    Duration Function()? elapsed,
    IFlexiLogger? logger,
  }) : _elapsed = elapsed {
    if (interval <= Duration.zero) {
      throw ArgumentError.value(interval, 'interval', 'must be greater than zero');
    }
    this.logger = logger;
  }

  @override
  String get logTag => 'KlineDataPipeline';

  final KlineData data;
  final IndicatorPaintObjectManager manager;
  final void Function({required bool replace}) onCandlesMerged;
  final void Function() onComputed;
  final Duration interval;
  final Duration Function()? _elapsed;

  final Queue<({List<ICandleModel> batch, _UpdateKind kind, bool allowUrgent})> _pending = Queue();
  final Set<IndicatorCalculator> _requested = {};
  final Stopwatch _clock = Stopwatch();

  _PipelinePhase _phase = _PipelinePhase.idle;
  Range? _dirty;
  Timer? _timer;
  Duration _nextTick = Duration.zero;
  bool _urgent = false;
  bool _retryPending = false;
  bool _deferredTick = false;
  bool _started = false;
  bool _disposed = false;

  void start() {
    if (_started || _disposed) return;
    _started = true;
    _clock.start();
    _nextTick = interval;
    _drainPending();
    if (_urgent) _tryCompute();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _clock.stop();
    _pending.clear();
    _requested.clear();
    _dirty = null;
    _urgent = false;
    _retryPending = false;
    _deferredTick = false;
    _started = false;
  }

  void replace(List<ICandleModel> batch) => _enqueue(batch, _UpdateKind.replace);

  void updateLatest(List<ICandleModel> batch) => _enqueue(batch, _UpdateKind.updateLatest);

  void appendHistory(List<ICandleModel> batch) => _enqueue(batch, _UpdateKind.appendHistory);

  /// 请求当前数据全部指标立即重算.
  void invalidateAll() {
    if (_disposed) return;
    _dirty = Range.fullRecompute;
    _urgent = true;
    if (_started && _phase == _PipelinePhase.idle) _tryCompute();
  }

  /// 请求一个指标立即全量重算.
  void recompute(IndicatorCalculator calculator) {
    if (_disposed) return;
    _requested.add(calculator);
    _urgent = true;
    if (_started && _phase == _PipelinePhase.idle) _tryCompute();
  }

  void _enqueue(List<ICandleModel> batch, _UpdateKind kind) {
    if (_disposed || batch.isEmpty) return;
    if (_timer == null && _dirty == null && !_urgent) {
      _advanceTick();
    }
    _pending.addLast((
      batch: List<ICandleModel>.of(batch, growable: false),
      kind: kind,
      allowUrgent: _phase != _PipelinePhase.computing,
    ));
    if (_started && _phase == _PipelinePhase.idle) _drainPending();
  }

  void _drainPending() {
    if (!_started || _disposed || _phase != _PipelinePhase.idle || _pending.isEmpty) return;
    _phase = _PipelinePhase.merging;
    try {
      while (_pending.isNotEmpty) {
        final update = _pending.removeFirst();
        final previousLatestTs = data.latest?.ts;
        final previousLength = data.length;
        final stopwatch = Stopwatch()..start();
        Range? range;
        try {
          range = switch (update.kind) {
            _UpdateKind.replace => data.replace(update.batch, slotCount: manager.computedDataCapacity),
            _UpdateKind.updateLatest => data.updateLatest(update.batch, slotCount: manager.computedDataCapacity),
            _UpdateKind.appendHistory => data.appendHistory(update.batch, slotCount: manager.computedDataCapacity),
          };
          stopwatch.stop();
        } catch (error, stackTrace) {
          stopwatch.stop();
          loge(
            'Merge failed::: kind:${update.kind.name} key:${data.key} candles:${update.batch.length} '
            'spent:${stopwatch.elapsedMicroseconds}μs',
            error: error,
            stackTrace: stackTrace,
          );
          rethrow;
        }
        if (range == null) {
          logw(
            'Merge dropped::: kind:${update.kind.name} key:${data.key} candles:${update.batch.length} '
            'spent:${stopwatch.elapsedMicroseconds}μs',
          );
          continue;
        }
        if (update.kind != _UpdateKind.updateLatest) {
          logd(
            'Merge::: kind:${update.kind.name} key:${data.key} candles:${update.batch.length} range:$range '
            'spent:${stopwatch.elapsedMicroseconds}μs',
          );
        }
        final recoveryPending = _retryPending || _dirty?.requiresFullRecompute == true || _requested.isNotEmpty;
        // updateLatest 在头部插入新蜡烛时，存量索引整体后移；已累积的 _dirty 仍是旧坐标，
        // 需按插入数量平移后再合并，否则被弄脏但已移位的蜡烛会落在新 range 之外而漏算。
        if (update.kind == _UpdateKind.updateLatest && _dirty != null && !_dirty!.requiresFullRecompute) {
          final delta = data.length - previousLength;
          if (delta > 0) {
            _dirty = Range(_dirty!.start + delta, _dirty!.end + delta);
          }
        }
        _dirty = _mergeRange(_dirty, range);
        final insertedLatest =
            update.kind == _UpdateKind.updateLatest && previousLatestTs != null && data.latest!.ts > previousLatestTs;
        if (update.kind != _UpdateKind.updateLatest || (insertedLatest && update.allowUrgent && !recoveryPending)) {
          _urgent = true;
        }
        onCandlesMerged(replace: update.kind == _UpdateKind.replace);
      }
    } finally {
      _phase = _PipelinePhase.idle;
    }

    if (!_urgent && _dirty != null && _nextTick <= _elapsedNow) {
      _deferredTick = true;
      _nextTick += interval;
      _advanceTick();
    }

    if (_urgent || _deferredTick) {
      _deferredTick = false;
      _tryCompute();
    } else {
      _scheduleTick();
    }
  }

  Range _mergeRange(Range? current, Range next) {
    if (current == null) return next;
    if (current.requiresFullRecompute || next.requiresFullRecompute) return Range.fullRecompute;
    return current.merge(next);
  }

  void _onTick() {
    if (_disposed) return;
    _timer = null;
    _nextTick += interval;
    if (_phase == _PipelinePhase.computing) {
      _scheduleTick();
      return;
    }
    if (_phase == _PipelinePhase.merging) {
      _deferredTick = true;
      return;
    }
    _drainPending();
    _tryCompute();
    _scheduleTick();
  }

  void _tryCompute() {
    if (!_started || _disposed || _phase != _PipelinePhase.idle) return;
    _requested.removeWhere(
      (calculator) => !identical(manager.getCalculator(calculator.indicator.key), calculator),
    );
    final dirty = _dirty;
    if (dirty == null && _requested.isEmpty) {
      _urgent = false;
      _retryPending = false;
      return;
    }

    _timer?.cancel();
    _timer = null;
    _phase = _PipelinePhase.computing;
    _urgent = false;
    final requested = Set<IndicatorCalculator>.of(_requested);
    final stopwatch = Stopwatch()..start();
    var calculatorCount = 0;
    try {
      try {
        if (dirty != null) {
          final reset = dirty.requiresFullRecompute;
          final range = reset ? data.computableRange : dirty;
          for (final calculator in manager.visibleCalculators) {
            if (!requested.contains(calculator)) {
              calculatorCount++;
              calculator.compute(data, range, reset: reset);
            }
          }
        }
        for (final calculator in requested) {
          calculatorCount++;
          calculator.compute(data, data.computableRange, reset: true);
        }
      } catch (error, stackTrace) {
        stopwatch.stop();
        _retryPending = true;
        loge(
          'Compute failed::: key:${data.key} dirty:$dirty requested:${requested.length} '
          'calculators:$calculatorCount spent:${stopwatch.elapsedMicroseconds}μs',
          error: error,
          stackTrace: stackTrace,
        );
        rethrow;
      }
      stopwatch.stop();
      _retryPending = false;
      if (calculatorCount > 0) {
        logd(
          'Compute::: key:${data.key} dirty:$dirty requested:${requested.length} calculators:$calculatorCount '
          'spent:${stopwatch.elapsedMicroseconds}μs',
        );
      }
      _dirty = null;
      _requested.removeAll(requested);
      onComputed();
    } finally {
      _phase = _PipelinePhase.idle;
      _advanceTick();
      _drainPending();
      _scheduleTick();
    }
  }

  void _scheduleTick() {
    if (!_started || _disposed || _timer != null || (_dirty == null && _requested.isEmpty) || _urgent) return;
    _advanceTick();
    _timer = Timer(_nextTick - _elapsedNow, _onTick);
  }

  Duration get _elapsedNow => _elapsed?.call() ?? _clock.elapsed;

  void _advanceTick() {
    while (_nextTick <= _elapsedNow) {
      _nextTick += interval;
    }
  }
}
