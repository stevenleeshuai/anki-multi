import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/note_types_table.dart';

part 'note_types_dao.g.dart';

@DriftAccessor(tables: [NoteTypes])
class NoteTypesDao extends DatabaseAccessor<AppDatabase>
    with _$NoteTypesDaoMixin {
  NoteTypesDao(super.db);

  Future<List<NoteType>> getAll() => select(noteTypes).get();

  Future<NoteType?> getByName(String name) =>
      (select(noteTypes)..where((t) => t.name.equals(name))).getSingleOrNull();

  Future<int> insertNoteType(NoteTypesCompanion entry) =>
      into(noteTypes).insert(entry);

  Future<int> count() async {
    final query = selectOnly(noteTypes)..addColumns([noteTypes.id.count()]);
    final row = await query.getSingle();
    return row.read(noteTypes.id.count()) ?? 0;
  }
}
