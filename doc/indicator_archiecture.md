

```dart
interface PaintObject<T extends Indicator> {

    void precompute(KlineData data, {int? start, int? end});


    MinMax? initState(int start, int end);


    void didUpdateIndicator(T oldIndicator);


    void paint(IPaintContext context, Canvas canvas);


    void onCross(Canvas canvas, CandleModel model);


    void paintTips(Canvas canvas);
}
```


```dart
// 负责管理Indicator配置获取与PaintObject实例
class PaintObjectManager {

    
}
```