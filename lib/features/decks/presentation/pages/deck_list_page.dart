import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/deck_service.dart';

class DeckListPage extends ConsumerWidget {
  const DeckListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(allDecksWithCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('anki_multi'),
      ),
      body: decksAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text('还没有牌组，点 + 新建一个'),
            );
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final item = list[i];
              return ListTile(
                leading: const Icon(Icons.folder),
                title: Text(item.deck.name),
                subtitle: Text('${item.cardCount} 张卡片'),
                onTap: () => context.push('/decks/${item.deck.id}'),
                onLongPress: () => _showDeckMenu(context, ref, item.deck.id),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('加载失败: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/decks/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeckMenu(BuildContext context, WidgetRef ref, int deckId) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('编辑'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/decks/$deckId/edit');
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('删除', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirm = await _confirmDelete(context);
                  if (confirm == true) {
                    await ref.read(deckServiceProvider).delete(deckId);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除牌组？'),
        content: const Text('该牌组及其所有卡片会被永久删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
