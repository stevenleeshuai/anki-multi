# M1 — 项目脚手架 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 完成 anki_multi 项目的初始脚手架——能在 Android 真机上跑起来一个连通了 SQLite 数据库的 Flutter 应用，所有核心依赖装好，开源协议、README、目录结构、主题、路由、Riverpod 都就位。

**Architecture:** Flutter App 采用 feature-based 目录结构；drift 作为 SQLite ORM；Riverpod 作为状态管理；go_router 作为路由器。M1 只搭骨架——schema 定义完整但 UI 仅一个 Hello World 首页用于验证 build/run 链路打通。

**Tech Stack:** Flutter 3.x, Dart 3.x, drift（含 build_runner 代码生成）, flutter_riverpod, go_router, sqlite3_flutter_libs, path_provider

**预计时长：** ~10 小时（Week 1-2，每周 5 小时）

**对应 spec：** `docs/superpowers/specs/2026-05-09-anki_multi-design.md`

---

## File Structure 概览

本里程碑创建/修改的所有文件：

| 文件 | 作用 |
|---|---|
| `pubspec.yaml` | 项目依赖 |
| `analysis_options.yaml` | 静态检查配置 |
| `LICENSE` | AGPL v3 全文 |
| `README.md` | 项目说明 |
| `.gitignore` | Flutter create 自动生成，附加少量自定义 |
| `lib/main.dart` | 应用入口 |
| `lib/app.dart` | MaterialApp + 路由根 |
| `lib/core/theme/app_theme.dart` | 主题（亮/暗） |
| `lib/core/routing/app_router.dart` | go_router 路由表 |
| `lib/core/database/database.dart` | drift Database 类与表定义 |
| `lib/core/database/database.g.dart` | drift 自动生成（不手写） |
| `lib/core/database/tables/decks_table.dart` | decks 表 |
| `lib/core/database/tables/note_types_table.dart` | note_types 表 |
| `lib/core/database/tables/notes_table.dart` | notes 表 |
| `lib/core/database/tables/cards_table.dart` | cards 表 |
| `lib/core/database/tables/reviews_table.dart` | reviews 表 |
| `lib/core/database/tables/media_table.dart` | media 表 |
| `lib/core/database/tables/settings_table.dart` | settings 表 |
| `lib/core/database/database_provider.dart` | Riverpod provider 提供 Database 实例 |
| `lib/features/home/presentation/pages/home_page.dart` | Hello World 首页（M1 验证用） |
| `test/core/database/database_test.dart` | 数据库 schema 集成测试 |

---

## Task 0: 前置环境检查

**目的：** 确认开发环境就绪，避免后续步骤受阻。

- [ ] **Step 1: 确认 Flutter SDK 已安装且版本符合**

```bash
flutter --version
```
预期：输出 Flutter 3.16+（任何 3.x 都行，建议最新 stable）

如果未安装，参考 https://docs.flutter.dev/get-started/install 安装。

- [ ] **Step 2: 跑 flutter doctor 检查 Android 工具链**

```bash
flutter doctor -v
```
预期：以下三项必须 ✓
- Flutter
- Android toolchain
- Android Studio（或 IntelliJ）

如果 Android toolchain 报错，先解决再继续。

- [ ] **Step 3: 准备 Android 真机**

操作：
1. Android 手机打开"开发者选项"
2. 开启"USB 调试"
3. 用 USB 线连接电脑

验证：

```bash
flutter devices
```

预期：列表中能看到你的手机（至少一个 mobile 设备）。

---

## Task 1: 创建 Flutter 项目

**Files:**
- Create: 整个 Flutter 项目骨架（自动生成）

- [ ] **Step 1: 在当前空目录创建 Flutter 项目**

注意：当前目录 `/Users/stevenlsli/github/anki` 已经是 git 仓库且包含 `docs/`，不能直接 `flutter create .` 因为它会要求空目录。我们需要用 `--no-overwrite` 或手动方法。

实际命令：

```bash
flutter create --org com.anki_multi --project-name anki_multi --platforms=android,ios,linux,macos,windows .
```

预期：

```
Created project anki_multi in <path>
```

如果报"directory not empty"，加 `--overwrite`（但要注意 docs/ 不会被影响）：

```bash
flutter create --org com.anki_multi --project-name anki_multi --platforms=android,ios,linux,macos,windows --overwrite .
```

- [ ] **Step 2: 验证项目可构建**

```bash
flutter build apk --debug
```

预期：构建成功，生成 `build/app/outputs/flutter-apk/app-debug.apk`。第一次构建会慢（5-10 分钟），耐心等待。

- [ ] **Step 3: 提交此基线（一次原子提交）**

```bash
git add .
git status
git commit -m "chore: scaffold flutter project with flutter create"
```

---

## Task 2: 配置 pubspec.yaml 全部依赖

**Files:**
- Modify: `pubspec.yaml`

**目的：** 一次性把整个 v0.1 需要的依赖全装上，免得后面零散加。

- [ ] **Step 1: 替换 pubspec.yaml dependencies 段为以下内容**

把 `pubspec.yaml` 中 `dependencies:` 部分（注意保留顶部 name/description/version 和 environment）改成：

```yaml
dependencies:
  flutter:
    sdk: flutter

  # 状态管理
  flutter_riverpod: ^2.5.1

  # 路由
  go_router: ^14.2.0

  # 数据库
  drift: ^2.18.0
  sqlite3_flutter_libs: ^0.5.24
  path_provider: ^2.1.3
  path: ^1.9.0

  # FSRS 算法
  fsrs: ^2.0.1

  # Markdown 渲染（flutter_markdown 已废弃，用 flutter_markdown_plus 替代）
  flutter_markdown_plus: ^1.0.7

  # TTS
  flutter_tts: ^4.0.2

  # UI 工具
  cupertino_icons: ^1.0.8
```

- [ ] **Step 2: 替换 dev_dependencies**

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter

  # 静态检查
  flutter_lints: ^4.0.0

  # 代码生成
  drift_dev: ^2.18.0
  build_runner: ^2.4.11

  # 测试工具
  mocktail: ^1.0.4
```

- [ ] **Step 3: 安装依赖**

```bash
flutter pub get
```

预期：输出 `Got dependencies!`，无报错。如果某个版本不存在，把版本号改成 `flutter pub get` 报错信息中提示的最新版本。

- [ ] **Step 4: 提交**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add core dependencies for v0.1"
```

---

## Task 3: 添加 LICENSE / README / 静态检查配置

**Files:**
- Create: `LICENSE`
- Replace: `README.md` (Flutter create 已生成默认版本)
- Modify: `analysis_options.yaml`

- [ ] **Step 1: 写入 AGPL v3 LICENSE 文件**

到 https://www.gnu.org/licenses/agpl-3.0.txt 下载完整 AGPL v3 文本，保存为 `LICENSE`。或运行：

```bash
curl -fsSL https://www.gnu.org/licenses/agpl-3.0.txt -o LICENSE
```

预期：得到一个约 35KB 的纯文本文件，开头是 `GNU AFFERO GENERAL PUBLIC LICENSE`。

- [ ] **Step 2: 替换 README.md**

把 README.md 全部内容替换成：

```markdown
# anki_multi

一个开源、跨平台、Local-first 的速记卡应用，使用 FSRS 算法做调度。

> **状态**：早期开发中（M1 进行中）

## 特点（v0.1 目标）

- 🌐 跨平台：Android / iOS / macOS / Windows / Linux（v0.1 仅 Android 调试）
- 🧠 FSRS 算法（业界最先进的间隔重复调度）
- 📝 Markdown 卡片 + 图片附件 + 挖空（Cloze）
- 🔊 多语言 TTS
- 💾 Local-first：数据全在本地 SQLite，不强制云同步
- 📤 JSON 备份/恢复

## 路线图

详见 `docs/superpowers/specs/2026-05-09-anki_multi-design.md`。

## License

AGPL v3.0（详见 LICENSE 文件）
```

- [ ] **Step 3: 配置静态检查**

替换 `analysis_options.yaml` 内容为：

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    invalid_annotation_target: ignore
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"

linter:
  rules:
    avoid_print: true
    prefer_single_quotes: true
    require_trailing_commas: true
    sort_pub_dependencies: false
```

- [ ] **Step 4: 验证 lint 跑通**

```bash
flutter analyze
```

预期：可能有一些初始 warnings 来自模板代码，但不应有 errors。

- [ ] **Step 5: 提交**

```bash
git add LICENSE README.md analysis_options.yaml
git commit -m "docs: add AGPL v3 license, README, and lint config"
```

---

## Task 4: 创建 feature-based 目录结构

**Files:**
- Create: 一系列空目录（Dart 不需要 `__init__.py`，所以只需创建目录）

- [ ] **Step 1: 删除模板生成的 lib/main.dart**

`flutter create` 生成的默认 `lib/main.dart` 会覆盖我们后面写的，先备份再删除：

```bash
rm lib/main.dart
```

- [ ] **Step 2: 创建目录结构**

```bash
mkdir -p lib/core/database/tables \
         lib/core/database/daos \
         lib/core/theme \
         lib/core/routing \
         lib/features/home/presentation/pages \
         lib/features/decks/domain \
         lib/features/decks/data \
         lib/features/decks/application \
         lib/features/decks/presentation/pages \
         lib/features/cards/domain \
         lib/features/cards/data \
         lib/features/cards/application \
         lib/features/cards/presentation/pages \
         lib/features/review/domain \
         lib/features/review/data \
         lib/features/review/application \
         lib/features/review/presentation/pages \
         lib/features/stats/presentation/pages \
         lib/features/settings/presentation/pages \
         lib/features/tts \
         lib/shared/widgets
```

预期：目录创建成功，无错误输出。

- [ ] **Step 3: 在每个底层目录放 `.gitkeep` 占位**

```bash
find lib -type d -empty -exec touch {}/.gitkeep \;
```

- [ ] **Step 4: 验证目录结构**

```bash
tree -L 4 lib
```

预期：输出符合 spec 5.2 节的 feature-based 结构。

- [ ] **Step 5: 提交**

```bash
git add lib/
git commit -m "chore: scaffold feature-based directory layout"
```

---

## Task 5: 定义 drift Tables（七张表）

**Files:**
- Create: `lib/core/database/tables/decks_table.dart`
- Create: `lib/core/database/tables/note_types_table.dart`
- Create: `lib/core/database/tables/notes_table.dart`
- Create: `lib/core/database/tables/cards_table.dart`
- Create: `lib/core/database/tables/reviews_table.dart`
- Create: `lib/core/database/tables/media_table.dart`
- Create: `lib/core/database/tables/settings_table.dart`

每张表一个文件。drift 的表用 Dart class 继承 `Table` 表达。

- [ ] **Step 1: 创建 decks 表**

`lib/core/database/tables/decks_table.dart`：

```dart
import 'package:drift/drift.dart';

class Decks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get parentId => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}
```

- [ ] **Step 2: 创建 note_types 表**

`lib/core/database/tables/note_types_table.dart`：

```dart
import 'package:drift/drift.dart';

class NoteTypes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get fields => text()(); // JSON: ["正面", "反面"]
  TextColumn get templates => text()(); // JSON: 卡片模板定义
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}
```

- [ ] **Step 3: 创建 notes 表**

`lib/core/database/tables/notes_table.dart`：

```dart
import 'package:drift/drift.dart';

class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get noteTypeId => integer()();
  TextColumn get fields => text()(); // JSON: {"正面": "...", "反面": "..."}
  TextColumn get tags => text().withDefault(const Constant(''))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}
```

- [ ] **Step 4: 创建 cards 表**

`lib/core/database/tables/cards_table.dart`：

```dart
import 'package:drift/drift.dart';

class Cards extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get noteId => integer()();
  IntColumn get deckId => integer()();
  IntColumn get templateIdx => integer().withDefault(const Constant(0))();

  // FSRS 状态
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
```

- [ ] **Step 5: 创建 reviews 表**

`lib/core/database/tables/reviews_table.dart`：

```dart
import 'package:drift/drift.dart';

class Reviews extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cardId => integer()();
  IntColumn get reviewedAt => integer()();
  IntColumn get rating => integer()(); // 1=Again 2=Hard 3=Good 4=Easy
  IntColumn get state => integer()();
  IntColumn get due => integer()();
  RealColumn get stability => real()();
  RealColumn get difficulty => real()();
  IntColumn get elapsedDays => integer()();
  IntColumn get lastElapsedDays => integer()();
  IntColumn get scheduledDays => integer()();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
}
```

- [ ] **Step 6: 创建 media 表**

`lib/core/database/tables/media_table.dart`：

```dart
import 'package:drift/drift.dart';

class Media extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get filename => text().unique()();
  TextColumn get originalName => text()();
  IntColumn get size => integer()();
  TextColumn get mimeType => text()();
  IntColumn get createdAt => integer()();
}
```

- [ ] **Step 7: 创建 settings 表**

`lib/core/database/tables/settings_table.dart`：

```dart
import 'package:drift/drift.dart';

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
```

- [ ] **Step 8: 提交**

```bash
git add lib/core/database/tables/
git commit -m "feat(db): define seven core drift tables"
```

---

## Task 6: 创建 Database 类 + 代码生成

**Files:**
- Create: `lib/core/database/database.dart`

- [ ] **Step 1: 创建 Database 类**

`lib/core/database/database.dart`：

```dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/cards_table.dart';
import 'tables/decks_table.dart';
import 'tables/media_table.dart';
import 'tables/note_types_table.dart';
import 'tables/notes_table.dart';
import 'tables/reviews_table.dart';
import 'tables/settings_table.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  Decks,
  NoteTypes,
  Notes,
  Cards,
  Reviews,
  Media,
  Settings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // 仅供测试用：注入自定义 executor（如内存 DB）
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'anki_multi.sqlite'));
    return NativeDatabase(file);
  });
}
```

注意：此时 `_$AppDatabase` 还不存在（drift 代码生成器待运行）。IDE 会标红，正常。

- [ ] **Step 2: 运行 build_runner 生成代码**

```bash
dart run build_runner build --delete-conflicting-outputs
```

预期：
- 输出有 "Succeeded" 字样
- 生成 `lib/core/database/database.g.dart` 文件

- [ ] **Step 3: 验证编译通过**

```bash
flutter analyze lib/core/database/
```

预期：无错误。

- [ ] **Step 4: 提交**

```bash
git add lib/core/database/database.dart lib/core/database/database.g.dart
git commit -m "feat(db): add AppDatabase wrapper with code generation"
```

---

## Task 7: 写数据库集成测试（TDD 切入点）

**Files:**
- Create: `test/core/database/database_test.dart`

这是 M1 第一个真正的测试。验证 schema 工作正常。

- [ ] **Step 1: 写测试**

`test/core/database/database_test.dart`：

```dart
import 'package:anki_multi/core/database/database.dart';
import 'package:drift/drift.dart' hide isNull; // hide isNull 避免与 matcher 冲突
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

  test('能创建并查询 Deck', () async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final id = await db.into(db.decks).insert(
          DecksCompanion.insert(
            name: '默认牌组',
            createdAt: now,
            updatedAt: now,
          ),
        );

    final fetched = await (db.select(db.decks)
          ..where((d) => d.id.equals(id)))
        .getSingle();

    expect(fetched.name, '默认牌组');
    expect(fetched.parentId, isNull);
  });

  test('七张表都能 insert 一条数据不报错', () async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Deck
    await db.into(db.decks).insert(
          DecksCompanion.insert(name: 'D', createdAt: now, updatedAt: now),
        );

    // NoteType
    final noteTypeId = await db.into(db.noteTypes).insert(
          NoteTypesCompanion.insert(
            name: 'Basic',
            fields: '["正面","反面"]',
            templates: '[]',
            createdAt: now,
            updatedAt: now,
          ),
        );

    // Note
    final noteId = await db.into(db.notes).insert(
          NotesCompanion.insert(
            noteTypeId: noteTypeId,
            fields: '{}',
            createdAt: now,
            updatedAt: now,
          ),
        );

    // Card
    final cardId = await db.into(db.cards).insert(
          CardsCompanion.insert(
            noteId: noteId,
            deckId: 1,
            due: now,
            createdAt: now,
            updatedAt: now,
          ),
        );

    // Review
    await db.into(db.reviews).insert(
          ReviewsCompanion.insert(
            cardId: cardId,
            reviewedAt: now,
            rating: 3,
            state: 0,
            due: now,
            stability: 1.0,
            difficulty: 5.0,
            elapsedDays: 0,
            lastElapsedDays: 0,
            scheduledDays: 1,
          ),
        );

    // Media
    await db.into(db.media).insert(
          MediaCompanion.insert(
            filename: 'a.png',
            originalName: 'a.png',
            size: 100,
            mimeType: 'image/png',
            createdAt: now,
          ),
        );

    // Settings
    await db.into(db.settings).insert(
          SettingsCompanion.insert(key: 'theme', value: 'dark'),
        );

    expect(true, true); // 没抛异常即通过
  });
}
```

- [ ] **Step 2: 运行测试，确认失败/通过**

```bash
flutter test test/core/database/database_test.dart
```

预期：通过（因为 Task 5/6 已经把 schema 实现了）。如果失败，根据错误调整 schema。

输出应类似：

```
00:01 +2: All tests passed!
```

- [ ] **Step 3: 提交**

```bash
git add test/core/database/database_test.dart
git commit -m "test(db): verify schema with insertion tests"
```

---

## Task 8: 创建 Database Riverpod Provider

**Files:**
- Create: `lib/core/database/database_provider.dart`

- [ ] **Step 1: 创建 provider**

`lib/core/database/database_provider.dart`：

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
```

- [ ] **Step 2: 验证编译**

```bash
flutter analyze lib/core/database/database_provider.dart
```

预期：无错误。

- [ ] **Step 3: 提交**

```bash
git add lib/core/database/database_provider.dart
git commit -m "feat(db): expose AppDatabase via Riverpod provider"
```

---

## Task 9: 配置 Material 3 主题

**Files:**
- Create: `lib/core/theme/app_theme.dart`

- [ ] **Step 1: 创建主题**

`lib/core/theme/app_theme.dart`：

```dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData dark() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }
}
```

- [ ] **Step 2: 提交**

```bash
git add lib/core/theme/app_theme.dart
git commit -m "feat(theme): add Material 3 light/dark themes"
```

---

## Task 10: 配置 go_router 路由

**Files:**
- Create: `lib/features/home/presentation/pages/home_page.dart`
- Create: `lib/core/routing/app_router.dart`

M1 阶段只有一个 Hello World 首页，但路由结构先搭起来。

- [ ] **Step 1: 创建 Hello World 首页**

`lib/features/home/presentation/pages/home_page.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('anki_multi'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 64),
            const SizedBox(height: 16),
            Text(
              'Hello, anki_multi!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            FutureBuilder<int>(
              future: db.select(db.decks).get().then((r) => r.length),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Text('正在连接数据库...');
                }
                return Text('数据库已连接，当前牌组数: ${snapshot.data}');
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 创建 router**

`lib/core/routing/app_router.dart`：

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/pages/home_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
    ],
  );
});
```

- [ ] **Step 3: 提交**

```bash
git add lib/features/home lib/core/routing
git commit -m "feat: add Hello World home page and go_router skeleton"
```

---

## Task 11: 创建 App 与 main.dart 入口

**Files:**
- Create: `lib/app.dart`
- Create: `lib/main.dart`

- [ ] **Step 1: 创建 MyApp**

`lib/app.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'anki_multi',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

- [ ] **Step 2: 创建 main.dart**

`lib/main.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
```

- [ ] **Step 3: 验证编译**

```bash
flutter analyze
```

预期：无 error。可能有少量 info/warning 是模板代码遗留，先无视。

- [ ] **Step 4: 提交**

```bash
git add lib/app.dart lib/main.dart
git commit -m "feat: wire up MyApp with Riverpod scope and router"
```

---

## Task 12: Android 真机运行验证

**Files:** 无（仅运行）

- [ ] **Step 1: 确认设备连接**

```bash
flutter devices
```

预期：能看到你的 Android 手机。

- [ ] **Step 2: 在真机上运行 app**

```bash
flutter run -d <your-device-id>
```

或者直接：

```bash
flutter run
```

如果有多设备，选择 Android 设备。

预期：
- App 在手机上启动
- 显示标题 "anki_multi"
- 显示 "Hello, anki_multi!" 文字
- 显示 "数据库已连接，当前牌组数: 0"

- [ ] **Step 3: 截图保存为里程碑证据（可选但推荐）**

把首次运行截图保存到 `docs/screenshots/m1-hello-world.png`（手动从手机导出）。

- [ ] **Step 4: 如需要才提交截图**

```bash
git add docs/screenshots/
git commit -m "docs: add M1 hello world screenshot"
```

---

## Task 13: 跑全部测试 + lint 收尾

**Files:** 无

- [ ] **Step 1: 跑全部单元/集成测试**

```bash
flutter test
```

预期：所有测试通过。当前应该只有 `test/core/database/database_test.dart` 中的测试。

- [ ] **Step 2: lint 检查**

```bash
flutter analyze
```

预期：0 errors。warnings 可少量遗留（例如 widget tests 的废弃模板），但 errors 必须为 0。

- [ ] **Step 3: 删掉 Flutter create 自动生成但用不上的 widget 测试**

```bash
ls test/
```

如果有 `test/widget_test.dart`（flutter create 默认生成的，引用了原 main.dart 中的 MyApp），它会报错或失败。删掉它：

```bash
rm test/widget_test.dart
```

再跑一次：

```bash
flutter test
flutter analyze
```

预期：依然全部通过，0 errors。

- [ ] **Step 4: 提交（如果有删改）**

```bash
git add -A
git commit -m "chore: remove unused template widget test"
```

---

## Task 14: 写 M1 完成日志

**Files:**
- Create: `docs/devlog/2026-05-09-m1-complete.md`

- [ ] **Step 1: 创建 devlog 目录与日志**

```bash
mkdir -p docs/devlog
```

`docs/devlog/2026-05-09-m1-complete.md`：

```markdown
# M1 完成日志

**日期**：YYYY-MM-DD（填实际完成日期）

## 完成事项

- [x] Flutter 项目脚手架
- [x] 全部核心依赖配置
- [x] AGPL v3 LICENSE / README / lint 配置
- [x] feature-based 目录结构
- [x] 七张 drift 表 schema 定义 + 代码生成
- [x] 数据库集成测试通过
- [x] Riverpod + go_router + Material 3 主题
- [x] Hello World 首页能在 Android 真机运行并连通 DB

## 实际投入时间

约 X 小时（填实际数）

## 遇到的问题与解决

（写下你遇到的至少 1 个有意思的坑，比如版本冲突、签名问题等）

## 下一步：M2

牌组与卡片 CRUD（最简正反面）。预计 Week 3-4，10 小时投入。
```

- [ ] **Step 2: 提交**

```bash
git add docs/devlog/
git commit -m "docs: M1 completion devlog"
```

---

## 验收清单（M1 整体）

完成 M1 时，以下所有条目都必须通过：

- [ ] `flutter --version` 正常输出，工具链就绪
- [ ] `flutter pub get` 无错误
- [ ] `flutter analyze` 0 errors
- [ ] `flutter test` 全部通过（至少 2 个数据库测试）
- [ ] `flutter build apk --debug` 成功
- [ ] `flutter run` 能在 Android 真机启动应用
- [ ] App 显示 "Hello, anki_multi!" 与 "数据库已连接，当前牌组数: 0"
- [ ] git log 有 ~10+ 次提交，消息清晰
- [ ] LICENSE 文件存在且为 AGPL v3 全文
- [ ] devlog 写完

---

## Risks & Notes

- **drift 代码生成失败**：如 `dart run build_runner build` 报错，先 `dart run build_runner clean` 再重试。
- **Android 设备未识别**：检查 USB 调试是否打开、是否安装了对应厂商的 USB 驱动（Windows 上常见问题，macOS 几乎不会）。
- **第一次构建超慢**：5-10 分钟正常，后续增量构建会很快。
- **flutter create --overwrite 会覆盖 docs/ 吗？** 不会。`--overwrite` 只覆盖 Flutter 模板涉及的文件（lib/main.dart、test/widget_test.dart、平台目录等），docs 是安全的。但保险起见，运行前先 `git status` 确认无未提交改动。
