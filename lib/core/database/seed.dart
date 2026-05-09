import 'database.dart';

const _basicTemplate =
    '[{"name":"正→反","qfmt":"{{正面}}","afmt":"{{正面}}<hr>{{反面}}"}]';
const _basicFields = '["正面","反面"]';

const _clozeTemplate =
    '[{"name":"Cloze","qfmt":"{{cloze:内容}}","afmt":"{{cloze:内容}}"}]';
const _clozeFields = '["内容"]';

Future<void> seedDefaultNoteTypes(AppDatabase db) async {
  final dao = db.noteTypesDao;
  final count = await dao.count();
  if (count > 0) {
    return;
  }

  final now = DateTime.now().millisecondsSinceEpoch;
  await dao.insertNoteType(
    NoteTypesCompanion.insert(
      name: 'Basic',
      fields: _basicFields,
      templates: _basicTemplate,
      createdAt: now,
      updatedAt: now,
    ),
  );
  await dao.insertNoteType(
    NoteTypesCompanion.insert(
      name: 'Cloze',
      fields: _clozeFields,
      templates: _clozeTemplate,
      createdAt: now,
      updatedAt: now,
    ),
  );
}
