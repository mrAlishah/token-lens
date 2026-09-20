PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin

.PHONY: install uninstall check

install:
	mkdir -p "$(BINDIR)"
	install -m 0755 bin/codex-usage "$(BINDIR)/codex-usage"
	install -m 0755 bin/codex-turns "$(BINDIR)/codex-turns"

uninstall:
	rm -f "$(BINDIR)/codex-usage" "$(BINDIR)/codex-turns"

check:
	bash -n bin/codex-usage
	bash -n bin/codex-turns
