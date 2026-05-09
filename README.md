# anki_multi

一个开源、跨平台、Local-first 的速记卡应用，使用 FSRS 算法做调度。

> **状态**：早期开发中（M1 项目脚手架阶段）

## 特点（v0.1 目标）

- 🌐 跨平台：Android / iOS / macOS / Windows / Linux（v0.1 仅 Android 真机调试）
- 🧠 FSRS 算法（业界最先进的间隔重复调度）
- 📝 Markdown 卡片 + 图片附件 + 挖空（Cloze）
- 🔊 多语言 TTS
- 💾 Local-first：数据全在本地 SQLite，不强制云同步
- 📤 JSON 备份/恢复

## 路线图

详见 [`docs/superpowers/specs/2026-05-09-anki_multi-design.md`](docs/superpowers/specs/2026-05-09-anki_multi-design.md)。

10 个里程碑，约 4-6 个月到 v0.1：

| 里程碑 | 周次 | 交付物 |
|---|---|---|
| M1 | 1-2 | 项目脚手架（你当前看到的） |
| M2 | 3-4 | 牌组与卡片 CRUD |
| M3 | 5-6 | FSRS 复习引擎接入 ⭐ 自用起点 |
| M4 | 7-8 | Markdown + 图片附件 |
| M5 | 9-10 | 挖空（Cloze） |
| M6 | 11-12 | TTS 朗读 |
| M7 | 13-14 | 统计页 |
| M8 | 15-16 | 设置页 + UI 打磨 |
| M9 | 17-18 | JSON 数据备份 |
| M10 | 19-20 | v0.1 GitHub Release |

## 技术栈

- **UI**：Flutter (Dart) + Material 3
- **状态管理**：Riverpod
- **路由**：go_router
- **数据库**：drift（基于 SQLite）
- **算法**：[`fsrs`](https://pub.dev/packages/fsrs)
- **Markdown**：flutter_markdown_plus
- **TTS**：flutter_tts

## 开发

```bash
# 安装依赖
flutter pub get

# 在连接的 Android 设备上运行
flutter run

# 跑测试
flutter test

# 静态检查
flutter analyze
```

## License

[AGPL v3.0](LICENSE)。

> 选 AGPL 是有意为之：希望阻止任何方 fork 后做闭源/SaaS 化。如果你想基于此做商用衍生品，请遵循 AGPL 协议（即开源你的修改）。
