# M2 — 牌组与卡片 CRUD Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让用户能在 app 内创建/管理牌组、创建/管理 Basic 类型卡片（正面/反面文本），是 M3 接入 FSRS 复习的前置条件。M2 完成时，用户应能手动添加几十张卡片到 app 中。

**Architecture:** drift DAO 层做 CRUD；Riverpod Service 层提供响应式 stream + mutation；feature-based UI（DeckListPage、DeckEditPage、DeckDetailPage、CardEditPage）；首次启动时 seed 默认 NoteTypes（Basic + Cloze）。所有数据流响应式（Stream + StreamProvider），数据库写入后 UI 自动更新。

**Tech Stack:** drift DAO (`@DriftAccessor`), flutter_riverpod (StreamProvider, StateNotifier 或 AsyncNotifier), go_router 多路由, Material 3 form 组件。

**预计时长：** ~12 小时（Week 3-4，每周 5-6 小时）

**对应 spec：** `docs/superpowers/specs/2026-05-09-anki_multi-design.md`

---

## File Structure 概览

| 文件 | 作用 |
|---|---|
| `lib/core/database/daos/note_types_dao.dart` | NoteTypes 表 CRUD |
| `lib/core/database/daos/decks_dao.dart` | Decks 表 CRUD + 卡片数 join |
| `lib/core/database/daos/notes_dao.dart` | Notes 表 CRUD |
| `lib/core/database/daos/cards_dao.dart` | Cards 表 CRUD + 跨表查询 |
| `lib/core/database/seed.dart` | 首次启动 seed 默认 NoteTypes |
| `lib/core/database/database.dart` | @DriftDatabase 加 daos: [...] |
| `lib/core/database/database_provider.dart` | provider 创建后异步 seed |
| `lib/features/decks/domain/deck_with_count.dart` | Deck + cardCount 聚合 |
| `lib/features/cards/domain/card_with_content.dart` | Card + Note + NoteType 聚合 |
| `lib/features/decks/application/deck_service.dart` | Decks 的 Riverpod providers |
| `lib/features/cards/application/card_service.dart` | Cards 的 Riverpod providers |
| `lib/core/routing/app_router.dart` | 加 5 条路由 |
| `lib/features/decks/presentation/pages/deck_list_page.dart` | 替代旧 HomePage |
| `lib/features/decks/presentation/pages/deck_edit_page.dart` | 创建/编辑牌组 |
| `lib/features/decks/presentation/pages/deck_detail_page.dart` | 牌组详情 + 卡片列表 |
| `lib/features/cards/presentation/pages/card_edit_page.dart` | 创建/编辑卡片 |
| `test/core/database/note_types_dao_test.dart` | |
| `test/core/database/decks_dao_test.dart` | |
| `test/core/database/notes_dao_test.dart` | |
| `test/core/database/cards_dao_test.dart` | |
| `test/features/decks/deck_service_test.dart` | |
| `test/features/cards/card_service_test.dart` | |

---

## Task 1: NoteTypesDao + Seed 默认类型

**目的：** 让数据库首次启动时自动注入 Basic 和 Cloze 两种 NoteType。这两种类型未来 v0.1 都要支持，提前 seed 进去。

**Files:**
- Create: `lib/core/database/daos/note_types_dao.dart`
- Create: `lib/core/database/seed.dart`
- Modify: `lib/core/database/database.dart` (加 daos:)
- Create: `test/core/database/note_types_dao_test.dart`

- [ ] **Step 1: 写 NoteTypesDao**

`lib/core/database/daos/note_types_dao.dart`：

```dart
import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/note_types_table.dart';

part 'note_types_dao.g.dart';

@DriftAccessor(tables: [NoteTypes])
class NoteTypesDao extends DatabaseAccessor<AppDatabase>
    with _$NoteTypesDaoMixin {
  NoteTypesDao(super.db);

  Future<List<NoteType>> getAll() => select(noteTypes).get();

  Future<NoteType?> getByName(String name) =>
      (select(noteTypes)..where((t) => t.name.equals(name))).getSingleOrNull();

  Future<int> insertNoteType(NoteTypesCompanion entry) =>
      into(noteTypes).insert(entry);

  Future<int> count() async {
    final query = selectOnly(noteTypes)..addColumns([noteTypes.id.count()]);
    final row = await query.getSingle();
    return row.read(noteTypes.id.count()) ?? 0;
  }
}
```

- [ ] **Step 2: 在 database.dart 注册 DAO**

`lib/core/database/database.dart`，修改 `@DriftDatabase` 注解：

```dart
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
  ],
)
```

并在文件顶部加 import：

```dart
import 'daos/note_types_dao.dart';
```

- [ ] **Step 3: 写 seed.dart**

`lib/core/database/seed.dart`：

```dart
import 'package:drift/drift.dart';

import 'database.dart';

const _basicTemplate =
    '[{"name":"正→反","qfmt":"{{正面}}","afmt":"{{正面}}<hr>{{反面}}"}]';
const _basicFields = '["正面","反面"]';

const _clozeTemplate = '[{"name":"Cloze","qfmt":"{{cloze:内容}}","afmt":"{{cloze:内容}}"}]';
const _clozeFields = '["内容"]';

Future<void> seedDefaultNoteTypes(AppDatabase db) async {
  final dao = db.noteTypesDao;
  final count = await dao.count();
  if (count > 0) {
    return; // 已经 seed 过
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
```

- [ ] **Step 4: 跑 build_runner 重新生成代码**

```bash
dart run build_runner build
```

预期：生成 `note_types_dao.g.dart` + 更新 `database.g.dart`。

- [ ] **Step 5: 写 NoteTypesDao 测试**

`test/core/database/note_types_dao_test.dart`：

```dart
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
```

- [ ] **Step 6: 跑测试**

```bash
flutter test test/core/database/note_types_dao_test.dart
```

预期：3 tests passed。

- [ ] **Step 7: Commit**

---

## Task 2: 让 databaseProvider 自动 seed

**目的：** App 启动时就自动 seed，不需要 UI 触发。

**Files:**
- Modify: `lib/core/database/database_provider.dart`

- [ ] **Step 1: 改 provider**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';
import 'seed.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  // 异步 seed，不阻塞 provider 创建。如果有页面需要等 seed 完成，
  // 后续可以引入 FutureProvider 包装。但 v0.1 没场景需要。
  unawaited(seedDefaultNoteTypes(db));
  return db;
});
```

注意 `unawaited` 来自 `dart:async`，需要 import：

```dart
import 'dart:async';
```

- [ ] **Step 2: 验证 analyze 与 test**

```bash
flutter analyze && flutter test
```

预期：0 issues, all tests pass。

- [ ] **Step 3: Commit**

---

## Task 3: DecksDao + 测试

**Files:**
- Create: `lib/core/database/daos/decks_dao.dart`
- Modify: `lib/core/database/database.dart`
- Create: `test/core/database/decks_dao_test.dart`

- [ ] **Step 1: 写 DecksDao**

`lib/core/database/daos/decks_dao.dart`：

```dart
import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/cards_table.dart';
import '../tables/decks_table.dart';

part 'decks_dao.g.dart';

class DeckWithCount {
  const DeckWithCount({required this.deck, required this.cardCount});

  final Deck deck;
  final int cardCount;
}

@DriftAccessor(tables: [Decks, Cards])
class DecksDao extends DatabaseAccessor<AppDatabase> with _$DecksDaoMixin {
  DecksDao(super.db);

  Stream<List<Deck>> watchAll() => select(decks).watch();

  Future<Deck?> getById(int id) =>
      (select(decks)..where((d) => d.id.equals(id))).getSingleOrNull();

  Future<int> insertDeck(DecksCompanion entry) => into(decks).insert(entry);

  Future<bool> updateDeck(int id, DecksCompanion entry) async {
    final affected = await (update(decks)..where((d) => d.id.equals(id)))
        .write(entry);
    return affected > 0;
  }

  Future<int> deleteDeck(int id) =>
      (delete(decks)..where((d) => d.id.equals(id))).go();

  /// 牌组 + 该组中卡片数。用 left join 让没有卡片的牌组也返回 0。
  Stream<List<DeckWithCount>> watchAllWithCount() {
    final groupedQuery = customSelect(
      'SELECT d.*, COUNT(c.id) AS card_count '
      'FROM decks d '
      'LEFT JOIN cards c ON c.deck_id = d.id '
      'GROUP BY d.id '
      'ORDER BY d.created_at DESC',
      readsFrom: {decks, cards},
    );

    return groupedQuery.watch().map((rows) {
      return rows.map((row) {
        return DeckWithCount(
          deck: Deck(
            id: row.read<int>('id'),
            name: row.read<String>('name'),
            parentId: row.readNullable<int>('parent_id'),
            createdAt: row.read<int>('created_at'),
            updatedAt: row.read<int>('updated_at'),
          ),
          cardCount: row.read<int>('card_count'),
        );
      }).toList();
    });
  }
}
```

- [ ] **Step 2: 在 database.dart 注册 DAO**

修改 `@DriftDatabase` 注解的 `daos:`：

```dart
daos: [
  NoteTypesDao,
  DecksDao,
],
```

并加 import：

```dart
import 'daos/decks_dao.dart';
```

- [ ] **Step 3: 跑 build_runner**

```bash
dart run build_runner build
```

- [ ] **Step 4: 写测试**

`test/core/database/decks_dao_test.dart`：

```dart
import 'package:anki_multi/core/database/database.dart';
import 'package:anki_multi/core/database/daos/decks_dao.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DecksDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.decksDao;
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertDeck(String name) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return dao.insertDeck(
      DecksCompanion.insert(name: name, createdAt: now, updatedAt: now),
    );
  }

  test('insert + getById', () async {
    final id = await insertDeck('A');
    final fetched = await dao.getById(id);
    expect(fetched?.name, 'A');
  });

  test('updateDeck', () async {
    final id = await insertDeck('A');
    final ok = await dao.updateDeck(id, DecksCompanion(name: const Value('B')));
    expect(ok, isTrue);
    final fetched = await dao.getById(id);
    expect(fetched?.name, 'B');
  });

  test('deleteDeck', () async {
    final id = await insertDeck('A');
    final removed = await dao.deleteDeck(id);
    expect(removed, 1);
    final fetched = await dao.getById(id);
    expect(fetched, isNull);
  });

  test('watchAllWithCount 包含没卡片的牌组（count=0）', () async {
    await insertDeck('Empty');
    final list = await dao.watchAllWithCount().first;
    expect(list, hasLength(1));
    expect(list.first.cardCount, 0);
  });
}
```

- [ ] **Step 5: 跑测试**

```bash
flutter test test/core/database/decks_dao_test.dart
```

预期：4 tests passed。

- [ ] **Step 6: Commit**

---

## Task 4: NotesDao + CardsDao + 测试

两个 DAO 一起做，因为 Card 总是隶属于 Note。

**Files:**
- Create: `lib/core/database/daos/notes_dao.dart`
- Create: `lib/core/database/daos/cards_dao.dart`
- Modify: `lib/core/database/database.dart`
- Create: `test/core/database/notes_dao_test.dart`
- Create: `test/core/database/cards_dao_test.dart`

- [ ] **Step 1: NotesDao**

`lib/core/database/daos/notes_dao.dart`：

```dart
import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/notes_table.dart';

part 'notes_dao.g.dart';

@DriftAccessor(tables: [Notes])
class NotesDao extends DatabaseAccessor<AppDatabase> with _$NotesDaoMixin {
  NotesDao(super.db);

  Future<int> insertNote(NotesCompanion entry) => into(notes).insert(entry);

  Future<Note?> getById(int id) =>
      (select(notes)..where((n) => n.id.equals(id))).getSingleOrNull();

  Future<bool> updateNote(int id, NotesCompanion entry) async {
    final affected = await (update(notes)..where((n) => n.id.equals(id)))
        .write(entry);
    return affected > 0;
  }

  Future<int> deleteNote(int id) =>
      (delete(notes)..where((n) => n.id.equals(id))).go();
}
```

- [ ] **Step 2: CardsDao**

`lib/core/database/daos/cards_dao.dart`：

```dart
import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/cards_table.dart';
import '../tables/notes_table.dart';

part 'cards_dao.g.dart';

class CardWithNote {
  const CardWithNote({required this.card, required this.note});
  final Card card;
  final Note note;
}

@DriftAccessor(tables: [Cards, Notes])
class CardsDao extends DatabaseAccessor<AppDatabase> with _$CardsDaoMixin {
  CardsDao(super.db);

  Future<int> insertCard(CardsCompanion entry) => into(cards).insert(entry);

  Future<Card?> getById(int id) =>
      (select(cards)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<int> deleteCard(int id) =>
      (delete(cards)..where((c) => c.id.equals(id))).go();

  Future<int> deleteCardsByNote(int noteId) =>
      (delete(cards)..where((c) => c.noteId.equals(noteId))).go();

  /// 监听某牌组下所有卡片（带 note 联表，用于显示正面/反面）。
  Stream<List<CardWithNote>> watchByDeck(int deckId) {
    final query = select(cards).join([
      innerJoin(notes, notes.id.equalsExp(cards.noteId)),
    ])
      ..where(cards.deckId.equals(deckId))
      ..orderBy([OrderingTerm.desc(cards.createdAt)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return CardWithNote(
          card: row.readTable(cards),
          note: row.readTable(notes),
        );
      }).toList();
    });
  }
}
```

- [ ] **Step 3: 注册到 database.dart**

```dart
daos: [
  NoteTypesDao,
  DecksDao,
  NotesDao,
  CardsDao,
],
```

加 imports：

```dart
import 'daos/notes_dao.dart';
import 'daos/cards_dao.dart';
```

- [ ] **Step 4: build_runner**

```bash
dart run build_runner build
```

- [ ] **Step 5: NotesDao 测试**

`test/core/database/notes_dao_test.dart`：

```dart
import 'package:anki_multi/core/database/database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('insert + getById + update + delete', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = await db.notesDao.insertNote(
      NotesCompanion.insert(
        noteTypeId: 1,
        fields: '{"正面":"Q","反面":"A"}',
        createdAt: now,
        updatedAt: now,
      ),
    );

    var fetched = await db.notesDao.getById(id);
    expect(fetched?.fields, contains('Q'));

    await db.notesDao.updateNote(
      id,
      NotesCompanion(fields: const Value('{"正面":"Q2","反面":"A2"}')),
    );
    fetched = await db.notesDao.getById(id);
    expect(fetched?.fields, contains('Q2'));

    final removed = await db.notesDao.deleteNote(id);
    expect(removed, 1);
  });
}
```

- [ ] **Step 6: CardsDao 测试**

`test/core/database/cards_dao_test.dart`：

```dart
import 'package:anki_multi/core/database/database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<int> seedNote() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.notesDao.insertNote(
      NotesCompanion.insert(
        noteTypeId: 1,
        fields: '{"正面":"q","反面":"a"}',
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  test('insert card 并按 deck 监听', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final noteId = await seedNote();

    await db.cardsDao.insertCard(
      CardsCompanion.insert(
        noteId: noteId,
        deckId: 7,
        due: now,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final list = await db.cardsDao.watchByDeck(7).first;
    expect(list, hasLength(1));
    expect(list.first.note.fields, contains('q'));
  });

  test('deleteCardsByNote 一次删掉同 note 所有卡', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final noteId = await seedNote();
    await db.cardsDao.insertCard(CardsCompanion.insert(
        noteId: noteId, deckId: 1, due: now, createdAt: now, updatedAt: now));
    await db.cardsDao.insertCard(CardsCompanion.insert(
        noteId: noteId, deckId: 1, due: now, createdAt: now, updatedAt: now));

    final removed = await db.cardsDao.deleteCardsByNote(noteId);
    expect(removed, 2);
  });
}
```

- [ ] **Step 7: 跑测试**

```bash
flutter test test/core/database/notes_dao_test.dart test/core/database/cards_dao_test.dart
```

预期：3 tests passed。

- [ ] **Step 8: Commit**

---

## Task 5: Domain 聚合：DeckWithCount, CardWithContent

**目的：** UI 经常需要"卡片 + 它的 Note 内容"组合显示，定义 domain 类型让 UI 简洁。

**Files:**
- Note: `DeckWithCount` 已在 `decks_dao.dart` 中定义，**不**重复创建。
- Note: `CardWithNote` 也已在 `cards_dao.dart` 中定义。
- Create: `lib/features/cards/domain/card_with_content.dart` (Card + Note + NoteType 三层聚合)

> v0.1 我们其实只需要 `CardWithNote`（已在 dao 里），`CardWithContent` 是 M3 复习页才需要的（要从 NoteType 模板拼出"正面/反面"渲染）。M2 这一步可以**只定义骨架，留空 TODO**——错——按照 No Placeholders 规则，要么完成要么删除。这里**直接删除该任务**，到 M3 再创建。

**所以 Task 5 实际操作：**

- [ ] **Step 1: 跳过本任务**（domain 聚合都已在 dao 里，无需新文件）

> 注：保留这个 task 编号是为了让后续 task 编号与计划讨论一致；如果你愿意调整，把后面所有任务编号 -1 也行。

---

## Task 6: DeckService（Riverpod）

**Files:**
- Create: `lib/features/decks/application/deck_service.dart`
- Create: `test/features/decks/deck_service_test.dart`

- [ ] **Step 1: DeckService**

`lib/features/decks/application/deck_service.dart`：

```dart
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/daos/decks_dao.dart';
import '../../../core/database/database.dart';
import '../../../core/database/database_provider.dart';

/// 监听全部牌组（带卡片数）。
final allDecksWithCountProvider =
    StreamProvider.autoDispose<List<DeckWithCount>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.decksDao.watchAllWithCount();
});

/// 单个牌组。
final deckByIdProvider =
    FutureProvider.autoDispose.family<Deck?, int>((ref, id) {
  final db = ref.watch(databaseProvider);
  return db.decksDao.getById(id);
});

/// 操作类（mutation）：直接调用 DAO。
class DeckService {
  DeckService(this._db);

  final AppDatabase _db;

  Future<int> create(String name) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _db.decksDao.insertDeck(
      DecksCompanion.insert(name: name, createdAt: now, updatedAt: now),
    );
  }

  Future<bool> rename(int id, String name) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _db.decksDao.updateDeck(
      id,
      DecksCompanion(name: Value(name), updatedAt: Value(now)),
    );
  }

  Future<int> delete(int id) => _db.decksDao.deleteDeck(id);
}

final deckServiceProvider = Provider<DeckService>((ref) {
  return DeckService(ref.watch(databaseProvider));
});
```

- [ ] **Step 2: DeckService 测试**

`test/features/decks/deck_service_test.dart`：

```dart
import 'package:anki_multi/core/database/database.dart';
import 'package:anki_multi/features/decks/application/deck_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DeckService svc;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    svc = DeckService(db);
  });

  tearDown(() => db.close());

  test('create 后能 watch 到', () async {
    final id = await svc.create('My Deck');
    final list = await db.decksDao.watchAllWithCount().first;
    expect(list, hasLength(1));
    expect(list.first.deck.id, id);
    expect(list.first.deck.name, 'My Deck');
    expect(list.first.cardCount, 0);
  });

  test('rename 起作用', () async {
    final id = await svc.create('A');
    await svc.rename(id, 'B');
    final fetched = await db.decksDao.getById(id);
    expect(fetched?.name, 'B');
  });

  test('delete 起作用', () async {
    final id = await svc.create('A');
    await svc.delete(id);
    final fetched = await db.decksDao.getById(id);
    expect(fetched, isNull);
  });
}
```

- [ ] **Step 3: 跑测试**

```bash
flutter test test/features/decks/deck_service_test.dart
```

- [ ] **Step 4: Commit**

---

## Task 7: CardService（Riverpod）

**目的：** 创建/编辑/删除"Basic 卡片"的高层操作。Basic 卡片 = 一条 note + 一张 card。

**Files:**
- Create: `lib/features/cards/application/card_service.dart`
- Create: `test/features/cards/card_service_test.dart`

- [ ] **Step 1: CardService**

`lib/features/cards/application/card_service.dart`：

```dart
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/daos/cards_dao.dart';
import '../../../core/database/database.dart';
import '../../../core/database/database_provider.dart';

final cardsByDeckProvider =
    StreamProvider.autoDispose.family<List<CardWithNote>, int>((ref, deckId) {
  final db = ref.watch(databaseProvider);
  return db.cardsDao.watchByDeck(deckId);
});

class CardService {
  CardService(this._db);

  final AppDatabase _db;

  /// 在 [deckId] 下创建一张 Basic 卡片。返回 cardId。
  Future<int> createBasicCard({
    required int deckId,
    required String front,
    required String back,
  }) async {
    final basic = await _db.noteTypesDao.getByName('Basic');
    if (basic == null) {
      throw StateError('NoteType "Basic" 未 seed，无法创建 Basic 卡片');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final fieldsJson = jsonEncode({'正面': front, '反面': back});

    final noteId = await _db.notesDao.insertNote(
      NotesCompanion.insert(
        noteTypeId: basic.id,
        fields: fieldsJson,
        createdAt: now,
        updatedAt: now,
      ),
    );

    return _db.cardsDao.insertCard(
      CardsCompanion.insert(
        noteId: noteId,
        deckId: deckId,
        due: now, // new card, due immediately
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  /// 编辑 Basic 卡片：修改其 note 的 fields。
  Future<bool> updateBasicCard({
    required int noteId,
    required String front,
    required String back,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final fieldsJson = jsonEncode({'正面': front, '反面': back});
    return _db.notesDao.updateNote(
      noteId,
      NotesCompanion(
        fields: Value(fieldsJson),
        updatedAt: Value(now),
      ),
    );
  }

  /// 删除一张卡片（同时删除背后的 note，因为我们 v0.1 是 1 note → 1 card 模型）。
  Future<void> deleteCard({required int cardId, required int noteId}) async {
    await _db.cardsDao.deleteCard(cardId);
    await _db.notesDao.deleteNote(noteId);
  }
}

final cardServiceProvider = Provider<CardService>((ref) {
  return CardService(ref.watch(databaseProvider));
});
```

- [ ] **Step 2: 测试**

`test/features/cards/card_service_test.dart`：

```dart
import 'dart:convert';

import 'package:anki_multi/core/database/database.dart';
import 'package:anki_multi/core/database/seed.dart';
import 'package:anki_multi/features/cards/application/card_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late CardService svc;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await seedDefaultNoteTypes(db);
    svc = CardService(db);
  });

  tearDown(() => db.close());

  test('createBasicCard 同时创建 note + card', () async {
    final cardId = await svc.createBasicCard(
      deckId: 1,
      front: '光速',
      back: '3e8 m/s',
    );
    final card = await db.cardsDao.getById(cardId);
    expect(card, isNotNull);

    final note = await db.notesDao.getById(card!.noteId);
    final fields = jsonDecode(note!.fields) as Map<String, dynamic>;
    expect(fields['正面'], '光速');
    expect(fields['反面'], '3e8 m/s');
  });

  test('updateBasicCard 改 note 内容', () async {
    final cardId = await svc.createBasicCard(
        deckId: 1, front: 'A', back: 'B');
    final card = await db.cardsDao.getById(cardId);

    await svc.updateBasicCard(
      noteId: card!.noteId,
      front: 'A2',
      back: 'B2',
    );

    final note = await db.notesDao.getById(card.noteId);
    expect(note!.fields, contains('A2'));
  });

  test('deleteCard 同时删 note', () async {
    final cardId = await svc.createBasicCard(
        deckId: 1, front: 'A', back: 'B');
    final card = await db.cardsDao.getById(cardId);

    await svc.deleteCard(cardId: cardId, noteId: card!.noteId);

    expect(await db.cardsDao.getById(cardId), isNull);
    expect(await db.notesDao.getById(card.noteId), isNull);
  });
}
```

- [ ] **Step 3: 跑测试**

```bash
flutter test test/features/cards/card_service_test.dart
```

预期：3 tests passed。

- [ ] **Step 4: Commit**

---

## Task 8: 更新 routing

**Files:**
- Modify: `lib/core/routing/app_router.dart`

- [ ] **Step 1: 替换 router 为新路由**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/cards/presentation/pages/card_edit_page.dart';
import '../../features/decks/presentation/pages/deck_detail_page.dart';
import '../../features/decks/presentation/pages/deck_edit_page.dart';
import '../../features/decks/presentation/pages/deck_list_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DeckListPage(),
      ),
      GoRoute(
        path: '/decks/new',
        builder: (context, state) => const DeckEditPage(),
      ),
      GoRoute(
        path: '/decks/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return DeckDetailPage(deckId: id);
        },
      ),
      GoRoute(
        path: '/decks/:id/edit',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return DeckEditPage(deckId: id);
        },
      ),
      GoRoute(
        path: '/decks/:id/cards/new',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return CardEditPage(deckId: id);
        },
      ),
      GoRoute(
        path: '/cards/:id/edit',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return CardEditPage(editingCardId: id);
        },
      ),
    ],
  );
});
```

> 此时编译会失败，因为 4 个页面文件还没创建。这是预期的——后续任务依次创建。

- [ ] **Step 2: 暂不 commit**（等 Task 9-12 完成后一起提交，避免半路 build 不通过）

---

## Task 9: DeckListPage（首页）

**Files:**
- Create: `lib/features/decks/presentation/pages/deck_list_page.dart`
- Delete (optional): `lib/features/home/presentation/pages/home_page.dart` 已不再使用

- [ ] **Step 1: DeckListPage**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/deck_service.dart';

class DeckListPage extends ConsumerWidget {
  const DeckListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(allDecksWithCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('anki_multi'),
      ),
      body: decksAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text('还没有牌组，点 + 新建一个'),
            );
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final item = list[i];
              return ListTile(
                leading: const Icon(Icons.folder),
                title: Text(item.deck.name),
                subtitle: Text('${item.cardCount} 张卡片'),
                onTap: () => context.push('/decks/${item.deck.id}'),
                onLongPress: () => _showDeckMenu(context, ref, item.deck.id),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('加载失败: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/decks/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeckMenu(BuildContext context, WidgetRef ref, int deckId) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('编辑'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/decks/$deckId/edit');
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('删除', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirm = await _confirmDelete(context);
                  if (confirm == true) {
                    await ref.read(deckServiceProvider).delete(deckId);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除牌组？'),
        content: const Text('该牌组及其所有卡片会被永久删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
```

> ⚠️ 注意：删除牌组**目前不会**级联删除其下的卡片（外键无 ON DELETE CASCADE）。这是 v0.1 已知限制，M2 不修。下面 Risks 部分有记录。

- [ ] **Step 2: 暂不 commit**

---

## Task 10: DeckEditPage（创建/编辑牌组）

**Files:**
- Create: `lib/features/decks/presentation/pages/deck_edit_page.dart`

- [ ] **Step 1: DeckEditPage**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/deck_service.dart';

class DeckEditPage extends ConsumerStatefulWidget {
  const DeckEditPage({super.key, this.deckId});

  /// 为 null 时创建，否则编辑。
  final int? deckId;

  @override
  ConsumerState<DeckEditPage> createState() => _DeckEditPageState();
}

class _DeckEditPageState extends ConsumerState<DeckEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  bool _saving = false;
  bool _initialized = false;

  bool get _isEditing => widget.deckId != null;

  @override
  void dispose() {
    _nameCtl.dispose();
    super.dispose();
  }

  Future<void> _loadIfEditing() async {
    if (_initialized || !_isEditing) {
      _initialized = true;
      return;
    }
    final deck = await ref.read(deckByIdProvider(widget.deckId!).future);
    if (deck != null && mounted) {
      _nameCtl.text = deck.name;
    }
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadIfEditing(),
      builder: (context, snap) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_isEditing ? '编辑牌组' : '新建牌组'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameCtl,
                    decoration: const InputDecoration(
                      labelText: '牌组名称',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '请输入名称' : null,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving ? null : () => context.pop(),
                          child: const Text('取消'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          onPressed: _saving ? null : _onSave,
                          child: Text(_saving ? '保存中…' : '保存'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final svc = ref.read(deckServiceProvider);
    final name = _nameCtl.text.trim();

    if (_isEditing) {
      await svc.rename(widget.deckId!, name);
    } else {
      await svc.create(name);
    }

    if (mounted) context.pop();
  }
}
```

- [ ] **Step 2: 暂不 commit**

---

## Task 11: DeckDetailPage（牌组详情 + 卡片列表）

**Files:**
- Create: `lib/features/decks/presentation/pages/deck_detail_page.dart`

- [ ] **Step 1: DeckDetailPage**

```dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../cards/application/card_service.dart';
import '../../application/deck_service.dart';

class DeckDetailPage extends ConsumerWidget {
  const DeckDetailPage({super.key, required this.deckId});

  final int deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deckAsync = ref.watch(deckByIdProvider(deckId));
    final cardsAsync = ref.watch(cardsByDeckProvider(deckId));

    return Scaffold(
      appBar: AppBar(
        title: deckAsync.when(
          data: (d) => Text(d?.name ?? '未知牌组'),
          loading: () => const Text('加载中…'),
          error: (_, __) => const Text('错误'),
        ),
      ),
      body: cardsAsync.when(
        data: (cards) {
          if (cards.isEmpty) {
            return const Center(child: Text('这个牌组还没有卡片'));
          }
          return ListView.separated(
            itemCount: cards.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final entry = cards[i];
              final fields = jsonDecode(entry.note.fields)
                  as Map<String, dynamic>;
              final front = (fields['正面'] ?? '').toString();
              return ListTile(
                title: Text(
                  front,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('卡片 #${entry.card.id}'),
                onTap: () =>
                    context.push('/cards/${entry.card.id}/edit'),
                onLongPress: () => _confirmDeleteCard(
                  context,
                  ref,
                  cardId: entry.card.id,
                  noteId: entry.note.id,
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/decks/$deckId/cards/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmDeleteCard(
    BuildContext context,
    WidgetRef ref, {
    required int cardId,
    required int noteId,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除卡片？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(cardServiceProvider)
          .deleteCard(cardId: cardId, noteId: noteId);
    }
  }
}
```

- [ ] **Step 2: 暂不 commit**

---

## Task 12: CardEditPage（创建/编辑卡片）

**Files:**
- Create: `lib/features/cards/presentation/pages/card_edit_page.dart`

- [ ] **Step 1: CardEditPage**

```dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/database_provider.dart';
import '../../application/card_service.dart';

class CardEditPage extends ConsumerStatefulWidget {
  /// 创建模式：必须提供 deckId。
  /// 编辑模式：必须提供 editingCardId。
  const CardEditPage({super.key, this.deckId, this.editingCardId})
      : assert(deckId != null || editingCardId != null,
            'deckId 或 editingCardId 至少需要一个');

  final int? deckId;
  final int? editingCardId;

  @override
  ConsumerState<CardEditPage> createState() => _CardEditPageState();
}

class _CardEditPageState extends ConsumerState<CardEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _frontCtl = TextEditingController();
  final _backCtl = TextEditingController();
  bool _saving = false;
  bool _initialized = false;
  int? _editingNoteId;

  bool get _isEditing => widget.editingCardId != null;

  @override
  void dispose() {
    _frontCtl.dispose();
    _backCtl.dispose();
    super.dispose();
  }

  Future<void> _loadIfEditing() async {
    if (_initialized) return;
    if (!_isEditing) {
      _initialized = true;
      return;
    }

    final db = ref.read(databaseProvider);
    final card = await db.cardsDao.getById(widget.editingCardId!);
    if (card == null) {
      _initialized = true;
      return;
    }
    final note = await db.notesDao.getById(card.noteId);
    if (note != null) {
      _editingNoteId = note.id;
      final fields = jsonDecode(note.fields) as Map<String, dynamic>;
      _frontCtl.text = (fields['正面'] ?? '').toString();
      _backCtl.text = (fields['反面'] ?? '').toString();
    }
    _initialized = true;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadIfEditing(),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_isEditing ? '编辑卡片' : '新建卡片'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _frontCtl,
                    decoration: const InputDecoration(
                      labelText: '正面',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 2,
                    maxLines: 5,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '请输入正面' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _backCtl,
                    decoration: const InputDecoration(
                      labelText: '反面',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 2,
                    maxLines: 8,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '请输入反面' : null,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving ? null : () => context.pop(),
                          child: const Text('取消'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          onPressed: _saving ? null : _onSave,
                          child: Text(_saving ? '保存中…' : '保存'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final svc = ref.read(cardServiceProvider);
    final front = _frontCtl.text.trim();
    final back = _backCtl.text.trim();

    if (_isEditing) {
      if (_editingNoteId == null) {
        if (mounted) context.pop();
        return;
      }
      await svc.updateBasicCard(
        noteId: _editingNoteId!,
        front: front,
        back: back,
      );
    } else {
      await svc.createBasicCard(
        deckId: widget.deckId!,
        front: front,
        back: back,
      );
    }
    if (mounted) context.pop();
  }
}
```

- [ ] **Step 2: 跑 analyze + test 整体回归**

```bash
flutter analyze
flutter test
```

预期：0 issues; 之前所有测试 + 本里程碑测试都通过。

- [ ] **Step 3: 真机验证**

```bash
flutter build apk --debug
flutter install -d <your-android-id> --debug
```

手动操作验证：
1. 启动 App，看到 "还没有牌组，点 + 新建一个"
2. 点 FAB → 输入"测试牌组" → 保存 → 列表显示"测试牌组 0 张卡片"
3. 点该牌组 → 看到 "这个牌组还没有卡片"
4. 点 FAB → 输入正面"光速"反面"3e8 m/s" → 保存
5. 返回详情页，看到一张卡片
6. 长按卡片 → 删除 → 列表为空
7. 返回首页，长按牌组 → 删除 → 列表空

- [ ] **Step 4: 一次性 commit Task 8-12 全部 UI 变更**

```bash
git add lib/core/routing/app_router.dart \
        lib/features/decks/presentation/ \
        lib/features/cards/presentation/

git commit -m "feat(ui): deck/card list, edit, detail pages

- /                    DeckListPage   牌组列表（带卡片数）
- /decks/new           DeckEditPage   新建牌组
- /decks/:id           DeckDetailPage 牌组详情 + 卡片列表
- /decks/:id/edit      DeckEditPage   编辑牌组
- /decks/:id/cards/new CardEditPage   新建卡片
- /cards/:id/edit      CardEditPage   编辑卡片

完整 CRUD 闭环：建牌组 → 进入 → 加卡片 → 编辑/删除 → 返回。"
```

---

## Task 13: 全面回归 + M2 完成日志

**Files:**
- Create: `docs/devlog/<DATE>-m2-complete.md`

- [ ] **Step 1: flutter analyze + flutter test 全部通过**

```bash
flutter analyze
flutter test
```

- [ ] **Step 2: 真机回归（按 Task 12 Step 3 的清单跑一遍）**

- [ ] **Step 3: 写 devlog**

模板（`docs/devlog/<DATE>-m2-complete.md`，DATE 用当天）：

```markdown
# M2 完成日志

**日期**：YYYY-MM-DD
**项目**：anki_multi
**对应里程碑**：M2 — 牌组与卡片 CRUD

## 完成事项

- [x] Task 1: NoteTypesDao + Basic/Cloze seed
- [x] Task 2: databaseProvider 自动 seed
- [x] Task 3: DecksDao + tests
- [x] Task 4: NotesDao + CardsDao + tests
- [x] Task 5: domain 聚合（实际全在 dao 里）
- [x] Task 6: DeckService + Riverpod
- [x] Task 7: CardService + Riverpod
- [x] Task 8: routing 5 条新路由
- [x] Task 9: DeckListPage
- [x] Task 10: DeckEditPage
- [x] Task 11: DeckDetailPage
- [x] Task 12: CardEditPage
- [x] Task 13: 回归 + 本日志

## 实际投入时间

约 X 小时

## 问题与解决

（写下你遇到的至少 1 个有意思的坑）

## 下一步：M3 — FSRS 复习引擎

预计 Week 5-6，10 小时。M3 完成后**项目可自用**。
```

- [ ] **Step 4: Commit**

```bash
git add docs/devlog/
git commit -m "docs: M2 completion devlog"
git push
git tag -a v0.0.2-m2 -m "M2: deck/card CRUD complete"
git push --tags
```

---

## 验收清单（M2 整体）

完成 M2 时，以下所有条目都必须通过：

- [ ] `flutter analyze` 0 errors
- [ ] `flutter test` 所有测试通过（应有 ~14 个测试：M1 的 2 + M2 新增的 12 左右）
- [ ] 真机能完成"建牌组 → 加几张卡片 → 编辑 → 删除"全流程
- [ ] git 历史清晰，每个 task 至少 1 个 commit
- [ ] devlog 写完
- [ ] 标签 `v0.0.2-m2` 推到远程

---

## Risks & Notes

### 已知 v0.1 局限（M2 不修，未来版本再处理）

1. **删除牌组不级联删除卡片**：drift schema 没设 ON DELETE CASCADE。删除牌组后，原属该牌组的卡片会变成"孤儿"。M3+ 需要在 DeckService.delete 中先删该 deck 的所有 cards/notes。
2. **没有撤销机制**：删除卡片/牌组立即生效，没有 trash bin。
3. **Basic 卡片只生成 1 张**：实际 Anki 的 Basic 类型可以配置生成"反 → 正"卡，但我们 v0.1 简化为 1 note → 1 card。
4. **Cloze NoteType 已 seed 但 UI 不能创建 Cloze 卡片**：CardEditPage 当前只支持 Basic。Cloze 在 M5 开发。

### Tips

- **drift codegen 卡住**：`dart run build_runner clean && dart run build_runner build`
- **AsyncValue.when 拿到 error**：先看 console，drift schema 错误会在 stack trace 里
- **路由不生效**：确认 GoRouter 重新创建了（修改 app_router.dart 后 hot restart 才生效，hot reload 可能不够）
