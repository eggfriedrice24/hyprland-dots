# OpenCode

Configuration for OpenCode v2. `~/.config/opencode` is a symlink to this directory.

- `opencode.json` - permissions and MCP servers, native v2 shape
- `cli.json` - terminal client settings (theme, diffs, session view)
- `AGENTS.md` - global instructions, loaded first in every session
- `commands/remember.md` - `/remember` slash command, saves a memory on demand
- `plugins/project-memory.js` - persistent memory, see below
- `service.json` - background service password, written by OpenCode, gitignored

## Memory

OpenCode v2 has no built-in memory. `plugins/project-memory.js` adds one modelled on
Claude Code's auto memory. It is auto-loaded from `~/.config/opencode/plugins`.

Layout:

```text
~/.opencode/
|-- memory/                 shared, applies in every project
|   |-- MEMORY.md           index: one line per memory, never content
|   `-- user_*.md
`-- <project>/memory/       per project
    |-- MEMORY.md
    |-- feedback_*.md
    |-- project_*.md
    `-- reference_*.md
```

`<project>` is the project root directory name (the current directory for non-git
locations), lowercased and sanitized. For `~/p/rune` it is `~/.opencode/rune/memory/`.
The plugin creates the project directory on startup; MEMORY.md is created on first save.

Each memory is one file with one fact and frontmatter (`name`, `description`, `type`).
Types are `user`, `feedback`, `project`, `reference`. Feedback and project memories carry
**Why:** and **How to apply:** lines and can link each other with `[[name]]`.

On every model request the plugin injects one system part:

1. the memory protocol: format, when to save, keep the index in sync, update rather than duplicate
2. both MEMORY.md indexes, re-read each request so fresh saves show up immediately
3. up to 3 recalled memory files whose name or description overlaps the latest user prompt

Full memory files are never injected wholesale; the agent reads them on demand from the
index. `opencode.json` allows `edit` under `~/.opencode/**` so saves do not prompt.

`/remember <fact>` asks the agent to save a memory right away. Without an argument it
saves the most important thing from the current conversation.

Overrides:

- `OPENCODE_MEMORY_DIR` changes the memory root
- `OPENCODE_MEMORY_PROJECT` changes the project name for the current session
