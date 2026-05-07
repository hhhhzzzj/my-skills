# my-claude-skills

我的个人精选 Claude Code / Windsurf skill 包。一行命令跨机器安装，方便在新设备上快速复刻自己的工作流。

## 收录的 skill

| Skill                   | 干什么                                                                                                                                                 | 触发示例                                    |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------- |
| **codebase-onboarding** | 给一个仓库写 onboarding 文档（按读者身份调整深浅）                                                                                                     | "给这个仓库写一份 onboarding"               |
| **code-tour**           | 写 VS Code [CodeTour 扩展](https://marketplace.visualstudio.com/items?itemName=vsls-contrib.codetour) 用的 `.tour` 文件——按 persona 步进式 walkthrough | "给这个项目写一个 architect tour"           |
| **senior-backend**      | 装一个资深后端工程师 review 项目，指出生产可用性 / smell / 改进建议                                                                                    | "用资深 Java 后端的视角 review 这个项目"    |
| **tech-debt-tracker**   | 扫描代码库的技术债、打分排序、生成清理计划                                                                                                             | "评估这个项目的技术债优先级"                |
| **tutorial-writer**     | 写 PocketFlow 风格的多章节教程——比喻开头、叙事性强、每章 800-2000 字                                                                                   | "把这仓库当一本书写"、"PocketFlow 风格教程" |

前 4 个来自 [alirezarezvani/claude-skills](https://github.com/alirezarezvani/claude-skills)（MIT，详见 `ATTRIBUTION.md`）。`tutorial-writer` 是我自己写的，灵感来自 [PocketFlow tutorial-codebase-knowledge](https://github.com/The-Pocket/PocketFlow-Tutorial-Codebase-Knowledge)。

## 安装

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/hhhhzzzj/my-skills/main/install.ps1 | iex
```

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/hhhhzzzj/my-skills/main/install.sh | sh
```

脚本会：

1. 把仓库 clone 到 `%LOCALAPPDATA%\my-claude-skills`（Windows）或 `~/.local/share/my-claude-skills`（\*nix）
2. 为 `skills/` 下每个目录在 `~/.claude/skills/` 下建 Junction（Windows）或 symlink（\*nix），供 Claude Code 使用
3. 把 `skills/` 下每个目录复制到 `~/.codeium/windsurf/skills/`，供 Windsurf Cascade 使用
4. 重启 Claude Code / Windsurf 后生效

> Windsurf 理论上能通过 `Read Claude Code Config` 读取 `~/.claude/skills/`，但 Windows 下 Junction 支持不稳定。本仓库对 Windsurf 使用真实目录复制，更稳。

### 重新跑一次会怎样（幂等）

`install` 既是首次安装命令，也是更新命令。重跑时按 skill 状态分别处理。

Claude Code：

| `~/.claude/skills/<name>/` 当前状态      | 行为                                              | 输出标记   |
| ---------------------------------------- | ------------------------------------------------- | ---------- |
| 不存在                                   | 创建 Junction/symlink 指向仓库                    | `+ <name>` |
| 已是指向 my-claude-skills 的链接         | **跳过**（git pull 已经更新内容了，链接无需重建） | `= <name>` |
| 是别的目录或指向别处的链接               | **不动**，警告（保护你手动放的其他来源 skill）    | `! <name>` |
| 我们之前装的，但仓库里已经删掉这个 skill | 自动 unlink（清理 stale）                         | `- <name>` |

Windsurf：

| `~/.codeium/windsurf/skills/<name>/` 当前状态 | 行为                                           | 输出标记   |
| --------------------------------------------- | ---------------------------------------------- | ---------- |
| 不存在                                        | 复制真实目录，并写入 `.my-claude-skills-managed` 标记 | `+ <name>` |
| 是 my-claude-skills 管理的复制目录            | 删除旧副本并复制最新版                         | `= <name>` |
| 是别的目录或链接                              | **不动**，警告（保护你手动放的其他来源 skill） | `! <name>` |
| 我们之前装的，但仓库里已经删掉这个 skill      | 自动删除该托管副本                             | `- <name>` |

要把"被跳过"的某个 skill 替换成 my-claude-skills 的版本，先手动删除对应目录再重跑 install 就行。

## 更新

```powershell
# Windows
irm https://raw.githubusercontent.com/hhhhzzzj/my-skills/main/install.ps1 | iex
```

```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/hhhhzzzj/my-skills/main/install.sh | sh
```

跟首次安装是同一条命令——脚本检测到已存在就 `git pull`。

## 卸载

```powershell
# Windows
& "$env:LOCALAPPDATA\my-claude-skills\uninstall.ps1"
```

```bash
# macOS / Linux
~/.local/share/my-claude-skills/uninstall.sh
```

## 想加新 skill？

1. 把 skill 目录放到 `skills/<name>/`，至少含 `SKILL.md`
2. `git push`
3. 重新跑 install 命令——新 skill 会自动同步到 Claude Code 和 Windsurf

也欢迎 fork 这个仓库做成你自己的精选包。

## 设计原则

- **轻量**：每个 skill 单一职责，不搞编排
- **去 HARD-GATE**：相信 LLM 能按描述工作，任务定义清晰比强制约束更有用
- **跨机一致**：跟着 git 走，不依赖本机临时配置

## License

MIT — 详见 `LICENSE`。
