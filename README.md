# Token Lens

Token Lens is a small CLI toolkit for inspecting Codex token usage at turn/task level.

Current commands:

- `codex-turns` - list recent unique Codex turn IDs, their root turn and session ID.
- `codex-usage` - inspect token usage and health for a selected turn/root task.

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

After installing, an old shell-defined `codex-turns()` helper can be removed from `~/.zshrc`; `codex-turns` is a normal executable owned by this repository.

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

The default health profile is `coding`, so no profile switch or config file is required:

```bash
codex-usage T-3aa6eba0
```

Choose another built-in profile when the workload differs:

```bash
codex-usage T-3aa6eba0 --profile simple
codex-usage T-3aa6eba0 --profile agentic
```

The built-in profiles are:

- `simple` - small, focused edits or questions with limited repository/tool interaction.
- `coding` - the default for normal software-engineering work with repository reads, tools, MCP/plugin/skill activity, tests, and several turns.
- `agentic` - longer autonomous workflows with more exploration, tool calls, validation, and iterative turns.

`codex-usage` resolves the selected turn to its root task and reports task-level totals. The cache ratio shown in the health table is also task-level, so metrics in the same table use the same task scope.

## Built-in coding criteria

The default `coding` profile is intentionally more tolerant than a simple chat/task profile:

| Metric | GREAT | GOOD | WATCH | BAD | Weight |
| --- | ---: | ---: | ---: | ---: | ---: |
| Effective used tokens | < 8K | 8K-<20K | 20K-<50K | >= 50K | 30% |
| Uncached input tokens | < 6K | 6K-<15K | 15K-<35K | >= 35K | 25% |
| Cache ratio | >= 80% | 60-<80% | 35-<60% | < 35% | 20% |
| Input tokens | < 50K | 50K-<150K | 150K-<300K | >= 300K | 10% |
| Reasoning output tokens | < 1K | 1K-<4K | 4K-<12K | >= 12K | 10% |
| Turns | <= 3 | 4-8 | 9-15 | >= 16 | 5% |

These values are built directly into `bin/codex-usage`. They remain available even when no config file exists.

## Configure the criteria

An optional config file is read automatically from:

```text
~/.config/token-lens/config.json
```

The file is not required. When absent, Token Lens uses its hardcoded defaults.

A complete example is available at:

```text
config/example_config.json
```

For example, to change only the coding profile's Effective and Uncached thresholds:

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
        },
        "uncached_input_tokens": {
          "great_lt": 7000,
          "good_lt": 18000,
          "watch_lt": 40000
        }
      }
    }
  }
}
```

Only supplied values override the built-in profile; omitted values keep their hardcoded defaults.

Use an explicit file:

```bash
codex-usage T-3aa6eba0 --config /path/to/config.json
```

Ignore any config file for one invocation:

```bash
codex-usage T-3aa6eba0 --no-config
```

An explicit `--profile` selects the profile even when the config has a different `default_profile`.

## How the overall rating works

The metrics do not have equal diagnostic value. Token Lens therefore uses a weighted score instead of making the overall result equal to the single worst metric.

The default weight distribution is:

```text
Effective   30%
Uncached    25%
Cache       20%
Input       10%
Reasoning   10%
Turns        5%
```

This is intentional. In coding workflows, high raw `input_tokens` can be normal when a large repository/context prefix is heavily cached. For example, a task with high input, a high cache ratio, and low uncached input can be healthier than a much smaller task that repeatedly sends fresh context.

Likewise, multiple turns are not inherently inefficient. Repository inspection, tool calls, editing, testing, fixing failures, and verification naturally create several turns in agentic coding. Turn count is therefore a weak signal by itself.

The overall weighted score uses the per-metric ratings `GREAT=0`, `GOOD=1`, `WATCH=2`, and `BAD=3`. Strong waste signals also have guardrails so a favorable weighted average cannot completely hide them. In particular, BAD uncached input together with a BAD cache ratio forces an overall BAD result.

Weights can be overridden in the same config profile:

```json
{
  "profiles": {
    "coding": {
      "weights": {
        "effective_used_tokens": 30,
        "uncached_input_tokens": 25,
        "cache_ratio_percent": 20,
        "input_tokens": 10,
        "reasoning_output_tokens": 10,
        "turns": 5
      }
    }
  }
}
```

## Important: these ratings are heuristics

The health labels are not a universal or 100% accurate measure of coding quality, efficiency, or cost. Token usage varies materially with model, context-window behavior, cache implementation, repository size, task complexity, tool/MCP/plugin/skill use, test output, generated code, and the amount of exploration required.

Do not interpret one threshold crossing as proof of a token leak. A genuine leak or regression is better identified from repeated patterns, such as:

- uncached input growing unexpectedly across comparable turns;
- cache ratio dropping while the stable context is expected to remain reusable;
- effective usage increasing materially for similar tasks;
- repeated context/tool output being reintroduced without useful work;
- a session diverging significantly from its own historical baseline.

For serious optimization, compare similar workloads against your own historical baseline. The built-in presets are starting points for practical coding observability, not contractual limits.

Future token-leak detection should combine these task-level signals with longitudinal/anomaly analysis rather than relying on a single global threshold.

## Terminal rendering

The Criteria block uses a fixed-width text table instead of placing emoji in every criteria cell. Emoji display width varies across terminals and fonts and can otherwise cause column drift.
