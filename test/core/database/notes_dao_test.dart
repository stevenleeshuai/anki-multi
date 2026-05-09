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

  test('insert + getById + update + delete', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = await db.notesDao.insertNote(
      NotesCompanion.insert(
        noteTypeId: 1,
        fields: '{"正面":"Q","反面":"A"}',
        createdAt: now,
        updatedAt: now,
      ),
    );

    var fetched = await db.notesDao.getById(id);
    expect(fetched?.fields, contains('Q'));

    await db.notesDao.updateNote(
      id,
      NotesCompanion(fields: const Value('{"正面":"Q2","反面":"A2"}')),
    );
    fetched = await db.notesDao.getById(id);
    expect(fetched?.fields, contains('Q2'));

    final removed = await db.notesDao.deleteNote(id);
    expect(removed, 1);
  });
}
