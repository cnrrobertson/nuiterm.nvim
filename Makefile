docs: deps
	nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniDoc.generate({'lua/nuiterm.lua', 'lua/nuiterm/config.lua', 'lua/nuiterm/terminal.lua'})" -c "quit"

test: deps
	nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run()" -c "quit"

test_file: deps
	nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run_file('$(FILE)')" -c "quit"

deps: deps/mini.nvim deps/nui.nvim

deps/mini.nvim:
	@mkdir -p deps
	git clone --filter=blob:none https://github.com/echasnovski/mini.nvim $@

deps/nui.nvim:
	@mkdir -p deps
	git clone --filter=blob:none https://github.com/MunifTanjim/nui.nvim $@
