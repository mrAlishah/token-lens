# Token Lens

![Token Lens Codex usage example](docs/assets/codex_usage_agentic.webp)

Token Lens is a CLI toolkit for inspecting Codex token usage at turn/task level.

- `codex-turns` lists recent unique Codex turns with root/session IDs.
- `codex-usage` reports task-level token health for a selected turn.

> **Hint:** Ratings are heuristics, not exact or universal; model, repository, caching, tools/MCP/skills/plugins, and task complexity can change normal usage.
> Compare similar workloads and your own history before treating a rating as inefficiency or a token leak.

## Requirements

- Bash
- `jq` (`brew install jq`)
- `ripgrep` / `rg` for `codex-usage` (`brew install ripgrep`)

Codex session data is read from `~/.codex/sessions`. Override it with `CODEX_SESSIONS_DIR`.

## Install

```bash
make install
export PATH="$HOME/.local/bin:$PATH"
```

This installs `codex-turns` and `codex-usage` into `~/.local/bin`.

## Usage

```bash
codex-turns
codex-turns 20
codex-turns --json

codex-usage T-3aa6eba0
codex-usage T-3aa6eba0 --profile agentic
codex-usage T-3aa6eba0 --json
```

The default profile is `coding`; no config file or profile switch is required.

### Profiles

- `simple`: focused edits/questions with limited tool use.
- `coding`: default software-engineering work with repository reads, tools, MCP/plugin/skill activity, tests, and several turns.
- `agentic`: longer autonomous workflows with more exploration, validation, and iteration.

## Default coding criteria

| Metric | GREAT | GOOD | WATCH | BAD | Weight |
| --- | ---: | ---: | ---: | ---: | ---: |
| Effective | < 8K | 8K-<20K | 20K-<50K | >= 50K | 30% |
| Uncached | < 6K | 6K-<15K | 15K-<35K | >= 35K | 25% |
| Cache | >= 80% | 60-<80% | 35-<60% | < 35% | 20% |
| Input | < 50K | 50K-<150K | 150K-<300K | >= 300K | 10% |
| Reasoning | < 1K | 1K-<4K | 4K-<12K | >= 12K | 10% |
| Turns | <= 3 | 4-8 | 9-15 | >= 16 | 5% |

The defaults are hardcoded in `bin/codex-usage`. Effective, uncached input, and cache ratio intentionally have more influence than raw input or turn count. High input can still be healthy when most context is cached, and multiple turns are normal in tool-driven coding.

The overall rating is weighted rather than equal to the single worst metric. A strong waste signal such as BAD uncached input together with a BAD cache ratio still forces an overall BAD result.

## Optional config

Token Lens automatically reads `~/.config/token-lens/config.json` when present. Missing values keep the built-in defaults.

See `config/example_config.json` for the full shape.

```json
{
  "default_profile": "coding",
  "profiles": {
    "coding": {
      "criteria": {
        "effective_used_tokens": {
          "great_lt": 10000,
          "good_lt": 25000,
          "watch_lt": 60000
        }
      }
    }
  }
}
```

Use another file or ignore config for one run:

```bash
codex-usage T-3aa6eba0 --config /path/to/config.json
codex-usage T-3aa6eba0 --no-config
```
