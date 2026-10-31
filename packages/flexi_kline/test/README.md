# flexi_kline 测试套件

## 架构

- **领域轴**：目录镜像 `lib/src`（framework/ core/ data/ model/ extension/ utils/ view/ 等）
- **类型轴**：通过 tag 区分（exploration / benchmark / property / integration）
- **支撑层**：`test/support/` 按职责分层，经单一 barrel `support.dart` 导出

## 目录结构

```
test/
├── support/           # 测试支撑（doubles / fixtures / generators / builders / matchers）
├── framework/         # chart/（Indicator 与 PaintObject 生命周期、slot）、collection/、draw/
├── core/              # Controller 集成测试；controller/、grid/、chart_zoom/、perf/ 按主题分组
├── data/              # KlineData 与 KlineSpec
├── model/             # 数据模型单元测试
├── extension/         # 扩展方法测试
├── utils/             # 工具函数测试
├── view/              # Widget 与手势；touch/、non_touch/ 按输入通道分组
├── benchmark/         # 性能基准（tag: benchmark）
├── exploration/       # 语言/运行时演示（tag: exploration）
├── dart_test.yaml     # tag 声明
└── README.md
```

## 运行命令

```bash
# 常规测试（排除 exploration 和 benchmark）
flutter test --exclude-tags "exploration,benchmark"

# 性能基准
flutter test --tags benchmark

# 探索性测试
flutter test --tags exploration

# 全量
flutter test
```

## 支撑层 (support/)

| 子目录 | 职责 |
|---------|------|
| doubles/ | Fake/Spy 测试替身 |
| fixtures/ | 数据夹具（内嵌 K 线 + 随机工厂） |
| generators/ | 属性测试输入生成器 |
| builders/ | 薄 arrange 脚手架 |
| matchers/ | 自定义 matcher |
| property.dart | forAll 属性测试入口 |
