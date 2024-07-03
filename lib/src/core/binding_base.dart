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
import 'package:flutter/material.dart';

import '../framework/export.dart';
import 'interface.dart';

abstract class KlineBindingBase with KlineLog implements ISetting {
  final IConfiguration configuration;

  /// 对于Kline的操作是否自动保存到本地配置中.
  /// 包括: dispose; 增删指标; 调整参数等等.
  final bool autoSave;

  KlineBindingBase({
    required this.configuration,
    this.autoSave = true,
    ILogger? logger,
  }) {
    logd("constrouct");
    loggerDelegate = logger;
    // initFlexiKlineConfig();
  }

  @protected
  @mustCallSuper
  void initState() {
    logd("initState base");
  }

  @protected
  @mustCallSuper
  void dispose() {
    logd("dispose base");
    if (autoSave) storeFlexiKlineConfig();
  }

  KlineBindingBase get instance => this;

  T getInstance<T extends KlineBindingBase>(T instance) {
    return instance;
  }
}
