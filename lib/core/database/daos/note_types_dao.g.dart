// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_types_dao.dart';

// ignore_for_file: type=lint
mixin _$NoteTypesDaoMixin on DatabaseAccessor<AppDatabase> {
  $NoteTypesTable get noteTypes => attachedDatabase.noteTypes;
  NoteTypesDaoManager get managers => NoteTypesDaoManager(this);
}

class NoteTypesDaoManager {
  final _$NoteTypesDaoMixin _db;
  NoteTypesDaoManager(this._db);
  $$NoteTypesTableTableManager get noteTypes =>
      $$NoteTypesTableTableManager(_db.attachedDatabase, _db.noteTypes);
}
