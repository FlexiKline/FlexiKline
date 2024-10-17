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

import 'package:flutter_ume_kit_dio_plus/flutter_ume_kit_dio_plus.dart'; // Dio Inspector

class AppDioInspector extends DioInspector {
  AppDioInspector({
    super.key,
    required super.dio,
    required this.showName,
  });

  final String showName;

  @override
  String get name => showName;

  @override
  String get displayName => showName;
}
