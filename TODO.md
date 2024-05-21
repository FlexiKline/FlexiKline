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
- [ ] 指标计算与算法实现统一.
- [x] 主题切换实现.
- [ ] 配置管理扩展: 由FlexiKlineConfig统一管理所有配置, FlexiKline构造时必传. 所有配置实现Serializer和CopyWith接口. 
- [ ] 框架调整: 将MultiPaintObjectIndicator改为abstract. 由不同功能的Indicator去实现多个Indicator的组合.

v0.4.0
- [ ] 数据加载接口封装.
- [ ] 数据合并算法优化.
- [ ] 手势操作优化.
- [ ] 测试start和end对调性能影响.

v0.5.0
- [ ] 支持横屏.
- [ ] 增加副图指标.

v0.6.0
- [ ] 画图工具实现.
- [ ] 画图框架实现.

v0.7.0
- [ ] 文档撰写.
- [ ] 全面调优.

v0.8.0
- [ ] 支持Desktop
- [ ] 支持Web
