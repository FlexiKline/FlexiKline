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

import 'indicator.dart';
import 'paint_object.dart';

abstract class IndicatorContext {
  IndicatorChart get indicatorChart;
  PaintObjectIndicator get indicator;
}

abstract class IndicatorElement<T extends PaintObjectIndicator>
    implements IndicatorContext {
  IndicatorElement(T indicator) : _indicator = indicator;

  @override
  T get indicator => _indicator!;
  T? _indicator;

  int? get solot => _slot;
  int? _slot;

  void mount(int newSlot);

  void update(covariant T newIndicator) {
    if (newIndicator != indicator ||
        PaintObjectIndicator.canUpdate(indicator, newIndicator)) {
      _indicator = newIndicator;
    }
  }
}

class SingleIndicatorElement<T extends PaintObjectIndicator>
    extends IndicatorElement {
  SingleIndicatorElement(super.indicator);

  IndicatorChart? _indicatorChart;

  @override
  IndicatorChart<PaintObjectIndicator> get indicatorChart {
    assert(_indicatorChart != null, '$runtimeType unmounted');
    return _indicatorChart!;
  }

  @override
  void mount(int newSlot) {}
}
