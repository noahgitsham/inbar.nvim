local M = {}

--vim.keymap.set("", "<C-x>", function () vim.print(vim.fn.winlayout()) end)

local config = require("inbar.config")

M.setup = function(opts)
	config.setup(opts)

	local window = require("inbar.window")
	window.createAutocommands()
	window.createMissingBars()
end

local currWin = vim.api.nvim_get_current_win()
local scratch = vim.api.nvim_create_buf(false, true)
local path = vim.fn.expand("%")
--local filename = vim.fn.expand("%:t")
local paddingCount = 1
local padding = string.rep(" ", paddingCount)

local bufText = padding .. path .. padding

vim.api.nvim_buf_set_lines(scratch, 0, -1, false, {bufText})

return M
