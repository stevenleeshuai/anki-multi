import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/decks_dao.dart';
import 'daos/note_types_dao.dart';
import 'tables/cards_table.dart';
import 'tables/decks_table.dart';
import 'tables/media_table.dart';
import 'tables/note_types_table.dart';
import 'tables/notes_table.dart';
import 'tables/reviews_table.dart';
import 'tables/settings_table.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Decks,
    NoteTypes,
    Notes,
    Cards,
    Reviews,
    Media,
    Settings,
  ],
  daos: [
    NoteTypesDao,
    DecksDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'anki_multi.sqlite'));
    return NativeDatabase(file);
  });
}
