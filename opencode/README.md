# OpenCode

## Global Project Memory

`plugins/project-memory.js` is auto-loaded by OpenCode from the global config directory at `~/.config/opencode/plugins`.

For every OpenCode session, it appends these instruction globs:

- `~/.opencode/memory/*.md` for memories shared across all projects
- `~/.opencode/<project-name>/memory/*.md` for memories specific to the current project

`<project-name>` is derived from OpenCode's project name or the current worktree directory name, lowercased and sanitized for filesystem use. For `~/p/rune`, the project memory path is `~/.opencode/rune/memory/*.md`.

Overrides:

- `OPENCODE_MEMORY_DIR` changes the memory root
- `OPENCODE_MEMORY_PROJECT` changes the project name for the current session

Example layout:

```text
~/.opencode/
|-- memory/
|   `-- preferences.md
`-- rune/
    `-- memory/
        |-- MEMORY.md
        `-- project_rune_overview.md
```
