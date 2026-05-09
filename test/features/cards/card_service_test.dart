import 'dart:convert';

import 'package:anki_multi/core/database/database.dart';
import 'package:anki_multi/core/database/seed.dart';
import 'package:anki_multi/features/cards/application/card_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late CardService svc;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await seedDefaultNoteTypes(db);
    svc = CardService(db);
  });

  tearDown(() => db.close());

  test('createBasicCard 同时创建 note + card', () async {
    final cardId = await svc.createBasicCard(
      deckId: 1,
      front: '光速',
      back: '3e8 m/s',
    );
    final card = await db.cardsDao.getById(cardId);
    expect(card, isNotNull);

    final note = await db.notesDao.getById(card!.noteId);
    final fields = jsonDecode(note!.fields) as Map<String, dynamic>;
    expect(fields['正面'], '光速');
    expect(fields['反面'], '3e8 m/s');
  });

  test('updateBasicCard 改 note 内容', () async {
    final cardId = await svc.createBasicCard(
      deckId: 1,
      front: 'A',
      back: 'B',
    );
    final card = await db.cardsDao.getById(cardId);

    await svc.updateBasicCard(
      noteId: card!.noteId,
      front: 'A2',
      back: 'B2',
    );

    final note = await db.notesDao.getById(card.noteId);
    expect(note!.fields, contains('A2'));
  });

  test('deleteCard 同时删 note', () async {
    final cardId = await svc.createBasicCard(
      deckId: 1,
      front: 'A',
      back: 'B',
    );
    final card = await db.cardsDao.getById(cardId);

    await svc.deleteCard(cardId: cardId, noteId: card!.noteId);

    expect(await db.cardsDao.getById(cardId), isNull);
    expect(await db.notesDao.getById(card.noteId), isNull);
  });
}
