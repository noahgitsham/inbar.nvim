local M = {}

M.defaults = {
	border = {"┬", "─", "┤", "│", "┤", "─", "╰", "│"},
	--border = "none",
	padding = 0,
}

M.options = {}

M.setup = function(opts)
	opts = opts or {}
	M.options = vim.tbl_deep_extend("force", M.defaults, opts)
end

return M
