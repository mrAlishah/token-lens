# Token Lens

Token Lens is a small CLI toolkit for inspecting Codex token usage at turn/task level.

Current commands:

- `codex-turns` — list recent unique Codex turn IDs, their root turn and session ID.
- `codex-usage` — inspect token usage and health for a selected turn/root task.

## Requirements

- Bash
- `jq`
- `ripgrep` (`rg`) for `codex-usage`

By default, both commands read Codex session JSONL files from:

```text
~/.codex/sessions
```

Override it for testing or custom layouts with `CODEX_SESSIONS_DIR`.

## Install

```bash
make install
```

This installs both executables into `~/.local/bin` by default. Make sure that directory is on your `PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

After installing, the old `codex-turns()` function can be removed from `~/.zshrc`; `codex-turns` is now a normal executable owned by this repository.

## Usage

List recent turns:

```bash
codex-turns
codex-turns 20
codex-turns --limit 20
codex-turns --json
```

Inspect a turn:

```bash
codex-usage T-3aa6eba0
codex-usage <full-turn-id>
codex-usage T-3aa6eba0 --json
```

`codex-usage` resolves the selected turn to its root task and reports task-level totals. The cache ratio shown in the health table is also task-level, so metrics in the same table no longer mix selected-turn and whole-task scopes.

## Health criteria

The criteria block intentionally uses an ASCII fixed-width table instead of placing emoji in every cell. Emoji display width varies by terminal/font and caused the previous criteria view to drift out of alignment.

The rating bands currently target simple/efficient tasks and are heuristics, not universal limits.
