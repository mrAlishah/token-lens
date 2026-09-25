# Token Lens

<p align="center">
  <img src="docs/assets/codex_usage_agentic.webp"
       alt="Token Lens Codex usage example"
       width="50%" height="50%">
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

# Both providers: latest turn from each
token-lens usage --provider all --profile coding

# Both providers: explicit provider-specific IDs
token-lens usage --provider all \
  --codex-id T-3aa6eba0 \
  --claude-id T-1234abcd \
  --profile agentic
```

With `--provider all`, text output is rendered in separate `CODEX` and `CLAUDE` sections. `--json` returns a provider-keyed object.

The original provider-specific commands remain available:

```bash
codex-turns
codex-usage T-3aa6eba0

claude-turns
claude-usage T-1234abcd
```

## Profiles

- `simple`: focused edits/questions with limited tool use.
- `coding`: default software-engineering work with repository reads, tools, MCP/plugin/skill activity, tests, and several turns.
- `agentic`: longer autonomous workflows with more exploration, validation, subagents, and iteration.

The Codex `coding` profile keeps the existing token bands. Claude uses the same token bands but wider turn-count bands because one user request can produce several assistant/tool rounds.

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
