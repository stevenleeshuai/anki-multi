// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reviews_dao.dart';

// ignore_for_file: type=lint
mixin _$ReviewsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ReviewsTable get reviews => attachedDatabase.reviews;
  ReviewsDaoManager get managers => ReviewsDaoManager(this);
}

class ReviewsDaoManager {
  final _$ReviewsDaoMixin _db;
  ReviewsDaoManager(this._db);
  $$ReviewsTableTableManager get reviews =>
      $$ReviewsTableTableManager(_db.attachedDatabase, _db.reviews);
}
