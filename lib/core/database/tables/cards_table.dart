import 'package:drift/drift.dart';

class Cards extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get noteId => integer()();
  IntColumn get deckId => integer()();
  IntColumn get templateIdx => integer().withDefault(const Constant(0))();

  IntColumn get due => integer()();
  RealColumn get stability => real().withDefault(const Constant(0))();
  RealColumn get difficulty => real().withDefault(const Constant(0))();
  IntColumn get elapsedDays => integer().withDefault(const Constant(0))();
  IntColumn get scheduledDays => integer().withDefault(const Constant(0))();
  IntColumn get reps => integer().withDefault(const Constant(0))();
  IntColumn get lapses => integer().withDefault(const Constant(0))();
  IntColumn get state => integer().withDefault(const Constant(0))();
  IntColumn get lastReview => integer().nullable()();

  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}
