import 'package:drift/drift.dart';

class Reviews extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cardId => integer()();
  IntColumn get reviewedAt => integer()();
  IntColumn get rating => integer()();
  IntColumn get state => integer()();
  IntColumn get due => integer()();
  RealColumn get stability => real()();
  RealColumn get difficulty => real()();
  IntColumn get elapsedDays => integer()();
  IntColumn get lastElapsedDays => integer()();
  IntColumn get scheduledDays => integer()();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
}
