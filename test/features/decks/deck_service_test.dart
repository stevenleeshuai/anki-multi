import 'package:anki_multi/core/database/database.dart';
import 'package:anki_multi/features/decks/application/deck_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DeckService svc;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    svc = DeckService(db);
  });

  tearDown(() => db.close());

  test('create 后能 watch 到', () async {
    final id = await svc.create('My Deck');
    final list = await db.decksDao.watchAllWithCount().first;
    expect(list, hasLength(1));
    expect(list.first.deck.id, id);
    expect(list.first.deck.name, 'My Deck');
    expect(list.first.cardCount, 0);
  });

  test('rename 起作用', () async {
    final id = await svc.create('A');
    await svc.rename(id, 'B');
    final fetched = await db.decksDao.getById(id);
    expect(fetched?.name, 'B');
  });

  test('delete 起作用', () async {
    final id = await svc.create('A');
    await svc.delete(id);
    final fetched = await db.decksDao.getById(id);
    expect(fetched, isNull);
  });
}
