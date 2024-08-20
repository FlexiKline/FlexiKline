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

import 'binding_base.dart';
import 'interface.dart';

/// 负责绘制图层
///
mixin DrawBinding on KlineBindingBase implements IDraw {
  @override
  void initState() {
    super.initState();
    logd('initState draw');
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose draw');
  }

  // @override
  // bool onDrawStart(GestureData data, {bool force = false}) {
  //   // TODO: implement startCross
  //   throw UnimplementedError();
  // }

  // /// 更新Cross事件数据.
  // @override
  // void updateCross(GestureData data) {

  // }

  // /// 取消当前Cross事件
  // @override
  // void cancelCross() {

  // }
}
