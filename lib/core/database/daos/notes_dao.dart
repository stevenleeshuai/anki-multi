import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/notes_table.dart';

part 'notes_dao.g.dart';

@DriftAccessor(tables: [Notes])
class NotesDao extends DatabaseAccessor<AppDatabase> with _$NotesDaoMixin {
  NotesDao(super.db);

  Future<int> insertNote(NotesCompanion entry) => into(notes).insert(entry);

  Future<Note?> getById(int id) =>
      (select(notes)..where((n) => n.id.equals(id))).getSingleOrNull();

  Future<bool> updateNote(int id, NotesCompanion entry) async {
    final affected = await (update(notes)..where((n) => n.id.equals(id)))
        .write(entry);
    return affected > 0;
  }

  Future<int> deleteNote(int id) =>
      (delete(notes)..where((n) => n.id.equals(id))).go();
}
