# FlexiKline


## 背景


## 核心功能拆分

core/main.dart
负责主图(蜡烛)的绘制.

core/sub.dart
负责副图(指标)的绘制.

core/setting.dart
设置Kline参数, 及提供默认参数.

core/gesture.dart
负责管理手势操作

core/state.dart
负责数据状态的管理


测试1: 
I/flutter (16628): │ 🐛 KOKline	preprocessIndicatorData start at 2024-05-06 21:44:10.262303
I/flutter (16628): │ 🐛 KOKline	DADA	preprocess BASE[0, 100]true
I/flutter (16628): │ 🐛 KOKline	DADA	preprocess BASE[0, 100]true
I/flutter (16628): │ 🐛 KOKline	DADA	preprocess EMA => 5 spent:33246 microseconds
I/flutter (16628): │ 🐛 KOKline	DADA	preprocess EMA => 10 spent:12919 microseconds
I/flutter (16628): │ 🐛 KOKline	DADA	preprocess EMA => 20 spent:17212 microseconds
I/flutter (16628): │ 🐛 KOKline	DADA	preprocess EMA => 60 spent:9110 microseconds
I/flutter (16628): │ 🐛 KOKline	DADA	preprocess MA => 7 spent:5398 microseconds
I/flutter (16628): │ 🐛 KOKline	DADA	preprocess MA => 30 spent:3200 microseconds
I/flutter (16628): │ 🐛 KOKline	DADA	preprocess BOLL => BOLLParam{n:20, std:2} spent:41929 microseconds
I/flutter (16628): │ 🐛 KOKline	DADA	preprocess MACD => MACDParam{s:12, l:26, m:12} spent:40728 microseconds
I/flutter (16628): │ 🐛 KOKline	DADA	preprocess BASE[0, 100]true
I/flutter (16628): │ 🐛 KOKline	DADA	preprocess VOLMA => 5 spent:5085 microseconds
I/flutter (16628): │ 🐛 KOKline	DADA	preprocess VOLMA => 10 spent:3657 microseconds
I/flutter (16628): │ 🐛 KOKline	DADA	preprocess KDJ => KDJParam{n:9, m1:3, m2:3} spent:31168 microseconds
I/flutter (16628): │ 🐛 KOKline	preprocessIndicatorData completed!!! Total time spent 213188 milliseconds

测试2:
I/flutter (16628): │ 🐛 KOKline	preprocessIndicatorData start at 2024-05-06 21:44:35.192525
I/flutter (16628): │ 🐛 KOKline	DADA	preprocess BASE[0, 100]true
I/flutter (16628): │ 🐛 KOKline	DADA	preprocess BASE[0, 100]true
I/flutter (16628): │ 🐛 KOKline	DADA	preprocess EMA => 5 spent:45877 microseconds
I/flutter (16628): │ 🐛 KOKline	DADA	preprocess EMA => 10 spent:10058 microseconds
I/flutter (16628): │ 🐛 KOKline	DADA	preprocess EMA => 20 spent:13445 microseconds
I/flutter (16628): │ 🐛 KOKline	DADA	preprocess EMA => 60 spent:8348 microseconds
I/flutter (16628): │ 🐛 KOKline	DADA	preprocess MA => 7 spent:4703 microseconds
I/flutter (16628): │ 🐛 KOKline	DADA	preprocess MA => 30 spent:2215 microseconds
I/flutter (16628): │ 🐛 KOKline	DADA	preprocess BOLL => BOLLParam{n:20, std:2} spent:40761 microseconds
I/flutter (16628): │ 🐛 KOKline	DADA	preprocess MACD => MACDParam{s:12, l:26, m:12} spent:39644 microseconds
I/flutter (16628): │ 🐛 KOKline	DADA	preprocess BASE[0, 100]true
I/flutter (16628): │ 🐛 KOKline	DADA	preprocess VOLMA => 5 spent:4585 microseconds
I/flutter (16628): │ 🐛 KOKline	DADA	preprocess VOLMA => 10 spent:4152 microseconds
I/flutter (16628): │ 🐛 KOKline	DADA	preprocess KDJ => KDJParam{n:9, m1:3, m2:3} spent:29953 microseconds
I/flutter (16628): │ 🐛 KOKline	preprocessIndicatorData completed!!! Total time spent 221165 milliseconds