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

library indicator;

import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../extension/export.dart';
import '../../config/export.dart';
import '../../core/export.dart';
import '../../data/kline_data.dart';
import '../../model/export.dart';
import '../../utils/decimal_format_util.dart';
import '../collection/sortable_hash_set.dart';
import '../logger.dart';
import '../serializers.dart';

part 'common.dart';
part 'model.dart';
part 'indicator.g.dart';
part 'object.dart';
part 'object_helper.dart';