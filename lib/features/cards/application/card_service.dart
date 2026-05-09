import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/daos/cards_dao.dart';
import '../../../core/database/database.dart';
import '../../../core/database/database_provider.dart';

final cardsByDeckProvider =
    StreamProvider.autoDispose.family<List<CardWithNote>, int>((ref, deckId) {
  final db = ref.watch(databaseProvider);
  return db.cardsDao.watchByDeck(deckId);
});

class CardService {
  CardService(this._db);

  static const _frontFieldName = '正面';
  static const _backFieldName = '反面';

  final AppDatabase _db;

  /// 在 [deckId] 下创建一张 Basic 卡片。返回 cardId。
  Future<int> createBasicCard({
    required int deckId,
    required String front,
    required String back,
  }) async {
    // TODO(v1.0): 用 _db.transaction 包住 note + card 两个 insert，避免崩溃留孤儿。
    final basic = await _db.noteTypesDao.getByName('Basic');
    if (basic == null) {
      throw StateError('NoteType "Basic" 未 seed，无法创建 Basic 卡片');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final fieldsJson = jsonEncode({_frontFieldName: front, _backFieldName: back});

    final noteId = await _db.notesDao.insertNote(
      NotesCompanion.insert(
        noteTypeId: basic.id,
        fields: fieldsJson,
        createdAt: now,
        updatedAt: now,
      ),
    );

    return _db.cardsDao.insertCard(
      CardsCompanion.insert(
        noteId: noteId,
        deckId: deckId,
        due: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  /// 编辑 Basic 卡片：修改其 note 的 fields。
  Future<bool> updateBasicCard({
    required int noteId,
    required String front,
    required String back,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final fieldsJson = jsonEncode({_frontFieldName: front, _backFieldName: back});
    return _db.notesDao.updateNote(
      noteId,
      NotesCompanion(
        fields: Value(fieldsJson),
        updatedAt: Value(now),
      ),
    );
  }

  /// 删除一张卡片（同时删除背后的 note，因为 v0.1 是 1 note → 1 card 模型）。
  Future<void> deleteCard({required int cardId, required int noteId}) async {
    // 先删 card 再删 note：当 v1.0 加了 FK ON DELETE RESTRICT，反过来会失败。
    // TODO(v1.0): 用 _db.transaction 包住下面两步删除。
    await _db.cardsDao.deleteCard(cardId);
    await _db.notesDao.deleteNote(noteId);
  }
}

final cardServiceProvider = Provider<CardService>((ref) {
  return CardService(ref.watch(databaseProvider));
});
