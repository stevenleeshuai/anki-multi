import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/cards_table.dart';
import '../tables/decks_table.dart';

part 'decks_dao.g.dart';

class DeckWithCount {
  const DeckWithCount({required this.deck, required this.cardCount});

  final Deck deck;
  final int cardCount;
}

@DriftAccessor(tables: [Decks, Cards])
class DecksDao extends DatabaseAccessor<AppDatabase> with _$DecksDaoMixin {
  DecksDao(super.db);

  Stream<List<Deck>> watchAll() => select(decks).watch();

  Future<Deck?> getById(int id) =>
      (select(decks)..where((d) => d.id.equals(id))).getSingleOrNull();

  Future<int> insertDeck(DecksCompanion entry) => into(decks).insert(entry);

  Future<bool> updateDeck(int id, DecksCompanion entry) async {
    final affected =
        await (update(decks)..where((d) => d.id.equals(id))).write(entry);
    return affected > 0;
  }

  Future<int> deleteDeck(int id) =>
      (delete(decks)..where((d) => d.id.equals(id))).go();

  /// 牌组 + 该组中卡片数。用 left join 让没有卡片的牌组也返回 0。
  Stream<List<DeckWithCount>> watchAllWithCount() {
    final groupedQuery = customSelect(
      'SELECT d.*, COUNT(c.id) AS card_count '
      'FROM decks d '
      'LEFT JOIN cards c ON c.deck_id = d.id '
      'GROUP BY d.id '
      'ORDER BY d.created_at DESC',
      readsFrom: {decks, cards},
    );

    return groupedQuery.watch().map((rows) {
      return rows.map((row) {
        return DeckWithCount(
          deck: Deck(
            id: row.read<int>('id'),
            name: row.read<String>('name'),
            parentId: row.readNullable<int>('parent_id'),
            createdAt: row.read<int>('created_at'),
            updatedAt: row.read<int>('updated_at'),
          ),
          cardCount: row.read<int>('card_count'),
        );
      }).toList();
    });
  }
}
