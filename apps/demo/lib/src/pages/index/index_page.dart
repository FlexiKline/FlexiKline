import 'package:flutter/material.dart';

import '../demo_kline/demo_kline_page.dart';

/// 本地 demo 清单项：标题 + 简介 + 页面构建器。
class _DemoEntry {
  const _DemoEntry({
    required this.title,
    required this.description,
    required this.pageBuilder,
  });

  final String title;
  final String description;
  final Widget Function() pageBuilder;
}

/// Demo 入口页：形态清单 + 跳转，新形态往 [_entries] 加一条即可。
class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  late final List<_DemoEntry> _entries = [
    _DemoEntry(
      title: 'K 线（BTC-USDT）',
      description: '分时 / 15分 / 1时 / 1天 / 1周 + 模拟实时推送',
      pageBuilder: () => const DemoKlinePage(),
    ),
  ];

  void _openEntry(_DemoEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => entry.pageBuilder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('FlexiKline Demo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'K 线演示',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '基于 flexi_kline 框架，离线 mock 数据。',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          for (final entry in _entries)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(entry.title),
                subtitle: Text(entry.description),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openEntry(entry),
              ),
            ),
        ],
      ),
    );
  }
}
