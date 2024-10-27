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

library overlay;

import 'dart:collection';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../config/export.dart';
import '../../constant.dart';
import '../../core/interface.dart';
import '../../data/export.dart';
import '../../extension/export.dart';
import '../../model/export.dart';
import '../../draw_objects/export.dart';
import '../../utils/date_time.dart';
import '../../utils/decimal_format_util.dart';
import '../collection/sortable_hash_set.dart';
import '../configuration.dart';
import '../logger.dart';
import '../serializers.dart';

part 'common.dart';
part 'draw_state.dart';
part 'model.dart';
part 'manager.dart';
part 'object.dart';
part 'object_helper.dart';
part 'overlay.g.dart';
