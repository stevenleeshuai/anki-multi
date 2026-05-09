// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'decks_dao.dart';

// ignore_for_file: type=lint
mixin _$DecksDaoMixin on DatabaseAccessor<AppDatabase> {
  $DecksTable get decks => attachedDatabase.decks;
  $CardsTable get cards => attachedDatabase.cards;
  DecksDaoManager get managers => DecksDaoManager(this);
}

class DecksDaoManager {
  final _$DecksDaoMixin _db;
  DecksDaoManager(this._db);
  $$DecksTableTableManager get decks =>
      $$DecksTableTableManager(_db.attachedDatabase, _db.decks);
  $$CardsTableTableManager get cards =>
      $$CardsTableTableManager(_db.attachedDatabase, _db.cards);
}
