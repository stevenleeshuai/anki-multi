import 'package:anki_multi/core/database/daos/decks_dao.dart';
import 'package:anki_multi/core/database/database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DecksDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.decksDao;
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertDeck(String name) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return dao.insertDeck(
      DecksCompanion.insert(name: name, createdAt: now, updatedAt: now),
    );
  }

  test('insert + getById', () async {
    final id = await insertDeck('A');
    final fetched = await dao.getById(id);
    expect(fetched?.name, 'A');
  });

  test('updateDeck', () async {
    final id = await insertDeck('A');
    final ok = await dao.updateDeck(id, DecksCompanion(name: const Value('B')));
    expect(ok, isTrue);
    final fetched = await dao.getById(id);
    expect(fetched?.name, 'B');
  });

  test('deleteDeck', () async {
    final id = await insertDeck('A');
    final removed = await dao.deleteDeck(id);
    expect(removed, 1);
    final fetched = await dao.getById(id);
    expect(fetched, isNull);
  });

  test('watchAllWithCount 包含没卡片的牌组（count=0）', () async {
    await insertDeck('Empty');
    final list = await dao.watchAllWithCount().first;
    expect(list, hasLength(1));
    expect(list.first.cardCount, 0);
  });

  test('watchAllWithCount 正确统计每组卡片数', () async {
    final emptyId = await insertDeck('Empty');
    final fullId = await insertDeck('Full');
    final now = DateTime.now().millisecondsSinceEpoch;

    final noteId = await db.notesDao.insertNote(
      NotesCompanion.insert(
        noteTypeId: 1,
        fields: '{"正面":"q","反面":"a"}',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await db.cardsDao.insertCard(
      CardsCompanion.insert(
        noteId: noteId,
        deckId: fullId,
        due: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.cardsDao.insertCard(
      CardsCompanion.insert(
        noteId: noteId,
        deckId: fullId,
        due: now,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final list = await dao.watchAllWithCount().first;
    final byId = {for (final e in list) e.deck.id: e.cardCount};
    expect(byId[emptyId], 0);
    expect(byId[fullId], 2);
  });

  test('watchById re-emits when row updates', () async {
    final id = await insertDeck('A');

    final expectation = expectLater(
      dao.watchById(id),
      emitsInOrder([
        isA<Deck>().having((d) => d.name, 'name', 'A'),
        isA<Deck>().having((d) => d.name, 'name', 'B'),
      ]),
    );

    // 触发更新；emitsInOrder 已经订阅，能收到第二个值。
    await Future<void>.delayed(Duration.zero);
    await dao.updateDeck(id, DecksCompanion(name: const Value('B')));

    await expectation;
  });
}
