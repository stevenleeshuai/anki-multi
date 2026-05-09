import 'package:drift/drift.dart';

class Media extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get filename => text().unique()();
  TextColumn get originalName => text()();
  IntColumn get size => integer()();
  TextColumn get mimeType => text()();
  IntColumn get createdAt => integer()();
}
