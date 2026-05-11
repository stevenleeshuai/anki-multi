import 'package:anki_multi/core/database/database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('insertReview 写入一行', () async {
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

    await db.reviewsDao.insertReview(
      ReviewsCompanion.insert(
        cardId: cardId,
        reviewedAt: now,
        rating: 3,
        state: 2,
        due: now + 86400000,
        stability: 1.5,
        difficulty: 5.0,
        elapsedDays: 0,
        lastElapsedDays: 0,
        scheduledDays: 1,
      ),
    );

    final rows = await db.select(db.reviews).get();
    expect(rows, hasLength(1));
    expect(rows.single.cardId, cardId);
    expect(rows.single.rating, 3);
  });
}
