import 'dart:math' as math;

import 'package:anki_multi/core/database/database.dart';
import 'package:anki_multi/features/review/application/review_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

void main() {
  test('rateCard 更新 card 并插入 review', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final scheduler = fsrs.Scheduler.customRandom(
      math.Random(0),
      enableFuzzing: false,
    );
    final service = ReviewService(db, scheduler);

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
            fields: '{"正面":"q","反面":"a"}',
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

    await service.rateCard(
      deckId: 1,
      cardId: cardId,
      rating: fsrs.Rating.good,
    );

    final updated = await db.cardsDao.getById(cardId);
    expect(updated, isNotNull);
    expect(updated!.state, isNot(0));

    final logs = await db.select(db.reviews).get();
    expect(logs, hasLength(1));
    expect(logs.single.cardId, cardId);
  });

  test('Again 后 Learning 短间隔内仍能继续复习同一张', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final scheduler = fsrs.Scheduler.customRandom(
      math.Random(0),
      enableFuzzing: false,
    );
    final service = ReviewService(db, scheduler);

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
            fields: '{"正面":"q","反面":"a"}',
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

    await service.rateCard(
      deckId: 1,
      cardId: cardId,
      rating: fsrs.Rating.again,
    );

    final next = await service.peekNextDue(1);
    expect(next, isNotNull);
    expect(next!.card.id, cardId);
  });

  test('peekNextDue 按顺序返回两张卡里应先复习的一张', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final service = ReviewService(
      db,
      fsrs.Scheduler.customRandom(math.Random(0), enableFuzzing: false),
    );

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

    Future<int> insertCard({
      required int noteId,
      required int due,
      required int state,
    }) {
      return db.into(db.cards).insert(
            CardsCompanion.insert(
              noteId: noteId,
              deckId: 1,
              due: due,
              createdAt: now,
              updatedAt: now,
              state: Value(state),
            ),
          );
    }

    final n1 = await db.into(db.notes).insert(
          NotesCompanion.insert(
            noteTypeId: noteTypeId,
            fields: '{}',
            createdAt: now,
            updatedAt: now,
          ),
        );
    final n2 = await db.into(db.notes).insert(
          NotesCompanion.insert(
            noteTypeId: noteTypeId,
            fields: '{}',
            createdAt: now,
            updatedAt: now,
          ),
        );

    await insertCard(noteId: n1, due: now, state: 2);
    await insertCard(noteId: n2, due: now - 1, state: 0);

    final next = await service.peekNextDue(1);
    expect(next, isNotNull);
    expect(next!.card.state, 0);
    expect(next.card.noteId, n2);
  });
}
