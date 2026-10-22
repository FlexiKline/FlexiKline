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

import 'package:flutter/material.dart';

import 'chart.dart';
import 'constants.dart';
import 'preset.dart';

class BenchApp extends StatelessWidget {
  const BenchApp({
    super.key,
    required this.preset,
    this.features = const {},
    this.candles = benchCandleCount,
  });

  final BenchPreset preset;
  final Set<BenchFeature> features;
  final int candles;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: BenchChart(preset: preset, features: features, candles: candles),
        ),
      ),
    );
  }
}
