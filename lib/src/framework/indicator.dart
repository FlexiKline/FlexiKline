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

  PaintObject? paintObject;
  void ensurePaintObject(KlineBindingBase controller) {
    paintObject ??= createPaintObject(controller);
  }

  void update(Indicator newVal) {
    tipsHeight = newVal.tipsHeight;
    padding = newVal.padding;
  }

  PaintObject createPaintObject(KlineBindingBase controller);

  @mustCallSuper
  void dispose() {
    paintObject?.dispose();
    paintObject = null;
  }

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
abstract class SinglePaintObjectIndicator extends Indicator {
  SinglePaintObjectIndicator({
    required super.key,
    required super.height,
    super.tipsHeight,
    super.padding,
  });

  @override
  SinglePaintObjectBox createPaintObject(
    KlineBindingBase controller,
  );
}

/// 多个绘制Indicator的配置.
/// children 维护具体的Indicator配置.
class MultiPaintObjectIndicator extends Indicator {
  MultiPaintObjectIndicator({
    required super.key,
    required super.height,
    super.tipsHeight,
    super.padding,
    Iterable<dynamic> children = const [],
  }) : children = LinkedHashSet<SinglePaintObjectIndicator>.from(children);

  final Set<SinglePaintObjectIndicator> children;

  @override
  MultiPaintObjectBox createPaintObject(
    KlineBindingBase controller,
  ) {
    return MultiPaintObjectBox(controller: controller, indicator: this);
  }

  @override
  void ensurePaintObject(KlineBindingBase controller) {
    paintObject ??= createPaintObject(controller);
    for (var child in children) {
      if (child.paintObject != paintObject) {
        child.paintObject?.dispose();
        _initChildPaintObject(controller, child);
      }
    }
  }

  void _initChildPaintObject(
    KlineBindingBase controller,
    SinglePaintObjectIndicator indicator,
  ) {
    indicator.update(this);
    indicator.paintObject = indicator.createPaintObject(controller);
    indicator.paintObject!.parent = paintObject;
  }

  void appendIndicator(
    SinglePaintObjectIndicator newIndicator,
    KlineBindingBase controller,
  ) {
    SinglePaintObjectIndicator? old;
    if (children.contains(newIndicator)) {
      old = children.lookup(newIndicator);
      old?.dispose();
    }
    children.add(newIndicator);
    if (paintObject != null) {
      // 说明当前父PaintObject已经创建, 需要及时创建新加入的newIndicator,
      _initChildPaintObject(controller, newIndicator);
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
