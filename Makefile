PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin

.PHONY: install uninstall check

install:
	mkdir -p "$(BINDIR)"
	install -m 0755 bin/token-lens "$(BINDIR)/token-lens"
	install -m 0755 bin/codex-usage "$(BINDIR)/codex-usage"
	install -m 0755 bin/codex-turns "$(BINDIR)/codex-turns"
	install -m 0755 bin/claude-usage "$(BINDIR)/claude-usage"
	install -m 0755 bin/claude-turns "$(BINDIR)/claude-turns"

uninstall:
	rm -f "$(BINDIR)/token-lens" "$(BINDIR)/codex-usage" "$(BINDIR)/codex-turns" "$(BINDIR)/claude-usage" "$(BINDIR)/claude-turns"

check:
	bash -n bin/token-lens
	bash -n bin/codex-usage
	bash -n bin/codex-turns
	bash -n bin/claude-usage
	bash -n bin/claude-turns
