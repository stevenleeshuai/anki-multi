import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/deck_service.dart';

class DeckEditPage extends ConsumerStatefulWidget {
  const DeckEditPage({super.key, this.deckId});

  /// 为 null 时创建，否则编辑。
  final int? deckId;

  @override
  ConsumerState<DeckEditPage> createState() => _DeckEditPageState();
}

class _DeckEditPageState extends ConsumerState<DeckEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  bool _saving = false;
  bool _initialized = false;

  bool get _isEditing => widget.deckId != null;

  @override
  void dispose() {
    _nameCtl.dispose();
    super.dispose();
  }

  Future<void> _loadIfEditing() async {
    if (_initialized || !_isEditing) {
      _initialized = true;
      return;
    }
    final deck = await ref.read(deckByIdProvider(widget.deckId!).future);
    if (deck != null && mounted) {
      _nameCtl.text = deck.name;
    }
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadIfEditing(),
      builder: (context, snap) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_isEditing ? '编辑牌组' : '新建牌组'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameCtl,
                    decoration: const InputDecoration(
                      labelText: '牌组名称',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '请输入名称' : null,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving ? null : () => context.pop(),
                          child: const Text('取消'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          onPressed: _saving ? null : _onSave,
                          child: Text(_saving ? '保存中…' : '保存'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final svc = ref.read(deckServiceProvider);
    final name = _nameCtl.text.trim();

    if (_isEditing) {
      await svc.rename(widget.deckId!, name);
    } else {
      await svc.create(name);
    }

    if (mounted) context.pop();
  }
}
