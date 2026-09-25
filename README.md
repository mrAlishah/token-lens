# Token Lens

<p align="center">
  <img src="docs/assets/codex_usage_agentic.webp"
       alt="Token Lens Codex usage example">
</p>

Token Lens is a local CLI toolkit for inspecting token usage from **Codex** and **Claude Code** at turn/session level.

> **Hint:** Ratings are heuristics, not exact or universal; model, repository, caching, tools/MCP/skills/plugins, and task complexity can change normal usage.
> Compare similar workloads and your own history before treating a rating as inefficiency or a token leak.

## Requirements

- Bash
- `jq` (`brew install jq`)
- `ripgrep` / `rg` for usage reports (`brew install ripgrep`)

Local data sources:

- Codex: `~/.codex/sessions` (override with `CODEX_SESSIONS_DIR`)
- Claude Code: `~/.claude/projects` (override with `CLAUDE_PROJECTS_DIR`)

## Install

```bash
make install
export PATH="$HOME/.local/bin:$PATH"
```

Installs `token-lens`, `codex-turns`, `codex-usage`, `claude-turns`, and `claude-usage` into `~/.local/bin`.

## Multi-provider usage

`token-lens` is the provider selector. The default provider is `all`.

```bash
# Recent turns, separated by provider
token-lens turns
token-lens turns --provider all 10
token-lens turns --provider codex 10
token-lens turns --provider claude 10

# One provider
token-lens usage --provider codex T-3aa6eba0
token-lens usage --provider claude T-1234abcd
token-lens usage --provider claude <session-id>

# Numeric record selector: 1 = newest, 2 = second newest, ...
codex-usage 1
codex-usage 3
claude-usage 1
claude-usage 3

# Both providers: latest turn from each
token-lens usage --provider all --profile coding

# Both providers: explicit provider-specific IDs
token-lens usage --provider all \
  --codex-id T-3aa6eba0 \
  --claude-id T-1234abcd \
  --profile agentic
```

With `--provider all`, text output is rendered in separate `CODEX` and `CLAUDE` sections. `--json` returns a provider-keyed object.

Both turn lists use the same columns:

```text
TIME  SHORT-ID  ROOT-ID  SESSION-ID  TURN-ID  MODEL  SOURCE
```

`SOURCE` is the project/repository working directory recorded by the provider when available. For Codex, `ROOT-ID` is the short root turn when it differs from the selected turn; when the turn is its own root it shows `S-xxxxxxxx`, the short session ID, instead of repeating `SHORT-ID`. Claude has no equivalent root-turn field in these transcripts, so it also uses `S-xxxxxxxx` in `ROOT-ID`.


The original provider-specific commands remain available. Usage commands also accept a positive record number using the same newest-first ordering as the matching `*-turns` command:

```bash
codex-turns
codex-usage 1          # newest Codex turn
codex-usage 3          # third newest Codex turn
codex-usage T-3aa6eba0

claude-turns
claude-usage 1         # newest Claude turn
claude-usage 3         # third newest Claude turn
claude-usage T-1234abcd
```

If the requested rank is larger than the available turn count, the command exits with a clear `record #N does not exist` error.

## Profiles

- `simple`: focused edits/questions with limited tool use.
- `coding`: default software-engineering work with repository reads, tools, MCP/plugin/skill activity, tests, and several turns.
- `agentic`: longer autonomous workflows with more exploration, validation, subagents, and iteration.

The Codex `coding` profile keeps the existing token bands. Claude uses the same token bands but wider turn-count bands because one user request can produce several assistant/tool rounds.

## Health scoring

Each usage report has two layers:

- **Raw metrics / legacy criteria** keep the existing fields, thresholds, and legacy rating for compatibility.
- **Efficiency Health (recommended)** appears underneath and is the preferred health signal. It evaluates cost load per turn, cache reuse, peak single-turn context pressure, and loop behavior. Raw cumulative task/session size alone does not force a `BAD` result.

Token counts use thousands separators for readability.

Recommended cost-equivalent baselines are heuristics:

```text
Codex  = uncached input * 1.0 + cached input * 0.10 + output * 8.0
Claude = base input * 1.0 + cache write * 2.0 + cache read * 0.10 + output * 5.0
```

Claude transcripts do not expose cache-write TTL, so `2.0x` is a conservative cache-write baseline. Claude also has no separate Codex-style reasoning-output field, so Token Lens does not invent one.

Cache efficiency is `N/A` until the sample is useful (default: at least 3 turns and 20,000 input tokens). Context pressure uses the largest single-turn input rather than cumulative input. Default context-window baselines are 400,000 tokens for Codex and 200,000 for Claude; these are configurable heuristics, not automatic model detection.

A recommended `BAD` is reserved for stronger pressure/waste evidence, such as very high context pressure or poor cache reuse combined with high cost load.

## Provider accounting

### Codex

Codex reports task-level totals derived from its `token_usage_record` records, including input, cached input, output, reasoning output, and root-turn relationships.

### Claude Code

Claude Code usage is read from assistant transcript records and deduplicated by `message.id` so repeated/streamed records are not counted twice.

Token Lens interprets Claude fields as:

```text
uncached_input = input_tokens + cache_creation_input_tokens
total_input    = uncached_input + cache_read_input_tokens
effective      = uncached_input + output_tokens
cache_ratio    = cache_read_input_tokens / total_input
```

Main-session and subagent records are reported separately and included in session totals when they share the selected `sessionId`.

Claude transcript usage does not expose a Codex-equivalent `reasoning_output_tokens` field, so that metric is not invented or scored for Claude.

## Optional config

Token Lens automatically reads `~/.config/token-lens/config.json` when present. Missing values keep the hardcoded defaults.

See `config/example_config.json`. Provider-specific Claude overrides can live under `providers.claude.profiles`; otherwise Claude falls back to the common profile values.

```bash
codex-usage T-3aa6eba0 --config /path/to/config.json
claude-usage T-1234abcd --config /path/to/config.json
token-lens usage --provider all --no-config
```
