## 0.1.0
* Initial release: the painting primitives of `flexi_kline` as a standalone package with no dependency beyond Flutter.
* Add `IconShape`, an immutable shape description shared by canvas and widgets, with ten built-in shapes; `ShapeImage` caches a shape as a bitmap for inline labels.
* Add `ShapeIcon`, which paints a shape as a vector widget using `IconTheme` defaults like `Icon`, and `ShapeImageProvider` for APIs that only accept an `ImageProvider`.
