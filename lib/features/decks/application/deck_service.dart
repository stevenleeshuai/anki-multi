import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/daos/decks_dao.dart';
import '../../../core/database/database.dart';
import '../../../core/database/database_provider.dart';

/// 监听全部牌组（带卡片数）。
final allDecksWithCountProvider =
    StreamProvider.autoDispose<List<DeckWithCount>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.decksDao.watchAllWithCount();
});

final deckByIdProvider =
    StreamProvider.autoDispose.family<Deck?, int>((ref, id) {
  final db = ref.watch(databaseProvider);
  return db.decksDao.watchById(id);
});

/// 操作类（mutation）：直接调用 DAO。
class DeckService {
  DeckService(this._db);

  final AppDatabase _db;

  Future<int> create(String name) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _db.decksDao.insertDeck(
      DecksCompanion.insert(name: name, createdAt: now, updatedAt: now),
    );
  }

  Future<bool> rename(int id, String name) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _db.decksDao.updateDeck(
      id,
      DecksCompanion(name: Value(name), updatedAt: Value(now)),
    );
  }

  Future<int> delete(int id) => _db.decksDao.deleteDeck(id);
}

final deckServiceProvider = Provider<DeckService>((ref) {
  return DeckService(ref.watch(databaseProvider));
});
