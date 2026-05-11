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

  /// 含默认 FSRS learningSteps（1m / 10m）：Learning/Relearning 点 Again 后 `due`
  /// 会落在「未来几分钟」，仅用 `due <= now` 会让会话误以为已无卡可学。
  static const int _learningDueHorizonMs = 20 * 60 * 1000;

  Future<int> insertCard(CardsCompanion entry) => into(cards).insert(entry);

  Future<Card?> getById(int id) =>
      (select(cards)..where((c) => c.id.equals(id))).getSingleOrNull();

  /// 下一张待复习卡片（带 note），按 state/due 优先级排序。
  ///
  /// Review（state 2）仍须 **已到期**（`due <= now`）。Learning / Relearning 允许
  /// `due` 在短时间窗内（未来 20 分钟内），以便同一会话内连续学完短间隔。
  Future<CardWithNote?> getNextDueWithNote({
    required int deckId,
    required int nowMillis,
  }) async {
    final learningDueCap = nowMillis + _learningDueHorizonMs;
    final rows = await customSelect(
      '''
      SELECT id FROM cards
      WHERE deck_id = ? AND (
        due <= ?
        OR (
          state IN (1, 3)
          AND due <= ?
        )
      )
      ORDER BY
        CASE state
          WHEN 0 THEN 0
          WHEN 1 THEN 1
          WHEN 3 THEN 2
          WHEN 2 THEN 3
          ELSE 9
        END,
        due ASC,
        id ASC
      LIMIT 1
      ''',
      variables: [
        Variable<int>(deckId),
        Variable<int>(nowMillis),
        Variable<int>(learningDueCap),
      ],
      readsFrom: {cards},
    ).get();

    if (rows.isEmpty) return null;

    final cardId = rows.first.read<int>('id');
    final card = await getById(cardId);
    if (card == null) return null;

    final note = await (select(notes)..where((n) => n.id.equals(card.noteId)))
        .getSingleOrNull();
    if (note == null) return null;

    return CardWithNote(card: card, note: note);
  }

  Future<bool> updateCard(int id, CardsCompanion entry) async {
    final affected =
        await (update(cards)..where((c) => c.id.equals(id))).write(entry);
    return affected > 0;
  }

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
