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

import 'package:flexi_kline/src/painting/export.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// 经参数构造, 保证每次都是新实例而非同一个 const。
LabelStyle _style({double fontSize = 10, EdgeInsets padding = EdgeInsets.zero, ShapeDecoration? decoration}) =>
    LabelStyle(
      text: TextStyle(fontSize: fontSize),
      padding: padding,
      decoration: decoration,
    );

void main() {
  group('TextLayoutCache', () {
    late TextLayoutCache cache;
    var builds = 0;

    Object Function() counted(Object content) => () {
      builds++;
      return content;
    };

    setUp(() {
      builds = 0;
      cache = TextLayoutCache(capacity: 2)..configure(_style());
    });

    tearDown(() => cache.dispose());

    test('命中时不再调用 build, 同 key 返回同一个 painter', () {
      final first = cache.layout('k', build: counted('hello'));
      final second = cache.layout('k', build: counted('hello'));
      expect(builds, 1);
      expect(second, same(first));
    });

    test('build 为 null 时 key 本身就是文本', () {
      final painter = cache.layout('abc');
      expect(painter.plainText, 'abc');
    });

    test('List key 按元素命中', () {
      final first = cache.layout([1.5, 2, 'x'], build: counted('a'));
      final second = cache.layout([1.5, 2, 'x'], build: counted('a'));
      expect(builds, 1);
      expect(second, same(first));
    });

    test('List key 入池时冻结: 调用方之后改动原 List, 已存条目不受影响', () {
      final key = [1, 2];
      final first = cache.layout(key, build: counted('a'));
      key[0] = 9; // 调用方复用自己的 List
      expect(cache.layout([1, 2], build: counted('a')), same(first));
      expect(builds, 1);

      // 命中路径重新插入的仍是池里冻结的 key, 而不是本次传入的实例。
      final reused = [1, 2];
      expect(cache.layout(reused, build: counted('a')), same(first));
      reused[1] = 7;
      expect(cache.layout([1, 2], build: counted('a')), same(first));
      expect(builds, 1);

      // 改动后的值是另一个 key。
      cache.layout([9, 2], build: counted('b'));
      expect(builds, 2);
    });

    test('record key 按值命中', () {
      final first = cache.layout((1.5, 2), build: counted('a'));
      final second = cache.layout((1.5, 2), build: counted('a'));
      expect(builds, 1);
      expect(second, same(first));
    });

    group('configure', () {
      test('等值但非同一实例的样式不清空', () {
        final painter = cache.layout('k', build: counted('a'));
        cache.configure(_style());
        expect(cache.layout('k', build: counted('a')), same(painter));
        expect(builds, 1);
        expect(painter.debugDisposed, isFalse);
      });

      test('只改 padding / decoration 不清空', () {
        final painter = cache.layout('k', build: counted('a'));
        cache.configure(_style(padding: const EdgeInsets.all(4)));
        cache.configure(
          _style(
            decoration: const ShapeDecoration(color: Color(0xFF00FF00), shape: RoundedRectangleBorder()),
          ),
        );
        expect(cache.layout('k', build: counted('a')), same(painter));
        expect(builds, 1);
      });

      test('排版字段变化时清空并释放旧 painter', () {
        final painter = cache.layout('k', build: counted('a'));
        cache.configure(_style(fontSize: 20));
        expect(painter.debugDisposed, isTrue);
        final next = cache.layout('k', build: counted('a'));
        expect(builds, 2);
        expect(next, isNot(same(painter)));
        expect(next.height, 20);
      });
    });

    group('LRU', () {
      test('容量满时淘汰最旧的并复用它的 painter', () {
        final a = cache.layout('a');
        cache.layout('b');
        final c = cache.layout('c');
        expect(c, same(a));
        expect(c.plainText, 'c');
        expect(a.debugDisposed, isFalse);

        // 'a' 已被淘汰: 再取需要重新构建。
        cache.layout('a', build: counted('a'));
        expect(builds, 1);
      });

      test('最近命中的不被淘汰', () {
        final a = cache.layout('a', build: counted('a'));
        cache.layout('b', build: counted('b'));
        cache.layout('a', build: counted('a')); // 命中, 'a' 挪到末尾
        cache.layout('c', build: counted('c')); // 淘汰 'b'
        expect(builds, 3);
        expect(cache.layout('a', build: counted('a')), same(a));
        expect(builds, 3);
        cache.layout('b', build: counted('b'));
        expect(builds, 4);
      });
    });

    test('InlineSpan 挂在以 style.text 为样式的根 span 下并继承字号', () {
      cache.configure(_style(fontSize: 20));
      const child = TextSpan(text: 'x');
      final painter = cache.layout('span', build: () => child);

      final root = painter.text! as TextSpan;
      expect(root.style, const TextStyle(fontSize: 20));
      expect(root.text, isNull);
      expect(root.children, hasLength(1));
      expect(root.children!.single, same(child));

      final direct = TextPainter(
        text: const TextSpan(text: 'x', style: TextStyle(fontSize: 20)),
        textDirection: TextDirection.ltr,
      )..layout();
      expect(painter.size, direct.size);
      expect(painter.height, 20);
      direct.dispose();
    });

    test('子 span 继承根 span 的颜色', () {
      const color = Color(0xFFFF0000);
      cache.configure(const LabelStyle(text: TextStyle(fontSize: 10, color: color)));
      final painter = cache.layout('span', build: () => const TextSpan(text: 'x'));
      final root = painter.text! as TextSpan;
      expect(root.style?.color, color);
      expect((root.children!.single as TextSpan).style, isNull);
    });

    test('minWidth / maxWidth 变化时不调用 build, 宽度随约束变化', () {
      final painter = cache.layout('k', build: counted('ab'));
      expect(painter.width, 20);

      expect(cache.layout('k', build: counted('ab'), minWidth: 50).width, 50);
      expect(cache.layout('k', build: counted('ab'), maxWidth: 10).width, 10);
      expect(cache.layout('k', build: counted('ab')).width, 20);
      expect(builds, 1);
    });

    test('minWidth == maxWidth 时宽度固定', () {
      cache.configure(const LabelStyle(text: TextStyle(fontSize: 10), minWidth: 30, maxWidth: 30));
      expect(cache.layout('ab').width, 30);
      expect(cache.layout('abcdef').width, 30);
    });

    test('style.maxWidth 与调用约束的 maxWidth 取交集, minWidth 夹到交集以内', () {
      cache.configure(const LabelStyle(text: TextStyle(fontSize: 10), maxWidth: 30));
      expect(cache.layout('abcdef', maxWidth: 200).width, 30);
      expect(cache.layout('abcdef', maxWidth: 20).width, 20);

      cache.configure(const LabelStyle(text: TextStyle(fontSize: 10), minWidth: 50, maxWidth: 100));
      expect(cache.layout('ab', maxWidth: 40).width, 40);
      expect(cache.layout('ab', maxWidth: 200).width, 50);
    });

    test('TextOverflow.ellipsis 配合 maxLines 生效', () {
      cache.configure(const LabelStyle(text: TextStyle(fontSize: 10, overflow: TextOverflow.ellipsis), maxLines: 1));
      final painter = cache.layout('abcdefghij', maxWidth: 35);
      expect(painter.didExceedMaxLines, isTrue);
      expect(painter.ellipsis, '\u2026');
      expect(painter.width, lessThanOrEqualTo(35));

      // 未声明 ellipsis 时不翻译。
      cache.configure(const LabelStyle(text: TextStyle(fontSize: 10), maxLines: 1));
      expect(cache.layout('abcdefghij', maxWidth: 35).ellipsis, isNull);
    });

    test('reset 之后 painter 已释放, 再取重新构建', () {
      final a = cache.layout('a', build: counted('a'));
      final b = cache.layout('b', build: counted('b'));
      cache.reset();
      expect(a.debugDisposed, isTrue);
      expect(b.debugDisposed, isTrue);
      cache.layout('a', build: counted('a'));
      expect(builds, 3);
    });

    test('dispose 之后 painter 已释放', () {
      final local = TextLayoutCache()..configure(_style());
      final painter = local.layout('a');
      local.dispose();
      expect(painter.debugDisposed, isTrue);
    });
  });
}
