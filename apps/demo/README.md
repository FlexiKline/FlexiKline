# FlexiKline Demo

[FlexiKline](../packages/flexi_kline/) 的示例应用，演示蜡烛图（K 线）绘制与交互。

## 运行

```bash
flutter run
```

支持 Android、iOS、macOS、Linux、Windows、Web 多端运行。

## 功能

- BTCUSDT 蜡烛 K 线：分时 / 15分 / 1时 / 1天 / 1周
- 模拟 HTTP 分页加载 + 模拟 WebSocket 实时推送
- 横屏 K 线（移动端自动切换横竖屏）
- 主题切换（Material 层与 K 线层联动）
- 绘图工具（由 flexi_kline_draw_tools 提供）

## 目录结构

```
lib/
├── main.dart                 # 入口
└── src/
    ├── app.dart              # MaterialApp 配置（主题、路由观察者）
    ├── config/               # 框架配置（K线周期、主题、指标、存储）
    ├── data/                 # 数据层（接口、mock 实现、模型）
    ├── pages/
    │   ├── common/
    │   │   ├── core/         # 页面架构核心（State 基类、数据接线 mixin）
    │   │   └── components/   # 业务通用组件（周期切换栏）
    │   ├── demo_kline/       # K 线 feature（竖屏页 + 横屏页 + 私有子组件）
    │   └── index/            # Demo 入口页
    ├── route/                # 路由相关（全局 RouteObserver）
    ├── theme/                # 应用主题（light/dark ThemeData + 主题模式管理）
    ├── utils/                # 工具（时间对齐、设备判断、横竖屏切换）
    └── widgets/              # 纯通用 UI 组件（与业务无关）
```

## 测试

```bash
flutter test
```

测试按 `lib/src/` 目录结构镜像组织，覆盖 config、data、utils、pages/common。
