import 'package:anki_multi/core/database/database.dart';
import 'package:anki_multi/core/database/seed.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('seedDefaultNoteTypes 在空库时插入 Basic 和 Cloze', () async {
    await seedDefaultNoteTypes(db);

    final all = await db.noteTypesDao.getAll();
    expect(all, hasLength(2));
    expect(all.map((t) => t.name).toSet(), {'Basic', 'Cloze'});
  });

  test('seedDefaultNoteTypes 重复调用不会插入重复', () async {
    await seedDefaultNoteTypes(db);
    await seedDefaultNoteTypes(db);

    final all = await db.noteTypesDao.getAll();
    expect(all, hasLength(2));
  });

  test('getByName 能查到 Basic', () async {
    await seedDefaultNoteTypes(db);

    final basic = await db.noteTypesDao.getByName('Basic');
    expect(basic, isNotNull);
    expect(basic!.fields, contains('正面'));
  });
}
