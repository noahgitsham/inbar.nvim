local M = {}

M.winTable = {} -- Stores ID kv pairs: windowID, inbarID

local config = require("inbar.config").options

-- Creates corresponding bar windows for each buffer window
M.createMissingBars = function ()
	for _, winID in pairs(vim.api.nvim_list_wins()) do
		if M.winUsesBar(winID) and not M.winTable[winID] then
			print("ID:", winID, "Title:", vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(winID)))
			M.createBar(winID)
		end
	end
end

M.createBar = function(winID)
	local bufferID = vim.api.nvim_create_buf(false, true)
	local winName = vim.fn.expand("%") --vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(winID))
	local barConfig = M.createBarConfig(winID)
	vim.api.nvim_buf_set_lines(bufferID, 0, -1, false, {winName})
	local barID = vim.api.nvim_open_win(bufferID, false, barConfig)
	M.winTable[winID] = barID
end

M.removeBar = function(winID)
	vim.api.nvim_win_close(M.winTable[winID], true)
	table.remove(M.winTable, winID)
end

M.updateBarContent = function(winID, contentFunc)
	local barID = M.winTable[winID]
	local content = contentFunc()
	vim.api.nvim_buf_set_lines(barID, 0, -1, false, {content})
	M.updateBarWidth(winID, string.len(content))
end

M.updateBarWidth = function(winID, width)
	local barConfig = vim.api.nvim_win_get_config(M.winTable[winID])
	barConfig.width = width
end

M.winUsesBar = function(winID)
	local winConfig = vim.api.nvim_win_get_config(winID)
	return winConfig.relative == "" -- If not floating
end

local winAtTop = function(winID)
	local winRow = vim.api.nvim_win_get_position(winID)[1]
	return (winRow == 0)
end

local winAtRightSide = function(winID)
	local winColumn = vim.api.nvim_win_get_position(winID)[2]
	local winWidth = vim.api.nvim_win_get_width(winID)
	local rightDistance = vim.opt.columns:get() - winColumn - winWidth
	return (rightDistance == 0)
end

M.updateBorderValues = function (winID, border)
	if border and type(border) ~= "string" then -- If enabled and not "single", etc
		if winAtTop(winID) then
			for i = 1, 3 do
				border[i] = ""
			end
		end
		if winAtRightSide(winID) then
			for i = 3, 5 do
				border[i] = ""
			end
		end
	end
end

M.createBarConfig = function(winID)
	local border = {unpack(config.border)} -- Shallow copy of border

	M.updateBorderValues(winID, border)

	local barConfig = {
		relative  = "win",
		win       = winID,
		anchor    = "NE",
		width     = 1,
		height    = 1,
		focusable = false,
		row       = -1,
		col       = vim.api.nvim_win_get_width(winID) + 1,
		style     = "minimal",
		border    = border,
	}

	M.updateBarContent(winID, function (winID)
		return tostring(vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(winID)))
	end)

	return barConfig
end

M.updateBarPosition = function (winID)
	vim.cmd.redraw()
	local barID = M.winTable[winID]
	local barConfig = vim.api.nvim_win_get_config(barID)
	barConfig.row = -1
	barConfig.col = vim.api.nvim_win_get_width(winID) + 1
	vim.api.nvim_win_set_config(barID, barConfig)
end

M.updateBarBorder = function (winID)
	local barID = M.winTable[winID]
	local barConfig = vim.api.nvim_win_get_config(barID)
	local border = {unpack(config.border)} -- Shallow copy of border
	M.updateBorderValues(winID, border)
	barConfig.border = border
	vim.api.nvim_win_set_config(barID, barConfig)
end


--M.updateAllBarPositions = function()
--	for winID, barID in pairs(M.winTable) do
--		local barConfig = vim.api.nvim_win_get_config(barID)
--		local col = vim.api.nvim_win_get_width(winID) + 1
--		barConfig.col = col
--		barConfig.row = -1
--		vim.api.nvim_win_set_config(barID, barConfig)
--	end
--end

M.createAutocommands = function()
	local autocommandGroup = vim.api.nvim_create_augroup("inbar", { clear = true })
	-- New window autocommand
	vim.api.nvim_create_autocmd("WinNew", {
		group = autocommandGroup,
		callback = function(args)
			M.createMissingBars()
		end,
	})

	-- Closing window autocommand
	vim.api.nvim_create_autocmd("WinClosed", {
		group = autocommandGroup,
		callback = function(args)
			local closedWinID = tonumber(args.match) --Get ID of window to be closed. Messy, fix if api becomes less bs
			--local closedWinID = vim.api.nvim_get_current_win()
			if M.winTable[closedWinID] then
				M.removeBar(closedWinID)
				
			end
		end,
	})

	-- Resize window autocommand
	vim.api.nvim_create_autocmd("WinResized", {
		group = autocommandGroup,
		callback = function()
			local resizedWinIDs = vim.v.event.windows
			for _, winID in pairs(resizedWinIDs) do
				if M.winTable[winID] then
					M.updateBarPosition(winID)
					M.updateBarBorder(winID)
				end
			end
			

		end,

	})
end

return M
