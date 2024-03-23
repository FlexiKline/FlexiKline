import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kline/kline.dart';

ValueNotifier<int> valueNotifier = ValueNotifier(0);

class TestBody extends StatefulWidget {
  const TestBody({super.key});

  @override
  State<TestBody> createState() => _TestBodyState();
}

Size get drawableSize => Size(
      ScreenUtil().screenWidth,
      ScreenUtil().screenWidth * 2 / 3,
    );

class _TestBodyState extends State<TestBody> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: ScreenUtil().screenWidth,
      height: ScreenUtil().screenWidth * 2 / 3,
      // margin: EdgeInsetsDirectional.all(20.r),
      color: Colors.grey,
      child: RepaintBoundary(
        child: CustomPaint(
          size: drawableSize,
          painter: PathCustomPainter(value: valueNotifier),
          isComplex: true,
        ),
      ),
    );
  }
}

/// https://juejin.cn/post/7274536210731073572
/// Flutter 绘制路径 Path 的全部方法介绍，一篇足矣~ （三）
class PathCustomPainter extends CustomPainter {
  const PathCustomPainter({required this.value}) : super(repaint: value);
  final ValueNotifier<int> value;
  @override
  void paint(Canvas canvas, Size size) {
    debugPrint('zp::: paint>>> value${value.value}');
    debugPrint(
      'zp::: paint>>> size$size,  screenWidth:${ScreenUtil().screenWidth}',
    );
    drawText(canvas);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  // 向左绘制, 超过左边界
  void drawText3(Canvas canvas) {
    final offset = Offset(50, 100);
    canvas.drawText(
      offset: offset,
      drawDirection: DrawDirection.rtl,
      margin: EdgeInsets.symmetric(horizontal: 0),
      drawableSize: drawableSize,
      text: '你好123456789',
      style: TextStyle(
        fontSize: 20,
        color: Colors.black,
        overflow: TextOverflow.ellipsis,
      ),
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      // minWidth: 100,
      maxWidth: 100,
      padding: EdgeInsets.all(10),
      backgroundColor: Colors.yellowAccent,
      borderRadius: 10,
      borderWidth: 1,
      maxLines: 1,
      borderColor: Colors.red,
    );

    canvas.drawPoints(
      PointMode.points,
      [
        offset,
      ],
      Paint()
        ..color = Colors.blue
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke,
    );
  }

  void drawText2(Canvas canvas) {
    final offset = Offset(ScreenUtil().screenWidth - 20, 100);
    canvas.drawText(
      offset: offset,
      drawDirection: DrawDirection.rtl,
      text: '你好123456789',
      style: TextStyle(
        fontSize: 20,
        color: Colors.black,
        overflow: TextOverflow.ellipsis,
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      // minWidth: 100,
      // maxWidth: 100,
      padding: EdgeInsets.all(10),
      backgroundColor: Colors.yellowAccent,
      borderRadius: 10,
      borderWidth: 1,
      // maxLines: 1,
      borderColor: Colors.red,
    );

    canvas.drawPoints(
      PointMode.points,
      [
        offset,
      ],
      Paint()
        ..color = Colors.blue
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke,
    );
  }

  void drawText(Canvas canvas) {
    Offset offset = Offset(ScreenUtil().screenWidth - 100, 150);
    final size = canvas.drawText(
      offset: offset,
      drawDirection: DrawDirection.ltr,
      margin: EdgeInsets.symmetric(horizontal: 0),
      drawableSize: drawableSize,
      text: '你好123456',
      style: TextStyle(
        fontSize: 20,
        color: Colors.black,
        overflow: TextOverflow.ellipsis,
      ),
      // children: [
      //   TextSpan(
      //     text: '红色',
      //     style: TextStyle(fontSize: 18.0, color: Colors.red),
      //   ),
      //   TextSpan(
      //     text: '绿色',
      //     style: TextStyle(fontSize: 18.0, color: Colors.green),
      //   ),
      // ],
      textAlign: TextAlign.right,
      textDirection: TextDirection.ltr,
      // minWidth: 100,
      // maxWidth: 100,
      textWidth: 80,
      padding: EdgeInsets.all(10),
      backgroundColor: Colors.yellowAccent,
      borderRadius: 10,
      borderWidth: 1,
      maxLines: 1,
      borderColor: Colors.red,
    );

    canvas.drawPoints(
      PointMode.points,
      [
        offset,
      ],
      Paint()
        ..color = Colors.blue
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke,
    );
  }

  void drawCandle2(Canvas canvas) {
    final paint1 = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final paint2 = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;

    final dx = 10.0;

    canvas
      ..drawLine(
        Offset(dx, 100.0),
        Offset(dx, 200.0),
        paint1,
      )
      ..drawLine(
        Offset(dx, 120.0),
        Offset(dx, 170.0),
        paint2,
      );
  }

  /// 绘制Candle
  void drawCandle(Canvas canvas) {
    final path = Path();
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;
    final start = Offset(100, 100);
    final width = 10;
    final height = 40;
    final lineW = 2;
    // path.moveTo(start.dx + (width - lineW) / 2, start.dy - 10);
    // path.lineTo(start.dx + (width - lineW) / 2, start.dy);
    // path.moveTo(start.dx, start.dy);
    // path.addRect(Rect.fromLTWH(start.dx, start.dy, 10, 40));
    // path.moveTo(start.dx + (width - lineW) / 2, start.dy + height);
    // path.lineTo(start.dx + (width - lineW) / 2, start.dy + height + 20);
    // canvas.drawPath(
    //   path,
    //   Paint()
    //     ..color = Colors.red
    //     ..style = PaintingStyle.fill
    //     ..strokeWidth = 2,
    // );

    final p1 = Offset(start.dx + (width) / 2, start.dy - 20);
    final p2 = Offset(start.dx + (width) / 2, start.dy);
    final pp1 = Offset(start.dx + (width) / 2, start.dy + height);
    final pp2 = Offset(start.dx + (width) / 2, start.dy + height + 20);
    canvas
      ..drawLine(p1, p2, paint)
      ..drawRect(Rect.fromLTWH(start.dx, start.dy, 10, 40), paint)
      ..drawLine(pp1, pp2, paint);
  }

  /// 1. void addRect(Rect rect) 线描述的矩形
  /// 方法介绍: 该方法是创建一个新的子路径，该路径是由四条线描述的矩形。
  void addRect(Canvas canvas) {
    final Path path = Path();
    path.moveTo(100, 200);
    path.lineTo(200, 300);
    path.addRect(
      const Rect.fromLTWH(100, 30, 100, 100), // 矩形的4个点
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.purple
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  /// 2. void addOval(Rect oval) 内切椭圆
  /// 方法介绍: 该方法是新建一个路径，该路径是给定矩形的内切椭圆。
  void addOval(Canvas canvas) {
    final Path path = Path();
    path.moveTo(100, 200);
    path.lineTo(200, 200);
    path.addOval(Rect.fromCenter(
      center: const Offset(150, 100), // 矩形的中心点
      width: 200, // 矩形宽
      height: 100, // 矩形高
    ));
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.purple
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  /// 3. void addArc(Rect oval, double startAngle, double sweepAngle) 圆弧
  /// 方法介绍: 该方法是创建新的路径，该路径是给定矩形内切椭圆的一段圆弧。
  /// startAngle 和 sweepAngle 传入的值是弧度，而不是角度
  /// 矩形内切椭圆的一段圆弧的弧度:
  ///   右(0度/360度[pi*0或pi*2]) -> 下(90度[pi*0.5]) -> 左(180度[pi*1]) -> 上(270度[pi*1.5])
  /// startAngle: 指定起始弧度值
  /// sweepAngle: 指定弧度的长度
  void addArc(Canvas canvas) {
    final Path path = Path();
    path.moveTo(100, 100);
    path.lineTo(300, 100);
    path.addArc(
      Rect.fromCenter(
        center: const Offset(150, 200), // 矩形的中心点
        width: 200, // 矩形宽
        height: 100, // 矩形高
      ),
      pi * 0.5, // startAngle
      pi, // sweepAngle
    );
    path.addArc(
      Rect.fromCenter(
        center: const Offset(250, 200), // 矩形的中心点
        width: 200, // 矩形宽
        height: 100, // 矩形高
      ),
      pi * 0.3, // startAngle
      pi * 1, // sweepAngle
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.purple
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  /// 4. void addPolygon(List<Offset> points, bool close)  多边形路径
  /// 方法介绍: 该方法是创建新的路径，将给定的点依次连接起来形成的路径。
  /// @param close: 参数是决定新路径的起点和终点是否相连。
  void addPolygon(Canvas canvas) {
    final Path path = Path();
    // path.moveTo(100, 100);
    // path.lineTo(200, 100);
    path.addPolygon(
      const [
        Offset(200, 100),
        Offset(300, 200),
        Offset(200, 300),
      ],
      false,
    );
    path.addPolygon(
      const [
        Offset(100, 200),
        Offset(200, 200),
        Offset(100, 300),
      ],
      true, // 将上面起点(100,200)与终点(100,300)最后连接起来.
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.purple
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  ///5. void addRRect(RRect rrect) 圆角矩形
  ///方法介绍: 该方法是新创建一个子路径，该路径是由四条直线和四个圆弧组成的圆角矩形。
  void addRRect(Canvas canvas) {
    final Path path = Path();
    path.moveTo(100, 100);
    // path.lineTo(200, 150);
    path.reset();
    path.addRRect(
      RRect.fromLTRBR(
        100,
        100,
        300,
        200,
        const Radius.circular(5), // 圆角
      ),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.purple
        ..style = PaintingStyle.fill
        ..strokeWidth = 2,
    );
  }

  ///6. void addPath(Path path, Offset offset, {Float64List? matrix4})
  ///方法介绍: 添加新的路径，可以设置新路径的偏移以及矩阵处理。
  ///
  ///rotateZ: Z是起点?
  void addPath(Canvas canvas) {
    final Path path = Path();
    // path.moveTo(100, 100);
    // path.lineTo(200, 200);

    final Path path1 = Path();
    path1.moveTo(100, 100);
    path1.lineTo(200, 200);
    final Matrix4 matrix4 = Matrix4.identity();
    // matrix4.translate(100.0, 100.0); // 向右, 向下平移100
    // matrix4.scale(2); // 放大2倍: 即将path1的起点和终点(x,y)坐标值都乘以2
    matrix4.rotateZ(pi * 1.9); // 围绕 Z 旋转该矩阵 [pi/3] 弧度

    path.addPath(
      path1, // 要添加的子路径
      const Offset(0, 0), // 子路径相对于父路径的起点
      matrix4: matrix4.storage,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.purple
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  /// 7. void extendWithPath(Path path, Offset offset, {Float64List? matrix4})
  /// 方法介绍: 该方法和 void addPath(Path path, Offset offset, {Float64List? matrix4}) 方法的参数以及参数的意义都是一样的。
  /// 唯一不同的是 void addPath(Path path, Offset offset, {Float64List? matrix4}) 的视图效果是路径分离的，
  /// 而该方法的视图效果是将原有路径和新加路径进行连线。
  void extendWithPath(Canvas canvas) {
    final Path path = Path();
    path.moveTo(100, 100);
    path.lineTo(200, 200);

    final Path path1 = Path();
    path1.moveTo(300, 100);
    path1.lineTo(400, 200);
    final Matrix4 matrix4 = Matrix4.identity();
    // matrix4.translate(100.0, 100.0);
    // matrix4.scale(2.0);
    // matrix4.rotateZ(pi / 3);

    path.extendWithPath(path1, const Offset(0, 0), matrix4: matrix4.storage);

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.purple
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  ///8. void close()
  ///方法介绍: 该方法是关闭最后一个子路径。注: 关闭会连接起点与终点
  ///该方法在 Flutter 中调用非常简单，但是也需要注意的是路径单独路还是有子路径。
  ///1. 有子路径时， close 关闭的是最后一个子路径
  ///2. 只有一个路径，close 是关闭整个路径
  void close(Canvas canvas) {
    final Path path = Path();
    path.moveTo(100, 100);
    path.lineTo(200, 200);

    final Path path1 = Path();
    path1.moveTo(300, 100);
    path1.lineTo(400, 200);
    path1.lineTo(400, 500);
    // path1.close();

    path.extendWithPath(path1, Offset.zero);
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.purple
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  /// 9. void reset()
  /// 方法介绍: 删除所有子路径，将路径重置初始状态（Path path = Path();）。
  void reset(Canvas canvas) {
    final Path path = Path();
    path.moveTo(100, 100);
    path.lineTo(200, 200);
    final Path path1 = Path();
    path1.moveTo(200, 100);
    path1.lineTo(300, 200);
    path.addPath(path1, Offset.zero);
    path.reset(); // 以上path及子路径path1都将删除. path重置为初始状态.
    path.moveTo(300, 100);
    path.lineTo(200, 200);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.purple
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  ///10. bool contains(Offset point)
  ///方法介绍: 该方法是测试给定的点是否在路径内。
  /// 测试的点只要是在路径闭合的区域内，无论你是否闭合路径，测试的结果都是 true。
  /// 需要注意的是在路径有很多子路径时，检测点是检测点是否在最后一个路径的闭合区域。
  void contains(Canvas canvas) {
    final Path path = Path();
    path.moveTo(100, 100);
    path.lineTo(150, 200);

    final Path path1 = Path();
    path1.moveTo(200, 100);
    path1.lineTo(300, 100);
    path1.lineTo(200, 200);
    // path1.close();

    path.addPath(path1, Offset.zero);
    // path.close();

    final bool isContains = path.contains(
      const Offset(200, 200), // 待测试hkko
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = isContains ? Colors.red : Colors.purple
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  /// 11. Path shift(Offset offset)
  /// 方法介绍: 该方法是将路径所有子路径全部复制一份，然后添加给定的偏移量。
  void shift(Canvas canvas) {
    final Path path = Path();
    path.moveTo(100, 100);
    path.lineTo(200, 200);
    final Path path1 = Path();
    path1.moveTo(200, 100);
    path1.lineTo(300, 200);
    path.addPath(path1, Offset.zero);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.purple
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final Path path2 = path.shift(const Offset(-100, 100));
    canvas.drawPath(
      path2,
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  ///12. Path transform(Float64List matrix4)
  ///方法介绍: 创建路径的所有子路径，经过矩阵转换后的副本。
  void transform(Canvas canvas) {
    final Path path = Path();
    path.moveTo(100, 100);
    path.lineTo(200, 200);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.purple
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final Matrix4 matrix4 = Matrix4.identity();
    // matrix4.translate(100.0);
    // matrix4.scale(2.0);
    matrix4.rotateZ(pi / 6);
    // 矩阵转换后的副本path1。
    final Path path1 = path.transform(matrix4.storage);
    canvas.drawPath(
      path1,
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  ///13. Rect getBounds()
  ///方法介绍: 该方法是计算路径的边界矩形。
  /// 获取所有路径, 在(x,y)坐标系中最大最小值形成的矩形.
  void getBounds(Canvas canvas) {
    final Path path = Path();
    path.moveTo(100, 100);
    path.lineTo(200, 200);

    final Path path1 = Path();
    path1.moveTo(200, 100);
    path1.lineTo(300, 300);
    // path.addPath(path1, Offset.zero);
    path.extendWithPath(path1, Offset.zero);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.purple
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.drawRect(
      path.getBounds(),
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  /// 14. static Path combine(PathOperation operation, Path path1, Path path2)
  /// 方法介绍: 根据指定形式组合两条路径生成新的路径。
  /// PathOperation 是路径整合形式控制参数，它是个枚举；它的枚举类型如下：
  /// - difference: 这是从第一个路径中减去第二个路径并生成新的路径。
  /// - intersect: 这是将两个路径重叠的部分创建为一个新的路径。
  /// - union: 这是将两个路径进行合并创建一个新的路径。
  /// - xor: 这是将两个路径进行异或创建新的路径。
  void combine(Canvas canvas) {
    final Path path1 = Path();
    path1.moveTo(100, 00);
    path1.lineTo(0, 200);
    path1.lineTo(200, 200);
    path1.close();

    canvas.drawPath(
      path1,
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final Path path2 = Path();
    path2.moveTo(150, 100);
    path2.lineTo(300, 100);
    path2.lineTo(200, 300);
    path2.lineTo(50, 300);
    path2.close();

    canvas.drawPath(
      path2,
      Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 根据PathOperation参数合并path1和path2的区域
    final Path path = Path.combine(
      // PathOperation.difference, // path1 减去 path2的部分
      // PathOperation.intersect, // path1 和 path2的交集
      // PathOperation.union, // path1 和 path2的共集
      // PathOperation.xor, // 去掉交集后的图形
      PathOperation.reverseDifference, // path2 减去 path1的部分
      path1,
      path2,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.purple
        ..style = PaintingStyle.fill
        ..strokeWidth = 2,
    );
  }

  /// 15. PathMetrics computeMetrics({bool forceClosed = false})
  /// 方法介绍: 该方法是对路径进行测量，可以获取路径相关的信息。
  void computeMetrics(Canvas canvas) {
    final Path path = Path();
    path.moveTo(100, 100);
    path.lineTo(200, 200);

    final Path path1 = Path();
    path1.moveTo(200, 200);
    path1.lineTo(200, 300);

    path.extendWithPath(path1, Offset.zero);
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.purple
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final PathMetrics pathMetrics = path.computeMetrics();
    final PathMetric pathMetric = pathMetrics.first;
    // 路径索引
    print('zp::: ${pathMetric.contourIndex}');
    // 路径是否关闭
    print('zp::: ${pathMetric.isClosed}');
    // 路径的长度
    print('zp::: ${pathMetric.length}');
    // 扩展新的路径
    print('zp::: ${pathMetric.extractPath(10, 20)}');
    // 计算给定路径偏移的位置以及切角
    print('zp::: ${pathMetric.getTangentForOffset(10)}');
  }

  /// void relativeArcToPoint(Offset arcEndDelta, {Radius radius = Radius.zero,double rotation = 0.0,bool largeArc = false,bool clockwise = true,})
  /// 该方法和 arcToPoint 方法基本一样，具体的细节和视图展示效果请查看 arcToPoint 方法的介绍。
  /// 该方法的和 arcToPoint 的唯一区别是该方法是以路径的最后一个点为新的原点，
  /// 而 arcToPoint 是以绘制 (0,0) 点为原点。其实就是选择的参考点不一样而已。
  void relativeArcToPoint(Canvas canvas) {
    final Path path = Path();
    path.moveTo(100, 200);
    path.lineTo(200, 200);
    path.relativeArcToPoint(
      const Offset(100, 100),
      radius: const Radius.circular(60),
      largeArc: true,
      clockwise: true,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.purple
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  //// void arcToPoint(Offset arcEnd, {Radius radius = Radius.zero,double rotation = 0.0,bool largeArc = false,bool clockwise = true,})
  //// 该方法是从路径的最后一个点到给定点绘制曲线，
  ///  同时，它还有 radius 、 rotation、largeArc 、 clockwise 四个参数可以自定义，以改变曲线的样式。
  /// 该方法不同的参数有不同的表现形式，我们下面一一探究。首先我们先设定:
  ///   1. d 为路径最后一个点到 arcEnd 点连线距离的一半；
  ///   2. c 为路径最后一个点到 arcEnd 点连线的中心；
  ///   3. r 为设置的 radius 参数。
  /// 下面我们介绍各个参数不同导致绘制的视图效果不同。
  /// 1. 如果该方法只传递一个 arcEnd 参数，并且 arcEnd 不等于路径的最后一个点，该方法将会展示一条从路径的最后一个点到 arcEnd点的直线。
  /// 2. 在 arcEnd 不等于路径的最后一个点时，同时设置 radius 参数时，该方的视图表现受 r和 d 的大小关系而影响。假如，
  /// 2.1 r <= d 则方法的视图表现为以 c 为圆点，以 d 为半径，绘制的半圆。
  /// 2.2 当 r > d 时 （假设：最后一个点为 (x1,y1)）， 该函数表现的视图效果是以 (x1 + d, 根号r^2 - d^2) 点为圆点， r 为半径的圆的圆弧的一段。
  /// 3. 在方法中 largeArc 参数是设置视图绘制的是大弧还是小弧。该参数的视图效果，又受 r 和 d 的大小关系影响。
  /// 3.1 如果 largeArc 为 false 时， 当 r <= d 时，绘制的是半圆；当 r > d 时绘制的是一小段圆弧。
  /// 3.2 如果 largeArc 为 true 时， 当 r <= d 时，绘制的是半圆；当 r > d 时绘制的是一大段圆弧。
  /// 总结:该参数主要影响的是当r > d 时， 如果 largeArc = true 时， 绘制的是大弧，否则绘制的是小弧。
  /// 4. 参数 clockwise 是设置绘制弧度的方向是顺时针还是逆时针。
  ///   其实它很好理解，可以理解为 clockwise 设置为 true 或者 false 它们的图案是沿着 路径最后一个点到 arcEnd 点的连线对称即可。
  /// 5. rotation 参数，该方法的文档注释是绘制曲线旋转。
  ///   经过测试发现无论怎么设置该参数都没有效果。经过底层代码查看，发现该参数在底层生成的变量没有使用，
  void arcToPoint(Canvas canvas) {
    final Path path = Path();
    path.moveTo(100, 200);
    path.arcToPoint(
      const Offset(200, 200),
      radius: const Radius.circular(40),
      largeArc: true,
      clockwise: true,
      rotation: 660,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.purple
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final Path path1 = Path();
    path1.moveTo(200, 200);
    path1.arcToPoint(
      const Offset(300, 200),
      radius: const Radius.circular(60),
      largeArc: true,
      clockwise: true,
      rotation: 90080,
    );
    canvas.drawPath(
      path1,
      Paint()
        ..color = Colors.purple
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.drawPoints(
      PointMode.points,
      [
        const Offset(100, 200),
        const Offset(200, 200),
        // const Offset(150, 200),
        const Offset(200, 200),
        const Offset(300, 200),
        // Offset(450, 200 - sqrt(pow(60, 2) - pow(50, 2)))
      ],
      Paint()
        ..color = Colors.red
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke,
    );
  }

  /// void arcTo(Rect rect, double startAngle, double sweepAngle, bool forceMoveTo)
  /// 该方法是在给定的矩形中创建一段内切椭圆的一段圆弧，
  /// 如果参数 forceMoveTo 为 true 则新起一段路径添加一段圆弧；
  /// 如果为false,则是直接添加一条线段和一段圆弧。
  void arcTo(Canvas canvas) {
    final Path path = Path();
    path.moveTo(100, 100);
    path.arcTo(
      Rect.fromCenter(
        center: const Offset(200, 200),
        width: 300,
        height: 200,
      ),
      pi * 0,
      pi * 1,
      false, //forceMoveTo
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.purple
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: const Offset(200, 200),
        width: 300,
        height: 200,
      ),
      Paint()
        ..color = Colors.red.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.drawPoints(
      PointMode.points,
      [const Offset(200, 200)],
      Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );

    canvas.drawPoints(
      PointMode.points,
      [const Offset(100, 100)],
      Paint()
        ..color = Colors.red.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );
  }

  /// void relativeConicTo(double x1, double y1, double x2, double y2, double w)
  /// 该方法的从当前点开始偏移 (x1,y1)点为控制点，并以 w 为权重，生成到当前点偏移 (x2,y2) 点的曲线。
  /// 注意: 当前点的偏移点也可以理解为以当前点为新的原点的点。
  void relativeConicTo(Canvas canvas) {
    final Path path = Path();
    path.moveTo(100, 200);
    path.relativeConicTo(100, -200, 200, 0, 2);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.purple
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.drawPoints(
      PointMode.points,
      const [
        Offset(100, 200),
        Offset(200, 0),
        Offset(300, 200),
      ],
      Paint()
        ..color = Colors.green
        ..strokeWidth = 6,
    );
  }

  /// void conicTo(double x1, double y1, double x2, double y2, double w)
  /// 该方法是创建从当前点到 (x2,y2)点的贝塞尔曲线，并以 (x1,y1) 为控制点；w 为曲线的权重。
  /// 权重：是控制点对曲线的影响程度。
  /// w > 1 时，曲线是双曲线；
  /// w = 1 时，曲线是抛物线；
  /// w < 1 时，曲线是椭圆;
  /// w = 0 时，曲线是直线。
  void conicTo(Canvas canvas) {
    final Path path = Path();
    path.moveTo(50, 100);
    path.conicTo(200, 10, 300, 100, 6);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.purple
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final Path path1 = Path();
    path1.moveTo(50, 100);
    path1.conicTo(200, 10, 300, 100, 1);
    canvas.drawPath(
      path1,
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final Path path2 = Path();
    path2.moveTo(50, 100);
    path2.conicTo(200, 10, 300, 100, 0.5);
    canvas.drawPath(
      path2,
      Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final Path path3 = Path();
    path3.moveTo(50, 100);
    path3.conicTo(200, 10, 300, 100, 0);
    canvas.drawPath(
      path3,
      Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.drawPoints(
      PointMode.points,
      const [
        Offset(50, 100),
        Offset(200, 10),
        Offset(300, 100),
      ],
      Paint()
        ..color = Colors.green
        ..strokeWidth = 6,
    );
  }

  /// 由四个点构造的三阶贝塞尔曲线
  /// void relativeCubicTo(double x1, double y1, double x2, double y2, double x3, double y3)
  /// 该方法是：添加以当前点开始到偏移 (x3,y3) 点的三阶贝塞尔曲线,并以当前点偏移 (x1,y1) 和 (x2,y2) 为控制点。
  void relativeCubicTo(Canvas canvas) {
    final Path path = Path();
    path.moveTo(20, 100); // (x0, y0)
    // (x1:100, y1:-80) - (x2:200, y2: 80) - (x3:300, y3:0)
    path.relativeCubicTo(100, -80, 200, 80, 300, 0);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.drawPoints(
      PointMode.points,
      const [
        Offset(20, 100), // (x0, y0)
        Offset(120, 20), // (x0+x1, y0+x1)
        Offset(220, 180), // (x0+x2, y0+y2)
        Offset(320, 100), // (x0+x3, y0+y3)
      ],
      Paint()
        ..color = Colors.green
        ..strokeWidth = 6,
    );
  }

  /// 由四个点构造的三阶贝塞尔曲线
  /// void cubicTo(double x1, double y1, double x2, double y2, double x3, double y3)
  /// 该方法是从当前点创建以 (x1,y1) 和 (x2,y2) 为控制点的三阶贝塞尔曲线。
  void cubicTo(Canvas canvas) {
    final Path path = Path();
    path.moveTo(20, 100); // (x0, y0)
    // (x1:100, x2:20) - (x2:200, y2: 180) - (x3:300, y3: 100)
    path.cubicTo(100, 20, 200, 180, 300, 100);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.drawPoints(
      PointMode.points,
      const [
        Offset(20, 100), // (x0, y0)
        Offset(100, 20), // (x1, y1)
        Offset(200, 180), // (x2, y2)
        Offset(300, 100), // (x3, y3)
      ],
      Paint()
        ..color = Colors.green
        ..strokeWidth = 6,
    );
  }

  /// 由三个点构造的三角形 组成的 二阶贝塞尔曲线
  /// void relativeQuadraticBezierTo(double x1, double y1, double x2, double y2)
  /// 该方法是在当前点偏移（x1,y1）处为控制点，添加到当前点偏移 (x2，y2) 的贝塞尔曲线。
  void relativeQuadraticBezierTo(Canvas canvas) {
    final Path path = Path();
    path.moveTo(20, 100);
    path.quadraticBezierTo(100, 200, 200, 100);
    path.relativeQuadraticBezierTo(50, 100, 150, 0);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.drawPoints(
      PointMode.points,
      const [
        Offset(20, 100), // (x0, y0)
        Offset(100, 200), // (x1, y1)
        Offset(200, 100), // (x2, y2)
        Offset(250, 200), // (x3, y3)
        Offset(350, 100), // (x3, y3)
      ],
      Paint()
        ..color = Colors.green
        ..strokeWidth = 6,
    );
  }

  /// void quadraticBezierTo(double x1, double y1, double x2, double y2)
  /// 该方法是使用控制点 (x1,y1) 添加从当前点到给定点 (x2,y2) 的二阶贝塞尔曲线段。
  void quadraticBezierTo(Canvas canvas) {
    final Path path = Path();
    path.moveTo(100, 100);
    path.quadraticBezierTo(200, 200, 300, 100);
    path.moveTo(100, 200);
    path.quadraticBezierTo(200, 300, 300, 200);
    path.moveTo(150, 100);
    path.quadraticBezierTo(250, 200, 350, 100);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  /// void relativeLineTo(double dx, double dy)
  /// 在距当前点,给定偏移 (dx,dy) 处创建新的子路径。
  void relativeLineTo(Canvas canvas) {
    final Path path = Path();
    path.moveTo(50, 50);
    path.lineTo(100, 50);
    path.relativeLineTo(50, 100); // 以(100,50)为原点移动(50,100) => (150, 150)
    path.relativeLineTo(50, 0); // 以(150, 150)为原点, 由于y是0,即x平移50
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = Colors.blue,
    );
  }

  /// void lineTo(double x, double y)
  /// 该方法是添加从当前点到 (dx,dy) 的直线
  void lineTo(Canvas canvas) {
    final Path path = Path();
    path.moveTo(10, 10);
    path.lineTo(100, 10);
    path.moveTo(10, 30); // 以(0,0)为原点, 移动到(10,30)
    path.lineTo(100, 30);
    path.lineTo(100, 60);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  /// void relativeMoveTo(double dx, double dy)
  /// 该方法是在当前点的（dx，dy）偏移处创建新的路径。
  /// 注意:该方法是以当前点为原点坐标，计算 (dx,dy) 的偏移。
  void relativeMoveTo(Canvas canvas) {
    final Path path = Path();
    path.moveTo(10, 100);
    path.lineTo(100, 100);
    path.relativeMoveTo(100, 100); // 以当前点(100,100)为原点移动(100,100), 移动后即(200,200)
    path.lineTo(200, 10);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = Colors.red,
    );
  }

  /// void moveTo(double x, double y)
  /// 该方法是一个实例方法，它是在给定坐标处 (x,y) 创建新的子路径。
  void moveTo(Canvas canvas) {
    // moveTo 移动画笔起始点
    final Path path = Path();
    // move1
    path.moveTo(100, 100);
    path.lineTo(200, 100);
    // move2
    path.moveTo(100, 200);
    path.lineTo(200, 200);
    // draw
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12,
    );
  }

  /// Path 的创建
  /// 路径创建方式
  /// factory Path.from(Path source): 该方法是通过对一个路径进行复制形成一个新的路径。
  void createPath(Canvas canvas) {
    // 1. 创建一个空的 Path
    final Path path = Path();
    debugPrint(path.toString());

    // 2. Path.from
    // source path
    final Path path1 = Path();
    path1.moveTo(10, 60);
    path1.lineTo(200, 60);
    // from 构建
    final Path pathFrom = Path.from(path1);
    canvas.drawPath(
      pathFrom,
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12,
    );
  }
}
