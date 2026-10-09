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

import 'package:flutter/foundation.dart';

import '../painting/paint_resource.dart';

/// 持有 [PaintResource]; 何时 reset / dispose 由混入者决定。
///
/// 用法: `late final _ticks = own(LabelPainter(capacity: 16));`, late final 让未用到的资源不分配。
mixin PaintResourceOwner {
  final _resources = <PaintResource>[];
  bool _disposed = false;

  /// 登记 [resource] 并原样返回。
  @protected
  R own<R extends PaintResource>(R resource) {
    // dispose 之后登记的资源再没有释放时机。
    assert(!_disposed, 'own() called after disposeResources(): $resource would never be disposed.');
    _resources.add(resource);
    return resource;
  }

  /// 丢弃已登记资源的缓存内容, 资源本身保留。
  @protected
  void resetResources() {
    for (final resource in _resources) {
      resource.reset();
    }
  }

  /// 释放并注销所有已登记资源; 重复调用是空操作。
  @protected
  void disposeResources() {
    _disposed = true;
    for (final resource in _resources) {
      resource.dispose();
    }
    _resources.clear();
  }
}
