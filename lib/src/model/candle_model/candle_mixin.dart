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

import 'package:decimal/decimal.dart';

import '../minmax.dart';

mixin MaMixin {
  List<Decimal?>? maRets;

  bool get isValidMaRets {
    if (maRets == null || maRets!.isEmpty) return false;
    bool isValid = false;
    for (var ret in maRets!) {
      if (ret != null) {
        isValid = true;
        break;
      }
    }
    return isValid;
  }

  MinMax? get maRetsMinmax {
    if (maRets == null || maRets!.isEmpty) return null;
    MinMax? minmax;
    for (var ret in maRets!) {
      if (ret != null) {
        minmax ??= MinMax(max: ret, min: ret);
        minmax.updateMinMaxByVal(ret);
      }
    }
    return minmax;
  }
}
