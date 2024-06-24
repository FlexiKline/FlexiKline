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
  List<BagNum?>? maList;

  bool get isValidMaList => maList != null && maList!.hasValidData;

  MinMax? get maListMinmax => MinMax.getMinMaxByList(maList);

  void cleanMa() {
    maList = null;
  }
}

mixin VolMaMixin {
  List<BagNum?>? volMaList;

  bool get isValidVolMaList => volMaList != null && volMaList!.hasValidData;

  MinMax? get volMaListMinmax => MinMax.getMinMaxByList(volMaList);

  void cleanVolMa() {
    volMaList = null;
  }
}

mixin EmaMixin {
  List<BagNum?>? emaList;

  bool get isValidEmaList => emaList != null && emaList!.hasValidData;

  MinMax? get emaListMinmax => MinMax.getMinMaxByList(emaList);

  void cleanEma() {
    emaList = null;
  }
}

mixin BollMixin {
  BagNum? mb;
  BagNum? up;
  BagNum? dn;

  bool get isValidBollData => mb != null && up != null && dn != null;

  MinMax? get bollMinmax => MinMax.getMinMaxByList([mb, up, dn]);

  void cleanBoll() {
    mb = up = dn = null;
  }
}

mixin SarMixin {
  BagNum? sar;

  /// 1: 代表上涨; -1: 代表下跌; 0: 代表开始上涨或下跌
  int? sarFlag;

  bool get isValidSarData => sar != null && sarFlag != null;

  void cleanSar() {
    sar = null;
  }
}

mixin MacdMixin {
  BagNum? dif;
  BagNum? dea;
  BagNum? macd;

  bool get isValidMacdData => dif != null && dea != null && macd != null;

  MinMax? get macdMinmax => MinMax.getMinMaxByList([dif, dea, macd]);

  void cleanMacd() {
    dif = dea = macd = null;
  }
}

mixin KdjMixin {
  BagNum? k;
  BagNum? d;
  BagNum? j;

  bool get isValidKdjData => k != null && d != null && j != null;

  MinMax? get kdjMinmax => MinMax.getMinMaxByList([k, d, j]);

  void cleanKdj() {
    k = d = j = null;
  }
}
