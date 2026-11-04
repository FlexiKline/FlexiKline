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
import 'package:flutter_test/flutter_test.dart';

/// 每次绘制记一次; 默认按类型判等, 两个实例的 key 相同。
final class _Probe extends IconShape {
  const _Probe(this.log);

  final List<Color> log;

  @override
  void paint(Canvas canvas, Size size, Color color) => log.add(color);
}

/// 同步解析 [provider], 返回图片信息; 调用方负责 dispose。
ImageInfo _load(ImageProvider provider, double devicePixelRatio) {
  ImageInfo? info;
  final stream = provider.resolve(ImageConfiguration(devicePixelRatio: devicePixelRatio));
  final listener = ImageStreamListener((image, _) => info = image);
  stream
    ..addListener(listener)
    ..removeListener(listener);
  return info!;
}

void main() {
  const red = Color(0xFFFF0000);
  const blue = Color(0xFF0000FF);
  const size = Size(5, 6.1);

  tearDown(
    () => PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages(),
  );

  testWidgets('形状、尺寸、颜色与像素密度相同时命中 ImageCache, 只栅格化一次', (tester) async {
    final log = <Color>[];
    _load(ShapeImageProvider(_Probe(log), size, red), 2).dispose();
    _load(ShapeImageProvider(_Probe(log), size, red), 2).dispose();
    expect(log, [red]);
  });

  testWidgets('key 区分像素密度与颜色', (tester) async {
    const provider = ShapeImageProvider(StarShape(), size, red);
    final key = await provider.obtainKey(const ImageConfiguration(devicePixelRatio: 2));

    expect(await provider.obtainKey(const ImageConfiguration(devicePixelRatio: 2)), key);
    expect(await provider.obtainKey(const ImageConfiguration(devicePixelRatio: 3)), isNot(key));
    expect(
      await const ShapeImageProvider(StarShape(), size, blue).obtainKey(const ImageConfiguration(devicePixelRatio: 2)),
      isNot(key),
    );
  });

  testWidgets('位图像素尺寸 = 逻辑尺寸 x 像素密度, 向上取整; scale 为像素密度', (tester) async {
    final info = _load(const ShapeImageProvider(StarShape(), size, red), 3);
    expect((info.image.width, info.image.height, info.scale), (15, 19, 3.0));
    info.dispose();
  });

  testWidgets('Image 按逻辑尺寸显示', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: Image(image: ShapeImageProvider(StarShape(), Size(12, 8), red))),
      ),
    );
    expect(tester.getSize(find.byType(Image)), const Size(12, 8));
  });
}
