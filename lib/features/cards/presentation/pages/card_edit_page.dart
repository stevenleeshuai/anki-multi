import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/database_provider.dart';
import '../../application/card_service.dart';

class CardEditPage extends ConsumerStatefulWidget {
  const CardEditPage({super.key, this.deckId, this.editingCardId})
      : assert(
          (deckId != null) != (editingCardId != null),
          '必须只提供 deckId 或 editingCardId 其中一个',
        );

  final int? deckId;
  final int? editingCardId;

  @override
  ConsumerState<CardEditPage> createState() => _CardEditPageState();
}

class _CardEditPageState extends ConsumerState<CardEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _frontCtl = TextEditingController();
  final _backCtl = TextEditingController();
  bool _saving = false;
  int? _editingNoteId;

  bool get _isEditing => widget.editingCardId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      Future.microtask(_loadExistingCard);
    }
  }

  @override
  void dispose() {
    _frontCtl.dispose();
    _backCtl.dispose();
    super.dispose();
  }

  Future<void> _loadExistingCard() async {
    final db = ref.read(databaseProvider);
    final card = await db.cardsDao.getById(widget.editingCardId!);
    if (!mounted || card == null) return;
    final note = await db.notesDao.getById(card.noteId);
    if (!mounted || note == null) return;

    final fields = jsonDecode(note.fields) as Map<String, dynamic>;
    final front = (fields['正面'] ?? '').toString();
    final back = (fields['反面'] ?? '').toString();

    setState(() {
      _editingNoteId = note.id;
      _frontCtl.value = TextEditingValue(
        text: front,
        selection: TextSelection.collapsed(offset: front.length),
      );
      _backCtl.value = TextEditingValue(
        text: back,
        selection: TextSelection.collapsed(offset: back.length),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑卡片' : '新建卡片'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _frontCtl,
                autofocus: !_isEditing,
                decoration: const InputDecoration(
                  labelText: '正面',
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 5,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入正面' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _backCtl,
                decoration: const InputDecoration(
                  labelText: '反面',
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 8,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入反面' : null,
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

    final svc = ref.read(cardServiceProvider);
    final front = _frontCtl.text.trim();
    final back = _backCtl.text.trim();

    try {
      if (_isEditing) {
        if (_editingNoteId == null) {
          if (mounted) context.pop();
          return;
        }
        await svc.updateBasicCard(
          noteId: _editingNoteId!,
          front: front,
          back: back,
        );
      } else {
        await svc.createBasicCard(
          deckId: widget.deckId!,
          front: front,
          back: back,
        );
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
