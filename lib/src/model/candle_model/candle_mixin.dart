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

import '../../extension/export.dart';
import '../bag_num.dart';
import '../minmax.dart';

mixin MaMixin {
  List<BagNum?>? maRets;

  bool get isValidMaRets => maRets != null && maRets!.hasValidData;

  MinMax? get maRetsMinmax => MinMax.getMinMaxByList(maRets);
}

mixin VolMaMixin {
  List<BagNum?>? volMaRets;

  bool get isValidVolMaRets => volMaRets != null && volMaRets!.hasValidData;

  MinMax? get volMaRetsMinmax => MinMax.getMinMaxByList(volMaRets);
}

mixin EmaMixin {
  List<BagNum?>? emaRets;

  bool get isValidEmaRets => emaRets != null && emaRets!.hasValidData;

  MinMax? get emaRetsMinmax => MinMax.getMinMaxByList(emaRets);
}
