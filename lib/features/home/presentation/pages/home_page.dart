import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('anki_multi'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 64),
            const SizedBox(height: 16),
            Text(
              'Hello, anki_multi!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            FutureBuilder<int>(
              future: db.select(db.decks).get().then((r) => r.length),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Text('正在连接数据库...');
                }
                return Text('数据库已连接，当前牌组数: ${snapshot.data}');
              },
            ),
          ],
        ),
      ),
    );
  }
}
