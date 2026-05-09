# anki_multi 设计文档

- **代号**：anki_multi
- **日期**：2026-05-09
- **状态**：Draft（待用户复核）
- **作者**：项目所有者 + AI 协作

---

## 1. 背景与初心

最初考虑直接使用国内 anki相关产品，因核心功能收费而萌生自建念头。后又考虑做"更便宜的同质化竞品"。经过权衡——同质化竞争结构性劣势 + solo 开发者商业化运营负担过重——最终决定：

> **做一个 self-use first 的开源 Anki 类速记卡应用，开放源码（AGPL v3），不商业化。**

这种定位带来的明显好处：

- 真实用户（自己）= 持续动力
- 没有商业化压力 = 可以追求长期可维护性 / 优雅
- 中途若失去精力，至少 v0.1 可用，社区也可能接手

## 2. 目标与非目标

### 2.1 目标

- 提供一个跨平台（Android/iOS/macOS/Windows/Linux）的现代 UI 速记卡应用
- 使用业界最先进的 FSRS 算法做调度
- 数据格式开放，未来与 Anki .apkg 互转
- 代码以 AGPL v3 开源，阻止任何方拿去做闭源/商用 SaaS

### 2.2 非目标（v0.1）

- ❌ 商业化、付费功能、订阅
- ❌ 云同步与多设备协作（推迟到 v2.0）
- ❌ 直接兼容 Anki 同步协议
- ❌ AI 自动生成卡片、双链、画板、热力图（推迟到 v0.2+）
- ❌ 完整的 .apkg 导入/导出（推迟到 v0.2+）
- ❌ iOS/macOS/Windows/Linux 真机调试与发布（v0.1 仅 Android 调试）

## 3. 战略选择

### 3.1 路径 D：独立项目 + Anki 数据格式兼容（未来）

四条路径中选 D：

- ❌ A. 完全从零写自定义格式 —— 失去 Anki 生态太可惜
- ❌ B. Fork Anki 桌面版换 UI —— Rust + Python + Svelte 多技术栈对 solo 不友好
- ❌ C. 兼容 Anki 同步协议 —— 协议复杂，回报低
- ✅ **D. 独立设计 + 数据格式兼容（未来支持 .apkg 导入导出）** —— 自由设计 + 不切断 Anki 生态

### 3.2 Local-first，云同步推迟到 v2.0

- v0.x 完全本地：所有数据在 SQLite，多设备同步靠用户自己（iCloud / Dropbox / WebDAV）
- v1.0 开源发布，仍是 Local-first
- v2.0 视社区反馈再决定是否提供官方/可自托管的同步服务

### 3.3 Android-first 调试

代码层面 Flutter 全平台兼容，但 v0.1 仅在 Android 真机上调试与发布。其他平台代码能编译但暂不打磨。

## 4. 技术栈

| 角色 | 选型 | 理由 |
|---|---|---|
| UI 框架 | **Flutter** (Dart) | 一份代码全平台，AI 协助友好 |
| 状态管理 | **Riverpod** | 当前 Flutter 社区最佳实践 |
| 路由 | **go_router** | 官方推荐 |
| 本地数据库 | **drift**（基于 SQLite） | 类型安全、跨平台、迁移支持好 |
| 算法 | **fsrs** | FSRS 官方 Dart 移植（pub.dev 包名 `fsrs`） |
| Markdown | **flutter_markdown_plus** | flutter_markdown 已废弃，社区接手维护 |
| TTS | **flutter_tts** | 跨平台系统 TTS 桥接 |
| UI 设计 | **Material 3** | Flutter 默认，跨平台一致 |
| License | **AGPL v3** | 阻止任何 fork 做闭源/SaaS |

## 5. 架构

### 5.1 分层

```
┌─────────────────────────────────────────┐
│             Flutter App                   │
│                                           │
│  Presentation 层（页面 + 组件）            │
│  ─ Pages: Home / Decks / Review /        │
│    CardEdit / Stats / Settings           │
│                ↓ Riverpod                 │
│  Application 层（业务逻辑 / Service）      │
│  ─ DeckService                           │
│  ─ CardService                           │
│  ─ ReviewService（FSRS 调度）             │
│  ─ StatsService                          │
│  ─ TtsService                            │
│                ↓                          │
│  Domain 层（纯数据模型 + 规则）            │
│  ─ Card / Deck / Note / NoteType /       │
│    Review / FsrsState                    │
│                ↓                          │
│  Infrastructure 层                        │
│  ─ LocalDB (drift + SQLite)              │
│  ─ FileStorage (媒体文件)                │
│  ─ fsrs                                  │
│  ─ flutter_tts                           │
└─────────────────────────────────────────┘
```

### 5.2 项目目录结构（feature-based）

```
anki_multi/
├── lib/
│   ├── main.dart
│   ├── app.dart                    # MaterialApp + 路由
│   ├── core/                       # 全局基础设施
│   │   ├── database/               #   drift schema
│   │   ├── theme/                  #   主题
│   │   └── routing/                #   go_router
│   ├── features/
│   │   ├── decks/                  # 牌组
│   │   │   ├── domain/             #     纯模型
│   │   │   ├── data/               #     仓储 / DAO
│   │   │   ├── application/        #     Riverpod provider / service
│   │   │   └── presentation/       #     页面 + 组件
│   │   ├── cards/                  # 卡片 CRUD + Markdown + Cloze
│   │   ├── review/                 # 复习 + FSRS
│   │   ├── stats/                  # 统计
│   │   ├── tts/                    # TTS 朗读
│   │   └── settings/               # 设置
│   └── shared/                     # 跨 feature 共用组件
├── test/
├── docs/
│   └── superpowers/specs/
├── android/  ios/  linux/  macos/  windows/
├── pubspec.yaml
├── README.md
└── LICENSE                         # AGPL v3
```

### 5.3 关键数据流：复习一张卡

```
用户进入复习页
  ↓
ReviewService.getDueCards(deckId)
  → CardDao.queryDue(deckId, now)
  ↓
展示卡片正面 → 用户点击"显示答案"→ 展示反面
  ↓
用户点击 4 评分按钮（Again/Hard/Good/Easy）
  ↓
ReviewService.applyReview(card, rating)
  → fsrs.next(card.fsrsState, rating)
  → 更新 cards 表（新 due/stability/difficulty/...）
  → 写一条 reviews 日志（永不删）
  ↓
取下一张待复习卡片，无则返回完成页
```

## 6. 数据模型

延用 Anki 经典三层模型 `note → card → note_type`，未来 .apkg 兼容时无需大改。

### 6.1 Schema（v0.1）

```sql
-- 牌组
decks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  parent_id INTEGER NULL,                -- v0.1 始终为 NULL，留 v0.2 用
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

-- 笔记类型（v0.1 内置 Basic / Cloze 两种）
note_types (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  fields TEXT NOT NULL,                  -- JSON: ["正面", "反面"]
  templates TEXT NOT NULL,               -- JSON: 卡片模板定义
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

-- 笔记（一条数据可生成 1+ 张卡）
notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  note_type_id INTEGER NOT NULL REFERENCES note_types(id),
  fields TEXT NOT NULL,                  -- JSON: {"正面": "...", "反面": "..."}
  tags TEXT NOT NULL DEFAULT '',         -- 空格分隔
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

-- 卡片（FSRS 调度的实际单元）
cards (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  note_id INTEGER NOT NULL REFERENCES notes(id),
  deck_id INTEGER NOT NULL REFERENCES decks(id),
  template_idx INTEGER NOT NULL DEFAULT 0,

  -- FSRS 状态
  due INTEGER NOT NULL,                  -- Unix ms
  stability REAL NOT NULL DEFAULT 0,
  difficulty REAL NOT NULL DEFAULT 0,
  elapsed_days INTEGER NOT NULL DEFAULT 0,
  scheduled_days INTEGER NOT NULL DEFAULT 0,
  reps INTEGER NOT NULL DEFAULT 0,
  lapses INTEGER NOT NULL DEFAULT 0,
  state INTEGER NOT NULL DEFAULT 0,      -- 0=New 1=Learning 2=Review 3=Relearning
  last_review INTEGER NULL,

  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

-- 复习日志（只增不删，未来训练 FSRS 参数用）
reviews (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  card_id INTEGER NOT NULL REFERENCES cards(id),
  reviewed_at INTEGER NOT NULL,
  rating INTEGER NOT NULL,               -- 1=Again 2=Hard 3=Good 4=Easy
  state INTEGER NOT NULL,
  due INTEGER NOT NULL,
  stability REAL NOT NULL,
  difficulty REAL NOT NULL,
  elapsed_days INTEGER NOT NULL,
  last_elapsed_days INTEGER NOT NULL,
  scheduled_days INTEGER NOT NULL,
  duration_ms INTEGER NOT NULL DEFAULT 0
);

-- 媒体文件
media (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  filename TEXT NOT NULL UNIQUE,
  original_name TEXT NOT NULL,
  size INTEGER NOT NULL,
  mime_type TEXT NOT NULL,
  created_at INTEGER NOT NULL
);

-- 用户设置 + FSRS 参数
settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
```

### 6.2 设计要点

- **note 与 card 分离**：一条 note 可由 note_type 的多个 template 生成多张 card（例如正→反 + 反→正）。
- **fields 用 JSON 存**：不同 note_type 字段不同，JSON 比拆十几张表灵活。
- **reviews 永不删除**：FSRS 参数训练依赖完整日志。
- **parent_id 字段提前留位**：v0.1 不用，v0.2 加层级牌组无需迁移。
- **media 与 notes 解耦**：media 文件名以哈希命名，notes 中通过 markdown 引用。

### 6.3 内置 note_types（v0.1 在 app 启动时 seed）

#### Basic
```json
{
  "name": "Basic",
  "fields": ["正面", "反面"],
  "templates": [
    { "name": "正→反", "qfmt": "{{正面}}", "afmt": "{{正面}}<hr>{{反面}}" }
  ]
}
```

#### Cloze
```json
{
  "name": "Cloze",
  "fields": ["内容"],
  "templates": [
    { "name": "Cloze", "qfmt": "{{cloze:内容}}", "afmt": "{{cloze:内容}}" }
  ]
}
```

## 7. v0.1 功能范围

### 7.1 核心功能（11 项）

1. **创建/编辑/删除卡片**（Basic 类型，正面/反面）
2. **创建/编辑/删除牌组**（v0.1 扁平结构）
3. **FSRS 复习引擎**（4 按钮：Again / Hard / Good / Easy）
4. **本地 SQLite 存储**（drift ORM）
5. **基础统计**（今日待复习/已复习/卡片总数）
6. **Markdown 渲染**（卡片正反面支持 MD 语法）
7. **图片附件**（卡片中插入图片）
8. **挖空（Cloze）**（`{{c1::答案}}` 语法）
9. **TTS 朗读**（系统原生 TTS，多语种）
10. **设置页**（FSRS 参数、TTS 偏好、深色模式）
11. **JSON 数据备份/恢复**（用户数据可导出可还原，开源项目的"数据自由"基本要求）

> 注：第 11 项是 spec 撰写时新增的，brainstorming 阶段未明确讨论。理由：缺少备份机制对一个会承载用户长期学习数据的应用是不可接受的。如不同意，可在 spec 复核时移除。

### 7.2 不在 v0.1 范围

- ❌ 层级牌组、双链、画板、热力图
- ❌ AI 卡片生成
- ❌ .apkg 导入/导出（推迟）
- ❌ 云同步
- ❌ 标签搜索/过滤（基础 tags 字段保留，UI 推迟）
- ❌ 自定义 note_types 编辑器（仅内置 Basic/Cloze）

## 8. 路线图

总周期：**4-6 个月到 v0.1**（每周 ~5 小时投入，AI 协助下）。

10 个里程碑，每个 = 2 周 = ~10 小时实际工作：

| 里程碑 | 周次 | 交付物 | 验收 |
|---|---|---|---|
| **M1** | 1-2 | 项目脚手架 + drift schema + Hello World 跑在 Android 真机 | 能 build apk |
| **M2** | 3-4 | 牌组 CRUD + 卡片 CRUD（最简正反面） | 能创建几张卡 |
| **M3** | 5-6 | FSRS 复习引擎接入，4 按钮工作 | 能完整复习一遍 ⭐ 自用起点 |
| **M4** | 7-8 | Markdown 渲染 + 图片附件 | 卡片支持图文 |
| **M5** | 9-10 | Cloze 挖空 | 挖空卡片可复习 |
| **M6** | 11-12 | TTS 朗读 | 卡片字段可朗读 |
| **M7** | 13-14 | 统计页（今日/总数 + 简单图表） | 能看到学习进度 |
| **M8** | 15-16 | 设置页 + UI 整体打磨 | 主题/参数可调 |
| **M9** | 17-18 | JSON 备份导入/导出 + 真机回归测试 | 数据可备份 |
| **M10** | 19-20 | v0.1 发布到 GitHub Release + README | 公开可用 |

**关键节点**：M3 完成（第 6 周）= 已可自用，是项目最重要的心理节点。

## 9. 测试策略

solo + 5h/周 限制下，原则：**核心逻辑必测，UI 可不测**。

| 层 | 测哪些 | 工具 | 优先级 |
|---|---|---|---|
| Domain | 模型不变量、Cloze 解析、Markdown 转换 | Dart `test` | 必须 |
| Application | FSRS 调度、复习流程编排 | `mocktail` | 必须 |
| Infrastructure | DAO 集成测试 | drift 内存 SQLite | 推荐 |
| Presentation | Widget 测试 | flutter_test | v0.1 不做 |

**最重要的测试**：FSRS 调度（`ReviewService.applyReview`）。这是核心，改坏会污染用户数据。

## 10. 错误处理

- **数据库异常**：UI 层 catch，弹 SnackBar 提示，写入本地日志文件
- **FSRS 异常输入**：service 层校验，无效 rating 抛 `ArgumentError`
- **TTS 不可用**：feature 降级，不阻塞复习
- **媒体文件丢失**：卡片渲染时显示 placeholder

## 11. 风险与缓解

| 风险 | 概率 | 影响 | 缓解 |
|---|---|---|---|
| solo + 5h/周 → 中途失去动力 | **高** | 高 | 公开 GitHub 仓库 + 每 2 周里程碑 + M3 后立即开始自用 |
| Flutter 学习曲线 | 中 | 中 | AI 重度协助，先小项目练手 |
| Android 厂商兼容（小米/华为/OPPO） | 中 | 中 | v0.1 限定到主要机型，问题排队修 |
| FSRS 算法误用 → 用户数据污染 | 低 | 高 | 全面单测覆盖 ReviewService |
| AGPL 限制贡献者 | 低 | 低 | 接受这个权衡 |
| 与 Anki 数据格式兼容比预期复杂 | 中 | 中 | v0.1 不做 .apkg 兼容，先写 JSON 备份 |

## 12. 开放问题（待解决）

- v0.1 上线后是否要正式起一个项目名（替换代号 anki_multi）？
- v0.2 优先做哪些功能？（TBD，根据自用反馈决定）
- README/贡献指南先用中文还是双语？

## 13. 参考资料

- Anki 官方源码：https://github.com/ankitects/anki
- AnkiDroid 源码：https://github.com/ankidroid/Anki-Android
- FSRS 算法：https://github.com/open-spaced-repetition
- fsrs (Dart 移植)：https://pub.dev/packages/fsrs · 源码 https://github.com/open-spaced-repetition/dart-fsrs
- drift 文档：https://drift.simonbinder.eu/
- Riverpod：https://riverpod.dev/
- AGPL v3 全文：https://www.gnu.org/licenses/agpl-3.0.html

---

## 附录 A：决策记录

记录 brainstorming 阶段做出的关键决策与放弃的备选方案，便于未来追溯。

| 决策 | 选择 | 备选 | 理由 |
|---|---|---|---|
| 商业模式 | Self-use + 开源 | 商业化 / 收费版 | 同质化竞争结构性劣势 + solo 商业化压力 |
| 路径 | D（独立 + Anki 数据兼容） | A 全自定义 / B Fork / C 协议兼容 | 性价比最高 |
| 同步策略 | Local-first，v2.0 再加云同步 | 一开始就上云 | 省 50% 早期工作量 |
| 平台 | Flutter，仅 Android 调试 | RN+Tauri / Tauri only / Web first | solo 友好 |
| License | AGPL v3 | MIT/GPL | 阻止闭源/SaaS 化 |
| 数据模型 | Anki 经典 note/card/note_type | 简化为 cards 单表 | 未来 .apkg 兼容 |
| 项目结构 | feature-based | 严格分层 | 模块边界清晰 |
| 测试 | Domain/Application 必测，UI v0.1 不测 | 全测 / 不测 | solo 时间预算 |
