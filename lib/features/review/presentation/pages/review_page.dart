import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:go_router/go_router.dart';

import '../../../../core/database/daos/cards_dao.dart';
import '../../application/review_providers.dart';

class ReviewPage extends ConsumerStatefulWidget {
  const ReviewPage({super.key, required this.deckId});

  final int deckId;

  @override
  ConsumerState<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends ConsumerState<ReviewPage> {
  static const _frontKey = '正面';
  static const _backKey = '反面';

  CardWithNote? _current;
  bool _loading = true;
  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _showBack = false;
    });
    final svc = ref.read(reviewServiceProvider);
    final next = await svc.peekNextDue(widget.deckId);
    if (!mounted) return;
    setState(() {
      _current = next;
      _loading = false;
    });
  }

  Future<void> _onRate(fsrs.Rating rating) async {
    final cur = _current;
    if (cur == null) return;

    try {
      await ref.read(reviewServiceProvider).rateCard(
            deckId: widget.deckId,
            cardId: cur.card.id,
            rating: rating,
          );
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
      return;
    }

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('复习'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final cur = _current;
    if (cur == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('暂无待复习卡片'),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('返回'),
            ),
          ],
        ),
      );
    }

    final fields = jsonDecode(cur.note.fields) as Map<String, dynamic>;
    final front = (fields[_frontKey] ?? '').toString();
    final back = (fields[_backKey] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: _showBack
                  ? Text(back, style: Theme.of(context).textTheme.titleLarge)
                  : Text(front, style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          const SizedBox(height: 16),
          if (!_showBack)
            FilledButton.tonal(
              onPressed: () => setState(() => _showBack = true),
              child: const Text('翻面'),
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.tonal(
                  onPressed: () => _onRate(fsrs.Rating.again),
                  child: const Text('Again'),
                ),
                FilledButton.tonal(
                  onPressed: () => _onRate(fsrs.Rating.hard),
                  child: const Text('Hard'),
                ),
                FilledButton(
                  onPressed: () => _onRate(fsrs.Rating.good),
                  child: const Text('Good'),
                ),
                FilledButton(
                  onPressed: () => _onRate(fsrs.Rating.easy),
                  child: const Text('Easy'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
