import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../data/models/kline_interval.dart';

/// 周期切换栏：选中态跟随 [selected]，点击只回调 [onSelected]，不改选中值。
class KlineIntervalBar extends StatefulWidget {
  const KlineIntervalBar({
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 0),
    required this.selected,
    required this.onSelected,
    this.intervals = KlineInterval.values,
  });

  final EdgeInsetsGeometry padding;

  /// 当前周期，由调用方持有。
  final ValueListenable<KlineInterval> selected;

  /// 点击某个周期时回调。
  final ValueChanged<KlineInterval> onSelected;

  /// 展示的周期列表。
  final List<KlineInterval> intervals;

  @override
  State<KlineIntervalBar> createState() => _KlineIntervalBarState();
}

class _KlineIntervalBarState extends State<KlineIntervalBar> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  KlineInterval get _selected => widget.selected.value;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.intervals.length,
      vsync: this,
      initialIndex: widget.intervals.indexOf(_selected),
    );
    widget.selected.addListener(_handleSelectedChanged);
  }

  @override
  void didUpdateWidget(covariant KlineIntervalBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      oldWidget.selected.removeListener(_handleSelectedChanged);
      widget.selected.addListener(_handleSelectedChanged);
    }
    if (widget.intervals != oldWidget.intervals) {
      _tabController.dispose();
      _tabController = TabController(
        length: widget.intervals.length,
        vsync: this,
        initialIndex: widget.intervals.indexOf(_selected),
      );
    }
  }

  /// [KlineIntervalBar.selected] 变化时同步 TabBar 选中态（点击后由调用方更新选中值也走这里）。
  void _handleSelectedChanged() {
    final index = widget.intervals.indexOf(_selected);
    if (index >= 0 && _tabController.index != index) {
      _tabController.animateTo(index);
    }
  }

  @override
  void dispose() {
    widget.selected.removeListener(_handleSelectedChanged);
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
          for (final interval in widget.intervals) Tab(text: interval.label),
        ],
        onTap: (index) => widget.onSelected(widget.intervals[index]),
      ),
    );
  }
}

extension on KlineInterval {
  String get label => switch (this) {
    KlineInterval.line => '分时',
    KlineInterval.minute15 => '15分',
    KlineInterval.hour1 => '1时',
    KlineInterval.day1 => '1天',
    KlineInterval.week1 => '1周',
  };
}
