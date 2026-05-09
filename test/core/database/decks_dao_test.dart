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
}
