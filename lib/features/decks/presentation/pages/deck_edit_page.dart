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

  bool get _isEditing => widget.deckId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      Future.microtask(_loadExistingName);
    }
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    super.dispose();
  }

  Future<void> _loadExistingName() async {
    final deck = await ref.read(deckByIdProvider(widget.deckId!).future);
    if (!mounted || deck == null) return;
    _nameCtl.value = TextEditingValue(
      text: deck.name,
      selection: TextSelection.collapsed(offset: deck.name.length),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                autofocus: !_isEditing,
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
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final svc = ref.read(deckServiceProvider);
    final name = _nameCtl.text.trim();

    try {
      if (_isEditing) {
        await svc.rename(widget.deckId!, name);
      } else {
        await svc.create(name);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
      setState(() => _saving = false);
    }
  }
}
