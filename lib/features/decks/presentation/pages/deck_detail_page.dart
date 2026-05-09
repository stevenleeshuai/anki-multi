import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../cards/application/card_service.dart';
import '../../application/deck_service.dart';

class DeckDetailPage extends ConsumerWidget {
  const DeckDetailPage({super.key, required this.deckId});

  final int deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deckAsync = ref.watch(deckByIdProvider(deckId));
    final cardsAsync = ref.watch(cardsByDeckProvider(deckId));

    return Scaffold(
      appBar: AppBar(
        title: deckAsync.when(
          data: (d) => Text(d?.name ?? '未知牌组'),
          loading: () => const Text('加载中…'),
          error: (_, __) => const Text('错误'),
        ),
      ),
      body: cardsAsync.when(
        data: (cards) {
          if (cards.isEmpty) {
            return const Center(child: Text('这个牌组还没有卡片'));
          }
          return ListView.separated(
            itemCount: cards.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final entry = cards[i];
              final fields = jsonDecode(entry.note.fields)
                  as Map<String, dynamic>;
              final front = (fields['正面'] ?? '').toString();
              return ListTile(
                title: Text(
                  front,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('卡片 #${entry.card.id}'),
                onTap: () => context.push('/cards/${entry.card.id}/edit'),
                onLongPress: () => _confirmDeleteCard(
                  context,
                  ref,
                  cardId: entry.card.id,
                  noteId: entry.note.id,
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/decks/$deckId/cards/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmDeleteCard(
    BuildContext context,
    WidgetRef ref, {
    required int cardId,
    required int noteId,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除卡片？'),
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
    if (ok == true) {
      await ref
          .read(cardServiceProvider)
          .deleteCard(cardId: cardId, noteId: noteId);
    }
  }
}
