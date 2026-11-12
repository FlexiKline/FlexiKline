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

import 'package:flexi_painting/flexi_painting.dart';
import 'package:flutter/widgets.dart';

void main() => runApp(
  WidgetsApp(
    color: const Color(0xFFFFFFFF),
    textStyle: const TextStyle(color: Color(0xFF000000), fontSize: 14),
    pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    ),
    home: const ColoredBox(
      color: Color(0xFFFFFFFF),
      child: Center(child: PaintingExample()),
    ),
  ),
);

const _bubble = BubbleBorder(borderRadius: BorderRadius.all(Radius.circular(6)));

/// A bubble used as a widget decoration, and the same bubble behind a cached canvas label.
class PaintingExample extends StatefulWidget {
  const PaintingExample({super.key});

  @override
  State<PaintingExample> createState() => _PaintingExampleState();
}

class _PaintingExampleState extends State<PaintingExample> {
  /// Lives across frames: the text is laid out again only when the key changes.
  final _label = LabelPainter();
  int _taps = 0;

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const ShapeDecoration(color: Color(0xFF3F51B5), shape: _bubble),
          child: const Text('ShapeDecoration', style: TextStyle(color: Color(0xFFFFFFFF))),
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: () => setState(() => _taps++),
          child: CustomPaint(size: const Size(240, 80), painter: _LabelChart(_label, _taps)),
        ),
      ],
    );
  }
}

class _LabelChart extends CustomPainter {
  _LabelChart(this.label, this.taps);

  final LabelPainter label;
  final int taps;

  static const _style = LabelStyle(
    text: TextStyle(color: Color(0xFF000000), fontSize: 14),
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: ShapeDecoration(color: Color(0xFFFFE082), shape: _bubble),
  );

  @override
  void paint(Canvas canvas, Size size) {
    label.paint(
      canvas,
      taps,
      build: () => 'Tapped $taps times',
      style: _style,
      anchor: size.center(Offset.zero),
      align: Alignment.center,
    );
  }

  @override
  bool shouldRepaint(_LabelChart oldDelegate) => oldDelegate.taps != taps;
}
