import 'package:flutter/material.dart';

import '../../../config/my_kline_interval.dart';

/// 周期切换栏：选中态由 [intervalNotifier] 驱动，点击回写 notifier 并回调 [onChanged]。
class MyKlineIntervalBar extends StatefulWidget {
  const MyKlineIntervalBar({
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 0),
    required this.intervalNotifier,
    required this.onChanged,
    this.supportedIntervals = MyKlineInterval.values,
  });

  final EdgeInsetsGeometry padding;

  /// 当前周期 notifier，由页面持有并初始化，本组件负责回写。
  final ValueNotifier<MyKlineInterval> intervalNotifier;

  /// 点击周期切换回调。
  final ValueChanged<MyKlineInterval> onChanged;

  /// 支持的周期列表。
  final List<MyKlineInterval> supportedIntervals;

  @override
  State<MyKlineIntervalBar> createState() => _MyKlineIntervalBarState();
}

class _MyKlineIntervalBarState extends State<MyKlineIntervalBar> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  MyKlineInterval get _selected => widget.intervalNotifier.value;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.supportedIntervals.length,
      vsync: this,
      initialIndex: widget.supportedIntervals.indexOf(_selected),
    );
    widget.intervalNotifier.addListener(_handleSelectedChanged);
  }

  @override
  void didUpdateWidget(covariant MyKlineIntervalBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.intervalNotifier != oldWidget.intervalNotifier) {
      oldWidget.intervalNotifier.removeListener(_handleSelectedChanged);
      widget.intervalNotifier.addListener(_handleSelectedChanged);
    }
    if (widget.supportedIntervals != oldWidget.supportedIntervals) {
      _tabController.dispose();
      _tabController = TabController(
        length: widget.supportedIntervals.length,
        vsync: this,
        initialIndex: widget.supportedIntervals.indexOf(_selected),
      );
    }
  }

  /// 外部（非本组件点击）改动选中值时，同步 TabBar 选中态。
  void _handleSelectedChanged() {
    final index = widget.supportedIntervals.indexOf(_selected);
    if (index >= 0 && _tabController.index != index) {
      _tabController.animateTo(index);
    }
  }

  void _onTap(int index) {
    final interval = widget.supportedIntervals[index];
    widget.intervalNotifier.value = interval;
    widget.onChanged(interval);
  }

  @override
  void dispose() {
    widget.intervalNotifier.removeListener(_handleSelectedChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        tabs: [
          for (final interval in widget.supportedIntervals) Tab(text: interval.label),
        ],
        onTap: _onTap,
      ),
    );
  }
}
