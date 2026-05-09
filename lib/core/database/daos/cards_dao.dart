import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/cards_table.dart';
import '../tables/notes_table.dart';

part 'cards_dao.g.dart';

class CardWithNote {
  const CardWithNote({required this.card, required this.note});

  final Card card;
  final Note note;
}

@DriftAccessor(tables: [Cards, Notes])
class CardsDao extends DatabaseAccessor<AppDatabase> with _$CardsDaoMixin {
  CardsDao(super.db);

  Future<int> insertCard(CardsCompanion entry) => into(cards).insert(entry);

  Future<Card?> getById(int id) =>
      (select(cards)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<int> deleteCard(int id) =>
      (delete(cards)..where((c) => c.id.equals(id))).go();

  Future<int> deleteCardsByNote(int noteId) =>
      (delete(cards)..where((c) => c.noteId.equals(noteId))).go();

  /// 监听某牌组下所有卡片（带 note 联表，用于显示正面/反面）。
  Stream<List<CardWithNote>> watchByDeck(int deckId) {
    final query = select(cards).join([
      innerJoin(notes, notes.id.equalsExp(cards.noteId)),
    ])
      ..where(cards.deckId.equals(deckId))
      ..orderBy([OrderingTerm.desc(cards.createdAt)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return CardWithNote(
          card: row.readTable(cards),
          note: row.readTable(notes),
        );
      }).toList();
    });
  }
}
