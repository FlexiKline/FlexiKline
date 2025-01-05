v0.2.0
- [x] 新框架设计.
- [x] 待解决ma, ema指标位置定位.
- [x] 待解决ma, ema, candle 最大最小值.
- [x] 待解决最新价移出可视区后的变换.
- [x] macd指标计算与绘制.
- [x] 配置序列化反序列化框架实现.
- [x] 待解决指标配置管理.
- [x] 待解决calcuManager中数据缓存dirty.
- [x] 指标计算算法优化 (MAVOL, EMA, MACD).

v0.3.0
- [x] CandleModel重构(指标数据绑定到Model上).
- [x] 指标的定制化实现.
- [x] 指标计算与算法实现统一.
- [x] 优化核心框架状态可配置.
- [x] 配置管理调整: 由FlexiKlineConfig统一管理所有配置, FlexiKline构造时必传. 所有配置实现Serializer和CopyWith接口. 

v0.4.0
- [x] 主题切换实现.
- [x] 配置框架优化.
- [x] 数据加载接口封装.
- [x] 蜡烛数据合并算法优化.
- [x] 指标计算性能优化.
- [x] 手势操作优化.
- [x] Flutter最低支持版本

v0.5.0
- [x] 支持横屏.
- [x] 缩放优化.
- [x] 配置管理优化.
- [x] 添加指标要dispose解绑下. (clone需要给Indicator增加clone接口, 暂不考虑.)
- [x] 增加副图指标.

v0.6.0
- [x] 支持Desktop
- [x] 支持Web
- [x] 手势识别框架重构, 适配Web/Desktop
- [x] 自定义指标与替换内置指标demo.
- [x] 增加精度大于16的测试demo. 
- [x] 文档撰写v1.
- [x] 第一版: 1. 发布到pub; 2. github开源

v0.7.0
- [x] 画图工具实现.
- [x] 画图框架实现.
- [x] 序列化/反序列化Overlay.
- [x] 数据坐标转换; 要考虑支持股票数据计算; 平行通道计算优化.
- [x] 放大镜优化
- [x] 支持锁定/磁吸/隐藏/连续绘制/层级调整功能.
- [x] DrawObject 接口定义/层级调整; 
- [x] 绘制状态管理重构
- [x] 非触摸平台(Web)手势适配
- [x] 命名规范(使用on...还是语义化描述) + 配置优化
- [x] DrawType支持group; 
  
v0.8.0
- [x] 抽离指标管理功能, 并统一由manager管理; 优化Indicator与PaintObject依赖关系.
- [x] KlinData中指标计算数据与CandleModel分离(保持CandleModel的独立)
- [x] ~~重新设计CandleReq的蜡烛数据标识与查询更新方式, 并考虑兼容股市Kline;~~
- [x] 实现indicators对象和DrawObjects对象与框架分离(API接口优化)
- [x] 更新绘制工具图标; 遗留问题修复.
- [x] controller与core库接口优化(保护API不被滥用)
- [x] 通过对grid的网络线拖拽调整指标图表的高度.
- [x] 整体框架重构3.
- [x] 文档撰写v2.

v0.9.0
- [ ] 指标计算性能优化: 
  1. 更新蜡烛数据流程优化.
  2. 按需计算, 增加指标同时触发指标计算后, 再绘制.
  3. 考虑保留上次最新数据计算中间态, 当新数据更新时继续计算.
- [x] 完善demo; 实现所有配置功能.
- [ ] 针对主区指标, 指标框架进行调整, 可不设置高度/padding, 由MainIndicator来统一. (另volume高度可按主区高度比例配置)
- [x] 配置管理优化.
- [ ] 数据更新后绘制bugfix.
- [ ] 测试考虑废弃BagNum, 由double完成.
- [ ] 增加图表移动/数据变化等监听: 仅在需要绘制时重新draw; 
- [ ] DrawObject增加接口, 根据当前环境参数检测是否需要参与绘制.
- [x] 非触摸设备增加ESC取消绘制.(后续版本增加更多快捷操作)
- [ ] timestampToIndex算法优化; bugfix.
- [ ] 文档撰写v3.

v1.0.0
- [ ] websocket更新demo.
- [ ] Tooltip的绘制优化.
- [ ] 考虑对TextSpan绘制增加点击事件(考虑通过controller全局管理, 并通知到用户侧响应)
- [ ] 全部文档撰写v4.
- [ ] 全面调优.
