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

import '../constant.dart';
import '../framework/export.dart';
import 'vol_ma.dart';
import 'volume.dart';

part 'ma_volume.g.dart';

@FlexiIndicatorSerializable
class MAVolumeIndicator extends MultiPaintObjectIndicator {
  MAVolumeIndicator({
    super.key = maVolKey,
    super.name = 'MAVOL',
    super.height = defaultSubIndicatorHeight,
    super.padding = defaultSubIndicatorPadding,
    super.drawBelowTipsArea = false,
    required this.volumeIndicator,
    required this.volMaIndicator,
  }) : super(children: [volumeIndicator, volMaIndicator]);
  // 确保MAVOL中Volume参数
  // : volumeIndicator = volumeIndicator.copyWith(
  //       paintMode: PaintMode.combine,
  //       showYAxisTick: true,
  //       showCrossMark: true,
  //       showTips: true,
  //       useTint: false,
  //     ),
  //     super(children: [
  //       volumeIndicator.copyWith(
  //         paintMode: PaintMode.combine,
  //         showYAxisTick: true,
  //         showCrossMark: true,
  //         showTips: true,
  //         useTint: false,
  //       ),
  //       volMaIndicator
  //     ]);

  final VolumeIndicator volumeIndicator;
  final VolMaIndicator volMaIndicator;

  factory MAVolumeIndicator.fromJson(Map<String, dynamic> json) =>
      _$MAVolumeIndicatorFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$MAVolumeIndicatorToJson(this);
}
