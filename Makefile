.PHONY: test format deps

test:
	@for f in tests/localreview/test_*.lua; do \
		nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedFile $$f"; \
	done

format:
	stylua lua/ tests/ plugin/

deps:
	@test -d .deps/plenary.nvim || git clone --depth 1 https://github.com/nvim-lua/plenary.nvim .deps/plenary.nvim
