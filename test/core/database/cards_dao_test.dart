import 'package:anki_multi/core/database/database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<int> seedNote() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.notesDao.insertNote(
      NotesCompanion.insert(
        noteTypeId: 1,
        fields: '{"正面":"q","反面":"a"}',
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  test('insert card 并按 deck 监听', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final noteId = await seedNote();

    await db.cardsDao.insertCard(
      CardsCompanion.insert(
        noteId: noteId,
        deckId: 7,
        due: now,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final list = await db.cardsDao.watchByDeck(7).first;
    expect(list, hasLength(1));
    expect(list.first.note.fields, contains('q'));
  });

  test('deleteCardsByNote 一次删掉同 note 所有卡', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final noteId = await seedNote();
    await db.cardsDao.insertCard(
      CardsCompanion.insert(
        noteId: noteId,
        deckId: 1,
        due: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.cardsDao.insertCard(
      CardsCompanion.insert(
        noteId: noteId,
        deckId: 1,
        due: now,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final removed = await db.cardsDao.deleteCardsByNote(noteId);
    expect(removed, 2);
  });

  test('Learning 阶段 due 在未来几分钟内仍能取出（Again 后会话不空）', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final noteId = await seedNote();
    final dueSoon = now + 60000;

    await db.cardsDao.insertCard(
      CardsCompanion.insert(
        noteId: noteId,
        deckId: 9,
        due: dueSoon,
        createdAt: now,
        updatedAt: now,
        state: const Value(1),
      ),
    );

    final next = await db.cardsDao.getNextDueWithNote(
      deckId: 9,
      nowMillis: now,
    );
    expect(next, isNotNull);
    expect(next!.card.state, 1);
  });
}
