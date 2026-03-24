# flexi_kline 测试套件说明

> 当前全部测试通过：`+562: All tests passed!`

---

## 目录结构

```
test/
├── helpers/            # 测试支撑工具（无 main() 入口，不参与测试运行）
├── model/              # 数据模型层测试（对应 lib/src/model/）
├── framework/          # 框架层测试（对应 lib/src/framework/）
├── extension/          # 扩展层测试（对应 lib/src/extension/）
├── utils/              # 工具函数测试（对应 lib/src/utils/）
└── exploration/        # 探索性演示（精度行为、异步机制、性能基准）
```

---

## helpers/ — 测试支撑工具

不直接运行，供其他测试文件 import。

| 文件 | 说明 |
|------|------|
| `test_utils.dart` | 通用打印工具：`logMsg`、`printMap`、`printIterable` |
| `log_print_impl.dart` | `ILogger` 的测试实现，输出到 `debugPrint` |
| `mock_candle_data.dart` | 内嵌 K 线示例数据；`getEthUsdtCandles()` / `getBtcCandles()` |
| `random_candle_list.dart` | 随机生成 `CandleModel` 列表 |
| `test_kline_config.dart` | `IFlexiKlineTheme` / `IConfiguration` 的轻量测试实现 |
| `compute.dart` | 基于 Isolate 的 `compute` 辅助函数 |

---

## model/ — 数据模型测试

### `flexi_num_test.dart`

覆盖 `FlexiNum`（`lib/src/model/flexi_num.dart`）的核心运算和类型分发逻辑。

| 测试组 | 覆盖点 |
|--------|--------|
| 基础四则运算 | `+` / `-` / `*` / `/` / `%` / `remainder`（num+num、decimal+decimal）；`isZero` |
| 跨类型运算 | num ↔ decimal 四则混合运算 |
| `fromAny` | 4 种输入类型（num/Decimal/String/BigInt）× 2 种模式；不支持类型抛 `FlexiNumException`；`fromAnyOrNull` |
| 比较运算符 | `<`、`<=`、`>`、`>=`（num/decimal）；`ltNum`/`gtNum`/`gteNum`/`lteNum`；`ltDecimal`/`gtDecimal` 等 |
| `abs` | 负值、正值、零、decimal |
| `divSafe` | 非零正常计算；除零返回 zero/自定义默认值；`divSafeNum`；`divSafeDecimal` |
| `clamp` | 范围内不变；低于下界；高于上界；`clampNum`；`clampDecimal` |
| `floor` / `ceil` / `round` | scale=0 和 scale=2（num/decimal）；负数 floor/ceil |
| `shift` | 正/负幂次（num/decimal）；shift(0) 不变 |
| `calcuMin` / `calcuMax` | 两端比较；相等时返回自身 |

### `range_test.dart`

覆盖 `Range` 值对象（`lib/src/model/range.dart`）。

| 测试组 | 覆盖点 |
|--------|--------|
| 构造 | 基本构造、`Range.empty` |
| getters | `length`、`isEmpty`、`isNotEmpty` |
| `merge` | 相邻、重叠、包含、不相交、与 empty 合并 |
| 相等性 | `==`、`hashCode` 一致性、`Range.empty` 等价 |
| `toString` | 格式验证 |

### `flexi_candle_model_test.dart`

覆盖 `FlexiCandleModel` 的全部公开 API。

| 测试组 | 用例数 | 覆盖点 |
|--------|--------|--------|
| `FlexiCandleModel.init` | 3 | fast/accurate 两种 `ComputeMode` 初始化；初始槽位为 null |
| `OHLCV getters` | 11 | ts / open / high / low / close / vol / turnover / tradeCount / confirmed / isLong / isShort |
| `get / set` | 8 | 多类型读写；类型不匹配返回 null；越界返回 false/null |
| `operator[] / operator[]=` | 9 | 正常读写；越界抛 `RangeError`；null 赋值清槽 |
| `isEmpty / clean / cleanAll` | 7 | 初始为 true；有数据为 false；越界为 true；clean 返回值；cleanAll 清空 |
| `hasValidData` | 3 | 空时 false；有数据时 true；cleanAll 后 false |
| `ComputeMode` | 2 | fast 使用 double（有精度损失）；accurate 使用 Decimal（保精度） |
| 边界情况 | 3 | count=0；turnover 为 null；大量槽位首尾读写 |

### `kline_data_test.dart`

覆盖 `lib/src/data/kline_data.dart` 中的合并和去重算法。

| 测试组 | 覆盖点 |
|--------|--------|
| `combineCandleList` | 空列表；前插；重叠覆盖；尾追加；尾端重叠；完全覆盖；内部嵌套不处理 |
| 合并算法逻辑（`_merge`） | 空列表；仅 curList；仅 newList；before1-4；after1-5 共 12 个场景 |
| `removeDuplicate` | 单元素；无重复；相邻重复；全部相同；头/尾重复 |

**说明：** `removeDuplicate` 不支持空列表输入（实现限制），不提供相应用例。

### `minmax_test.dart`

覆盖 `MinMax`（`lib/src/model/minmax.dart`）。

| 测试组 | 覆盖点 |
|--------|--------|
| 构造 / 工厂 | `MinMax()`、`MinMax.same`、`MinMax.from`（自动排序）、`MinMax.zero` |
| `clone` | 独立副本，修改不影响原对象 |
| getters | `size`、`middle`、`diffDivisor`、`isZero`、`isSame` |
| `updateMinMaxBy*` | `updateMinMaxBy`、`updateMinMaxByNum`、`updateMinMaxByDecimal` |
| `updateMinMax` | null 参数；扩展；不缩小 |
| `expand` | 正 margin；margin=0；负 margin |
| `expandByRatios` | 空列表；单 ratio；双 ratio；ratio=0 |
| `minToZero` | min>0；min=0；min<0 |
| `getMinMaxByList` | null/空；全 null；单元素；多元素；含 null |
| `lerp` | t=0/0.5/1；t=0.15；副本独立性；相同 MinMax；t 越界 clamp；30帧收敛 |

---

## framework/ — 框架基础设施测试

### `collections_test.dart`

覆盖 `lib/src/framework/collection/` 下的自定义集合类。

| 测试组 | 覆盖点 |
|--------|--------|
| `SortableHashSet` | 按权重排序；`add` 替换；`remove`；`removeWhere`；`append`（replace/no-replace）；`reversed`；`originList` |
| `FixedHashQueue` | 容量内追加；超容量淘汰队首；`append` 就地替换；`atFirst` 淘汰队尾；capacity=0 不入队 |
| `FIFOHashMap` | 容量内插入；超容量淘汰最早 key；更新已有 key 不触发淘汰；无容量限制 |

### `indicator_key_test.dart`

覆盖 `IIndicatorKey` 系列的创建、相等性、序列化/反序列化。

| 测试组 | 覆盖点 |
|--------|--------|
| 创建和基本属性 | `NormalIndicatorKey` / `DataIndicatorKey` / `BusinessIndicatorKey`；id / label |
| 相等性和哈希 | 同类同 id 相等；同类不同 id 不等；不同类同 id 不等；label 不影响相等性 |
| toString | 格式验证 |
| `IIndicatorKeyConvert` 序列化 | toJson / fromJson 往返；label 含冒号；无效格式返回 unknownIndicatorKey |
| `NormalIndicatorKeyConvert` | 专属 Convert 序列化；反序列化其他类型时转换 |
| `DataIndicatorKeyConvert` | 同上 |
| `BusinessIndicatorKeyConvert` | 同上 |
| 常量 IndicatorKey | unknownIndicatorKey / mainIndicatorKey / candleIndicatorKey / timeIndicatorKey |
| 边界情况 | 空字符串 id/label；超长字符串；含特殊字符 |

---

## extension/ — 扩展层测试

### `basic_type_ext_test.dart`

覆盖 `lib/src/extension/basic_type_ext.dart` 中的字符串扩展。

| 测试组 | 覆盖点 |
|--------|--------|
| `toCamelCase` | 下划线/连字符/空格分隔；多词；首词大写化；空字符串；单词 |
| `toSnakeCase` | camelCase→snake；多大写；首字母大写（前导下划线）；空字符串；全小写 |
| `truncate` | 未超出原样；等于 maxLength；超出添加省略号；自定义省略号；maxLength=0 |
| `sensitive` | 空字符串；长度不足不脱敏；默认参数；10位字符串；自定义 start/end；自定义省略号 |
| `toBase64` / `fromBase64` | ASCII 往返；Unicode 往返；空字符串往返；编码后不含原始非ASCII字符 |

### `collections_ext_test.dart`

覆盖 `lib/src/extension/collections_ext.dart` 中的集合扩展方法。

| 测试组 | 覆盖点 |
|--------|--------|
| `binarySearch` | 升序/降序查找；首元素；末尾元素；未找到 -1；空列表 |
| `secondWhereOrNull` | 找到第二个；只有一个；没有满足的 |
| `range` | 空列表；start+end；负 start 抛出；end<=start 抛出 |
| `groupBy` | 按奇偶分组；全部同组；空列表 |
| `chunk` | 均匀分块；最后不足块；size=0 抛出；空列表 |
| `partition` | 按奇偶分割；全匹配；全不匹配；空列表 |
| `sum` / `average` | 无 selector；带 selector；空列表 average=0 |
| `maxBy` / `minBy` | 正常；空列表返回 null |
| `distinctBy` | 有重复去重；全不重复 |
| `firstWhereOrNull` | 找到；未找到；空列表 |
| `toMap` | 正常映射；null 条目过滤；空列表 |

### `stopwatch_ext_test.dart`

覆盖 `FlexiStopwatch`（`lib/src/extension/stopwatch_ext.dart`）的核心行为。

| 测试组 | 覆盖点 |
|--------|--------|
| `FlexiStopwatch` | `lap` / `spentMicroseconds`；`run` 同步执行；`exec` 异步执行；执行后秒表仍在计时 |

---

## utils/ — 工具函数测试

### `algorithm_test.dart`

覆盖 `lib/src/utils/algorithm_util.dart` 中的算法函数。

| 测试组 | 覆盖点 |
|--------|--------|
| `scaledSingal` | x<1 返回 null；负数取绝对值；k=1 固定值；符号保留；输出在 (0,1)；k/x 单调性；自定义 kMax |
| `scaledDecelerate` | scale=1 原样；scale>1 增幅压缩；精确值；0<scale<1；单调递增；相对增幅对比 |
| `calcuInertialPanDuration` | 速度≤1 返回 0；负数取绝对值；单调递增；不超 maxDuration |
| `ensureMinDistance` | 调整后差为 1；d1=d2 对称扩张；距离已≥1 不调整；中点不变 |

### `vector_test.dart`

覆盖 `lib/src/utils/vector_util.dart` 和相关几何扩展。

| 测试组 | 覆盖点 |
|--------|--------|
| `pointDistanceToLine` | 点在线段上；不在线上；两种调用方式一致 |
| `reflectPointsOnRect` | 7 个方向，交点落在矩形边界 |
| `pointReflectInRect` | 8 个方向，落在相应边界 |
| `getDxAtDyOnAB` | y=x 斜线；颠倒端点一致；垂直线；水平线 |
| `Offset.direction` | 向右 0°；右下 45°；向下 90°；向左 180° |

### `convert_util_test.dart`

覆盖 `lib/src/utils/convert_util.dart` 中的类型转换函数。

| 测试组 | 覆盖点 |
|--------|--------|
| `parseInt` | null/int/double/String/非数字字符串 |
| `parseDouble` | null/int/double/String/其他类型 |
| `parseBool` | null；true/false 大小写不敏感；无效字符串 |
| `parseDecimal` | null/int/String/无效字符串 |
| `parseDateTime` / `convertDateTime` | null；int 时间戳；ISO 字符串；往返一致性 |
| `parseHexColor` / `convertHexColor` | null/空；0x 格式；# 6位；# 8位；大小写；往返一致性 |
| `parseRadius` / `convertRadius` | null→zero；num/String 单值；String 双值；往返（circular/elliptical） |
| `parseAlignment` / `convertAlignment` | null/空 Map；9 个预设；自定义 x/y；往返一致性 |

---

## exploration/ — 探索性演示

这些用例**不验证业务逻辑**，仅演示语言/运行时行为，CI 可按需跳过。

### `ieee754_precision_test.dart`

演示 IEEE 754 双精度浮点数与 `Decimal` 的精度差异，以及 RSI 精度和 `math.log` 对数函数各值行为。

### `dart_async_test.dart`

演示 Dart 异步机制（Future / scheduleMicrotask / Timer 执行顺序、`Future.doWhile`）、`Overlay` JSON 序列化，以及 `is` vs `case` 模式匹配性能对比。

### `dart_stopwatch_test.dart`

演示 Dart 标准库 `Stopwatch` 的基础 start/stop/elapsed 行为。

---

## 运行方式

```bash
# 运行全部测试
flutter test

# 运行指定目录
flutter test test/model/
flutter test test/framework/
flutter test test/extension/
flutter test test/utils/

# 跳过 exploration（探索性，非业务断言）
flutter test --exclude-tags exploration
```

> 注：`exploration/` 中的测试全部可通过，但不建议将其纳入 CI 强制检查，因其部分测试
> 依赖浮点行为（受 Dart 版本和平台影响）。
