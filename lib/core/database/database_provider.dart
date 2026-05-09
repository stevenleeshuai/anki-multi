import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';
import 'seed.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  unawaited(seedDefaultNoteTypes(db));
  return db;
});
