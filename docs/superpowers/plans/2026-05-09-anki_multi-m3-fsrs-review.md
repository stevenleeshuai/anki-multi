# M3 — FSRS 复习引擎 + 复习页 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在指定牌组内按 FSRS 调度复习卡片：展示正面 → 翻面看反面 → Again / Hard / Good / Easy 四档评分；每次评分更新 `cards` 行状态并追加一条 `reviews` 日志；牌组详情页可一键进入复习流。

**Architecture:** `fsrs` 包的 `Scheduler.reviewCard` 是唯一调度入口；纯 Dart 的 `FsrsCardMapper` 负责 drift `Card`（SQLite 行）与 `fsrs.Card` 互转（含 DB `state == 0`「新建」与 fsrs `State` 1/2/3 的差异）；`ReviewService`  orchestrate「读下一张 → 评分 → 事务写库 + 插日志」；`ReviewsDao` 只负责插入；`CardsDao` 增加「下一张待复习」查询；UI 用 Riverpod 读 `ReviewService`，路由 `/decks/:id/study`。

**Tech Stack:** `fsrs` ^2.0.1（`Scheduler`、`Rating`、`State`、`Card`）、drift migration、`customSelect` 或 typed query、`flutter_riverpod`、`go_router`。

**预计时长：** ~10–14 小时（Week 5–6）

**对应 spec：** `docs/superpowers/specs/2026-05-09-anki_multi-design.md` §5.3、里程碑表 M3

---

## 关键约定（实现前必读）

### 1. 命名冲突：`Card`

- drift 生成的类名是 **`Card`**（`database.dart`）。
- `package:fsrs/fsrs.dart` 也有 **`Card`**。

**强制写法**（二选一，全仓库一致即可）：

```dart
import 'package:anki_multi/core/database/database.dart' as db;
import 'package:fsrs/fsrs.dart' as fsrs;
// drift 行: db.Card
// 算法侧: fsrs.Card
```

或 `hide Card` + 单一前缀；**禁止**在同一文件无前缀混用两个 `Card`。

### 2. DB `state` 与 fsrs `State`

| `cards.state`（SQLite） | 含义 | 映射到 `fsrs.Card` |
|-------------------------|------|---------------------|
| **0** | 新建（M2 插入默认值，从未复习） | `fsrs.State.learning`，`step = 0`，`stability` / `difficulty` **null**（与 fsrs 新卡一致） |
| **1** | Learning | `fsrs.State.learning`，`step = learningStep ?? 0` |
| **2** | Review | `fsrs.State.review`，`step = null` |
| **3** | Relearning | `fsrs.State.relearning`，`step = learningStep ?? 0` |

持久化时：把 `fsrs.Card.state.value`、`fsrs.Card.step` 写回 `cards.state` / `cards.learningStep`。

### 3. UTC

`Scheduler.reviewCard` 若传入 `reviewDateTime`，**必须是 UTC**（详见 fsrs 源码 `reviewDateTime.isUtc` 断言）。统一：

```dart
final reviewUtc = DateTime.now().toUtc();
scheduler.reviewCard(fsrsCard, rating, reviewDateTime: reviewUtc);
```

### 4. 为何新增列 `learningStep`

fsrs 在 Learning / Relearning 阶段使用 **`step`**（分钟级间隔）。当前 `cards` 表无对应字段，**必须在 M3 做 schema v2 迁移**，否则 Learning 队列无法在重启后恢复。

---

## File Structure 概览

| 文件 | 作用 |
|------|------|
| `lib/core/database/tables/cards_table.dart` | 增加 `learningStep` 可空列 |
| `lib/core/database/database.dart` | `schemaVersion => 2`，`MigrationStrategy.onUpgrade` |
| `lib/core/database/daos/reviews_dao.dart` | `Reviews` 插入 |
| `lib/core/database/daos/cards_dao.dart` | `getNextDueWithNote`、`updateCardFsrs`（或通用 `updateCard`） |
| `lib/core/database/database.dart` | `@DriftDatabase` 注册 `ReviewsDao` |
| `lib/features/review/domain/fsrs_card_mapper.dart` | drift ↔ fsrs 纯函数 |
| `lib/features/review/application/review_service.dart` | `peekNextDue`、`rate`、事务 |
| `lib/features/review/application/review_providers.dart` | `Scheduler`、`ReviewService` 的 Riverpod |
| `lib/features/review/presentation/pages/review_page.dart` | 复习 UI |
| `lib/core/routing/app_router.dart` | `/decks/:id/study` |
| `lib/features/decks/presentation/pages/deck_detail_page.dart` | AppBar「复习」入口 |
| `test/...` | mapper / DAO / service 测试 |

---

## Task 1: `cards.learningStep` + migration v2

**Files:**
- Modify: `lib/core/database/tables/cards_table.dart`
- Modify: `lib/core/database/database.dart`
- Generated: `lib/core/database/database.g.dart`（build_runner）
- Modify: `test/core/database/database_test.dart`（若插入 cards 需显式带上新列默认值则可不写；nullable 列可不写）

- [ ] **Step 1: 改表定义**

在 `lib/core/database/tables/cards_table.dart` 的 `Cards` 类中，在 `state` 列附近增加：

```dart
IntColumn get learningStep => integer().nullable()();
```

- [ ] **Step 2: 提升 schemaVersion 并实现 onUpgrade**

`lib/core/database/database.dart`：

1. 把 `schemaVersion` 从 `1` 改为 `2`。
2. 增加 `import 'package:drift/drift.dart' show Migrator;`（若已有 drift import 则合并）。
3. 覆盖：

```dart
@override
MigrationStrategy get migration => MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(cards, cards.learningStep);
        }
      },
    );
```

（若项目已有 `onCreate`，合并逻辑，不要重复 `createAll` 两次。）

- [ ] **Step 3: 代码生成**

```bash
cd /Users/stevenlsli/github/anki
dart run build_runner build --build-filter="lib/core/database/**"
```

Expected: 成功生成；`database.g.dart` 含 `learningStep`。

- [ ] **Step 4: 静态检查与测试**

```bash
flutter analyze
flutter test
```

Expected: 0 issues；原有测试通过（插入 `CardsCompanion.insert` 可不填 nullable 列）。

- [ ] **Step 5: Commit**

```bash
git add lib/core/database/tables/cards_table.dart lib/core/database/database.dart lib/core/database/database.g.dart
git commit -m "feat(db): add cards.learningStep + schema v2 migration"
```

---

## Task 2: `FsrsCardMapper`（纯函数）+ 单元测试

**Files:**
- Create: `lib/features/review/domain/fsrs_card_mapper.dart`
- Create: `test/features/review/fsrs_card_mapper_test.dart`

- [ ] **Step 1: 实现 mapper**

`lib/features/review/domain/fsrs_card_mapper.dart`：

```dart
import 'package:anki_multi/core/database/database.dart' as db;
import 'package:fsrs/fsrs.dart' as fsrs;

DateTime _utcFromMillis(int ms) =>
    DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

/// drift [row] → fsrs.Card（用于调用 Scheduler.reviewCard）。
fsrs.Card driftRowToFsrs(db.Card row) {
  final due = _utcFromMillis(row.due);
  final lastReview = row.lastReview != null
      ? _utcFromMillis(row.lastReview!)
      : null;

  if (row.state == 0) {
    return fsrs.Card(
      cardId: row.id,
      state: fsrs.State.learning,
      step: 0,
      stability: null,
      difficulty: null,
      due: due,
      lastReview: lastReview,
    );
  }

  final step = (row.state == 1 || row.state == 3)
      ? (row.learningStep ?? 0)
      : null;

  return fsrs.Card(
    cardId: row.id,
    state: fsrs.State.fromValue(row.state),
    step: step,
    stability: row.stability > 0 ? row.stability : null,
    difficulty: row.difficulty > 0 ? row.difficulty : null,
    due: due,
    lastReview: lastReview,
  );
}

/// 将 [rated]（reviewCard 输出）与评分时刻 [reviewUtc] 同步到 drift Companion。
/// [prev]：评分前的行，用于计算 elapsedDays、lastElapsedDays、reps/lapses。
db.CardsCompanion fsrsResultToCompanion({
  required db.Card prev,
  required fsrs.Card rated,
  required DateTime reviewUtc,
  required fsrs.Rating rating,
  required int nowMillis,
}) {
  final lastReviewMs = rated.lastReview!.millisecondsSinceEpoch;
  final prevLastUtc = prev.lastReview != null
      ? _utcFromMillis(prev.lastReview!)
      : null;
  final elapsedDays = prevLastUtc != null
      ? reviewUtc.difference(prevLastUtc).inDays
      : 0;

  final scheduledDays =
      rated.due.difference(reviewUtc).inDays.clamp(0, 365000);

  var reps = prev.reps;
  var lapses = prev.lapses;
  reps += 1;
  if (rating == fsrs.Rating.again) {
    lapses += 1;
  }

  return db.CardsCompanion(
    due: Value(rated.due.millisecondsSinceEpoch),
    stability: Value(rated.stability ?? 0),
    difficulty: Value(rated.difficulty ?? 0),
    elapsedDays: Value(elapsedDays),
    scheduledDays: Value(scheduledDays),
    reps: Value(reps),
    lapses: Value(lapses),
    state: Value(rated.state.value),
    learningStep: Value(rated.step),
    lastReview: Value(lastReviewMs),
    updatedAt: Value(nowMillis),
  );
}
```

在文件顶部增加：

```dart
import 'package:drift/drift.dart' show Value;
```

并把下面的 `drift.Value` 全部写成 **`Value`**（drift 的 `Value<T>`，不是 `dart:ffi`）。

- [ ] **Step 2: 写测试（新建卡 state=0 → fsrs learning）**

`test/features/review/fsrs_card_mapper_test.dart`：

```dart
import 'package:anki_multi/core/database/database.dart';
import 'package:anki_multi/features/review/domain/fsrs_card_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

void main() {
  test('state 0 映射为 fsrs learning + null S/D', () {
    final row = Card(
      id: 1,
      noteId: 1,
      deckId: 1,
      templateIdx: 0,
      due: 1000,
      stability: 0,
      difficulty: 0,
      elapsedDays: 0,
      scheduledDays: 0,
      reps: 0,
      lapses: 0,
      state: 0,
      lastReview: null,
      createdAt: 1000,
      updatedAt: 1000,
      learningStep: null,
    );

    final c = driftRowToFsrs(row);

    expect(c.state, fsrs.State.learning);
    expect(c.step, 0);
    expect(c.stability, isNull);
    expect(c.difficulty, isNull);
  });
}
```

**注意：** `Card(...)` 构造需与生成器字段一致；若 `learningStep` 在生成代码中为可空 named 参数，按 `database.g.dart` 实际构造函数调整测试（这是 plan 要求「读生成代码」之处）。

再增加一条测试：`Scheduler.customRandom(math.Random(0), enableFuzzing: false)` + `reviewCard` 跑通一轮后，`fsrsResultToCompanion` 写回的 `state` 为 1/2/3 之一且 `due` 大于 `reviewUtc`。

- [ ] **Step 3: 运行测试**

```bash
flutter test test/features/review/fsrs_card_mapper_test.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/review/domain/fsrs_card_mapper.dart test/features/review/fsrs_card_mapper_test.dart
git commit -m "feat(review): drift/fsrs Card mapper + unit tests"
```

---

## Task 3: `ReviewsDao`

**Files:**
- Create: `lib/core/database/daos/reviews_dao.dart` + `part` / `.g.dart`
- Modify: `lib/core/database/database.dart`（`daos: [..., ReviewsDao]`）
- Create: `test/core/database/reviews_dao_test.dart`

- [ ] **Step 1: 写 DAO**

`lib/core/database/daos/reviews_dao.dart`：

```dart
import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/reviews_table.dart';

part 'reviews_dao.g.dart';

@DriftAccessor(tables: [Reviews])
class ReviewsDao extends DatabaseAccessor<AppDatabase> with _$ReviewsDaoMixin {
  ReviewsDao(super.db);

  Future<int> insertReview(ReviewsCompanion entry) =>
      into(reviews).insert(entry);
}
```

运行 build_runner 生成 mixin。

- [ ] **Step 2: 测试插入**

在 `test/core/database/reviews_dao_test.dart` 中：`AppDatabase.forTesting`，插入 deck/note/noteType/card（可抄 `database_test` 最小依赖），再 `ReviewsCompanion.insert(...)`，断言 `select(reviews).get()` 长度为 1。

`ReviewsCompanion.insert` 必填字段与表一致：`cardId, reviewedAt, rating, state, due, stability, difficulty, elapsedDays, lastElapsedDays, scheduledDays`（`durationMs` 有 default 可不写）。

- [ ] **Step 3: Commit**

```bash
git add lib/core/database/daos/reviews_dao.dart lib/core/database/daos/reviews_dao.g.dart lib/core/database/database.dart lib/core/database/database.g.dart test/core/database/reviews_dao_test.dart
git commit -m "feat(db): ReviewsDao + insert test"
```

---

## Task 4: `CardsDao` — 下一张待复习 + 更新 FSRS 字段

**Files:**
- Modify: `lib/core/database/daos/cards_dao.dart`
- Modify: `test/core/database/cards_dao_test.dart`

- [ ] **Step 1: `getNextDueWithNote`**

逻辑：`deckId` 匹配、`due <= nowMs`，排序：

1. `state`：`0 → 1 → 3 → 2`（新建与学习先于复习大间隔，可按产品再调；M3 固定此顺序）。
2. `due ASC`
3. `id ASC`

实现可用 `customSelect`，SQLite 表名为 **`cards`**、**`notes`**（drift 默认 snake_case 表名；若你改过 `tableName` 覆盖符，以生成代码为准）：

```dart
Future<CardWithNote?> getNextDueWithNote({
  required int deckId,
  required int nowMillis,
}) async {
  final rows = await customSelect(
    '''
    SELECT cards.*, notes.*
    FROM cards
    INNER JOIN notes ON notes.id = cards.note_id
    WHERE cards.deck_id = ? AND cards.due <= ?
    ORDER BY
      CASE cards.state
        WHEN 0 THEN 0
        WHEN 1 THEN 1
        WHEN 3 THEN 2
        WHEN 2 THEN 3
        ELSE 9
      END,
      cards.due ASC,
      cards.id ASC
    LIMIT 1
    ''',
    variables: [
      Variable<int>(deckId),
      Variable<int>(nowMillis),
    ],
    readsFrom: {cards, notes},
  ).get();

  if (rows.isEmpty) return null;
  final data = rows.single.data;
  return CardWithNote(
    card: cards.map(data),
    note: notes.map(data),
  );
}
```

若 `map(data)` 签名与 drift 版本不匹配，改用官方文档里推荐的方式把 `QueryRow` 解成两张表（以能通过 analyze + 测试为准）。也可用 **typed `select` + `join`** 表达同等 `ORDER BY`，避免手写 SQL。

**完成判据：** 单测覆盖「同一 deck 两张卡，`due`/`state` 不同时选出正确一张」。

- [ ] **Step 2: 更新方法**

`Future<bool> updateCard(int id, CardsCompanion data)` 已在 pattern 中常见；若无则添加。

- [ ] **Step 3: 测试**

在 `cards_dao_test.dart` 增加：同一 deck 插入两张卡，`due` 不同，`state` 不同，断言 `getNextDueWithNote` 返回期望 id。

- [ ] **Step 4: Commit**

```bash
git add lib/core/database/daos/cards_dao.dart test/core/database/cards_dao_test.dart lib/core/database/daos/cards_dao.g.dart
git commit -m "feat(db): CardsDao getNextDueWithNote + ordering tests"
```

---

## Task 5: `ReviewService`

**Files:**
- Create: `lib/features/review/application/review_service.dart`
- Create: `test/features/review/review_service_test.dart`

- [ ] **Step 1: 类骨架**

```dart
import 'package:anki_multi/core/database/database.dart' as db;
import 'package:anki_multi/features/review/domain/fsrs_card_mapper.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

class ReviewService {
  ReviewService(this._db, this._scheduler);

  final db.AppDatabase _db;
  final fsrs.Scheduler _scheduler;

  Future<db.CardWithNote?> peekNextDue(int deckId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _db.cardsDao.getNextDueWithNote(deckId: deckId, nowMillis: now);
  }

  Future<void> rateCard({
    required int deckId,
    required int cardId,
    required fsrs.Rating rating,
  }) async {
    final reviewUtc = DateTime.now().toUtc();
    final nowMillis = DateTime.now().millisecondsSinceEpoch;

    await _db.transaction(() async {
      final row = await _db.cardsDao.getById(cardId);
      if (row == null || row.deckId != deckId) {
        throw ArgumentError('card not in deck');
      }

      final fsrsCard = driftRowToFsrs(row);
      final rated = _scheduler
          .reviewCard(
            fsrsCard,
            rating,
            reviewDateTime: reviewUtc,
          )
          .card;

      final companion = fsrsResultToCompanion(
        prev: row,
        rated: rated,
        reviewUtc: reviewUtc,
        rating: rating,
        nowMillis: nowMillis,
      );

      await _db.cardsDao.updateCard(cardId, companion);

      await _db.reviewsDao.insertReview(
        db.ReviewsCompanion.insert(
          cardId: cardId,
          reviewedAt: reviewUtc.millisecondsSinceEpoch,
          rating: rating.value,
          state: rated.state.value,
          due: rated.due.millisecondsSinceEpoch,
          stability: rated.stability ?? 0,
          difficulty: rated.difficulty ?? 0,
          elapsedDays: companion.elapsedDays.value!,
          lastElapsedDays: row.elapsedDays,
          scheduledDays: companion.scheduledDays.value!,
        ),
      );
    });
  }
}
```

**要点：** `ReviewsCompanion.insert` 需要原生 **`int`/`double`**。`fsrsResultToCompanion` 已对 `elapsedDays` / `scheduledDays` 赋 `Value`，用 **`companion.elapsedDays.value!`**（实现里若不愿 `!`，可在 mapper 里额外返回 `(elapsedDays: int, scheduledDays: int)` 元组）。

**事务：** 使用 **`await _db.transaction(() async { ... })`**（`AppDatabase` 继承 Drift 的 `transaction`）。

**Scheduler 测试：** `ReviewService` 构造函数注入 `fsrs.Scheduler.customRandom(math.Random(0), enableFuzzing: false)`。

- [ ] **Step 2: 服务测试**

集成风格：`AppDatabase.forTesting`，插入 deck + note + card（state 0），调用 `rateCard`，再读 `cards` 行 `state != 0` 且 `reviews` 表多一行。

- [ ] **Step 3: Commit**

```bash
git add lib/features/review/application/review_service.dart test/features/review/review_service_test.dart
git commit -m "feat(review): ReviewService peek + rate with transaction"
```

---

## Task 6: Riverpod providers

**Files:**
- Create: `lib/features/review/application/review_providers.dart`

- [ ] **Step 1: 实现**

```dart
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

import '../../../core/database/database_provider.dart';
import 'review_service.dart';

final fsrsSchedulerProvider = Provider<fsrs.Scheduler>((ref) {
  return fsrs.Scheduler.customRandom(
    math.Random(),
    enableFuzzing: true,
  );
});

final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService(
    ref.watch(databaseProvider),
    ref.watch(fsrsSchedulerProvider),
  );
});
```

生产环境用真随机 + fuzz；**单测不引用该 provider**，直接 new `ReviewService(db, testScheduler)`。

- [ ] **Step 2: analyze + commit**

```bash
git add lib/features/review/application/review_providers.dart
git commit -m "feat(review): Riverpod providers for Scheduler + ReviewService"
```

---

## Task 7: `ReviewPage` UI

**Files:**
- Create: `lib/features/review/presentation/pages/review_page.dart`

- [ ] **Step 1: 行为**

- `ConsumerStatefulWidget`，`deckId` 构造参数。
- `initState` / `didChangeDependencies`：首次 `_load()`：`peekNextDue` → 若无卡：`Center` 文案「暂无待复习卡片」+ `TextButton` 关闭（`context.pop()`）。
- 有卡：显示正面（从 `note.fields` JSON 取 `正面`，与 `CardService` 字段名一致）。
- `IconButton` / `FAB`「翻面」切换 `_showBack`。
- 翻面后显示四个 `FilledButton` 或 `SegmentedButton`：Again / Hard / Good / Easy → 调用 `rateCard`，然后 `_load()` 下一张。
- 加载中：`CircularProgressIndicator`。

**评分枚举：** `fsrs.Rating.again` … `easy`。

**错误：** `SnackBar` 显示 `ArgumentError` 消息。

- [ ] **Step 2: 反面文本**

取 `反面` 字段；若无 key，显示空字符串。

- [ ] **Step 3: Commit**

```bash
git add lib/features/review/presentation/pages/review_page.dart
git commit -m "feat(review): ReviewPage flip + four ratings"
```

---

## Task 8: 路由 + 牌组详情入口

**Files:**
- Modify: `lib/core/routing/app_router.dart`
- Modify: `lib/features/decks/presentation/pages/deck_detail_page.dart`

- [ ] **Step 1: 路由**

增加：

```dart
GoRoute(
  path: '/decks/:id/study',
  builder: (context, state) {
    final id = int.parse(state.pathParameters['id']!);
    return ReviewPage(deckId: id);
  },
),
```

别忘了 `import` `ReviewPage`。

- [ ] **Step 2: DeckDetailPage AppBar**

`actions: [ IconButton(icon: const Icon(Icons.school_outlined), tooltip: '复习', onPressed: () => context.push('/decks/$deckId/study'), ), ]`

- [ ] **Step 3: Commit**

```bash
git add lib/core/routing/app_router.dart lib/features/decks/presentation/pages/deck_detail_page.dart
git commit -m "feat(routing): deck study route + deck detail entry"
```

---

## Task 9: 全量回归 + 真机清单

- [ ] **Step 1: 命令**

```bash
flutter analyze
flutter test
```

Expected: 0 issues；测试数 ≥ 原 20 + 新增。

- [ ] **Step 2: 真机（Android）**

1. 打开牌组详情 → 点「复习」→ 空牌组见空态文案。
2. 添加一张 Basic 卡 → 复习 → 见正面 → 翻面 → 四键其一 → 回到「暂无待复习」或下一张（一张卡时完成）。
3. 回到列表 / 详情，确认卡片未丢失。

- [ ] **Step 3: Commit devlog（可选单独 commit）**

写 `docs/devlog/2026-05-09-m3-complete.md`（模板同 M2），**不在本 plan 展开全文**。

---

## Spec coverage（自检）

| Spec 要求 | Task |
|-----------|------|
| FSRS 调度 | Task 2、5、6 |
| 四按钮 | Task 7 |
| `ReviewService` | Task 5 |
| `reviews` 日志 | Task 3、5 |
| 无效 rating | fsrs 枚举无无效值；deck/card 不匹配 `ArgumentError`（Task 5） |
| 核心单测覆盖调度 | Task 2、5 |

## Placeholder scan

- 无 TBD；Task 4 SQL 若需替换为 typed query，以「单测覆盖排序」为完成判据。

## Type consistency

- drift `Card` 始终 `db.Card` 或通过 `database.dart` 导入；fsrs 始终 `fsrs.Card`。
- `Rating` 仅用 `fsrs.Rating`。

---

**Plan complete:** `docs/superpowers/plans/2026-05-09-anki_multi-m3-fsrs-review.md`

**Execution options:**

1. **Subagent-Driven（推荐）** — 每 Task 派独立子代理实现 → spec review → code review → 主代理裁决；与 M2 相同节奏。  
2. **Inline Execution** — 本会话按 Task 顺序连续实现，用 executing-plans 做 checkpoint。

你想用哪一种推进 M3？
