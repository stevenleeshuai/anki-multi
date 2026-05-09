import 'package:anki_multi/core/database/database.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('能创建并查询 Deck', () async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final id = await db.into(db.decks).insert(
          DecksCompanion.insert(
            name: '默认牌组',
            createdAt: now,
            updatedAt: now,
          ),
        );

    final fetched =
        await (db.select(db.decks)..where((d) => d.id.equals(id))).getSingle();

    expect(fetched.name, '默认牌组');
    expect(fetched.parentId, isNull);
  });

  test('七张表都能 insert 一条数据不报错', () async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.into(db.decks).insert(
          DecksCompanion.insert(name: 'D', createdAt: now, updatedAt: now),
        );

    final noteTypeId = await db.into(db.noteTypes).insert(
          NoteTypesCompanion.insert(
            name: 'Basic',
            fields: '["正面","反面"]',
            templates: '[]',
            createdAt: now,
            updatedAt: now,
          ),
        );

    final noteId = await db.into(db.notes).insert(
          NotesCompanion.insert(
            noteTypeId: noteTypeId,
            fields: '{}',
            createdAt: now,
            updatedAt: now,
          ),
        );

    final cardId = await db.into(db.cards).insert(
          CardsCompanion.insert(
            noteId: noteId,
            deckId: 1,
            due: now,
            createdAt: now,
            updatedAt: now,
          ),
        );

    await db.into(db.reviews).insert(
          ReviewsCompanion.insert(
            cardId: cardId,
            reviewedAt: now,
            rating: 3,
            state: 0,
            due: now,
            stability: 1.0,
            difficulty: 5.0,
            elapsedDays: 0,
            lastElapsedDays: 0,
            scheduledDays: 1,
          ),
        );

    await db.into(db.media).insert(
          MediaCompanion.insert(
            filename: 'a.png',
            originalName: 'a.png',
            size: 100,
            mimeType: 'image/png',
            createdAt: now,
          ),
        );

    await db.into(db.settings).insert(
          SettingsCompanion.insert(key: 'theme', value: 'dark'),
        );

    expect(true, true);
  });
}
