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

import 'dart:collection';

import 'package:flutter/material.dart';

import '../core/export.dart';
import 'object.dart';

/// 指标基础配置
/// tipsHeight: 绘制区域顶部提示信息区域的高度
/// padding: 绘制区域的边界设定
abstract class Indicator {
  Indicator({
    required this.key,
    required this.height,
    this.tipsHeight = 0.0,
    this.padding = EdgeInsets.zero,
  });
  final Key key;
  final double height;
  double tipsHeight;
  EdgeInsets padding;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is Indicator) {
      return other.runtimeType == runtimeType && other.key == key;
    }
    return false;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }

  @mustCallSuper
  void dispose();

  static bool canUpdate(Indicator oldIndicator, Indicator newIndicator) {
    return oldIndicator.runtimeType == newIndicator.runtimeType &&
        oldIndicator.key == newIndicator.key;
  }

  static bool isMultiIndicator(Indicator indicator) {
    return indicator is MultiPaintObjectIndicator;
  }
}

/// 绘制对象的配置
/// 通过Indicator去创建PaintObject接口
/// 缓存Indicator对应创建的paintObject.
abstract class PaintObjectIndicator extends Indicator {
  PaintObjectIndicator({
    required super.key,
    required super.height,
    super.tipsHeight,
    super.padding,
  });

  PaintObject? _paintObject;
  PaintObject? get paintObject => _paintObject;
  set paintObject(val) {
    _paintObject = val;
  }

  void update(Indicator newVal) {
    tipsHeight = newVal.tipsHeight;
    padding = newVal.padding;
  }

  @factory
  PaintObject createPaintObject(
    KlineBindingBase controller,
  );

  @mustCallSuper
  @override
  void dispose() {
    paintObject?.dispose();
    paintObject = null;
  }
}

/// 多个绘制Indicator的配置.
/// children 维护具体的Indicator配置.
abstract class MultiPaintObjectIndicator extends PaintObjectIndicator {
  MultiPaintObjectIndicator({
    required super.key,
    required super.height,
    super.tipsHeight,
    super.padding,
    Iterable<dynamic> children = const [],
  }) : children = LinkedHashSet<PaintObjectIndicator>.from(children);

  final Set<PaintObjectIndicator> children;

  @override
  @mustCallSuper
  MultiPaintObjectBox createPaintObject(KlineBindingBase controller);

  void appendIndicator(
    PaintObjectIndicator newIndicator,
    KlineBindingBase controller,
  ) {
    PaintObjectIndicator? old;
    if (children.contains(newIndicator)) {
      old = children.lookup(newIndicator);
      old?.dispose();
    }
    children.add(newIndicator);
    if (paintObject != null) {
      // 说明当前父PaintObject已经创建, 需要及时创建新加入的newIndicator,
      newIndicator.update(this);
      newIndicator.paintObject = newIndicator.createPaintObject(controller);
      newIndicator.paintObject!.parent = paintObject;
    }
  }

  void deleteIndicator(Key key) {
    children.removeWhere((element) {
      if (element.key == key) {
        element.dispose();
        return true;
      }
      return false;
    });
  }
}
