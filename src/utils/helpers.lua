local helpers = {}

function helpers.log(message, gameState)
	if not gameState or not gameState.log then
		print(message)
		return
	end
	table.insert(gameState.log, message)
	
	-- Limit log size to prevent memory leaks (keep last 100 entries)
	local maxLogEntries = 100
	if #gameState.log > maxLogEntries then
		-- Remove oldest entries
		for i = 1, #gameState.log - maxLogEntries do
			table.remove(gameState.log, 1)
		end
	end
	
	print(message)
end

function helpers.sanitizeUtf8(s)
	if not s then return '' end
	if love.utf8 and pcall(love.utf8.len, s) then return s end
	s = s:gsub('[^%z\32-\126]', '')
	return s
end

function helpers.currentPlayer(state)
	return state.players[state.turn]
end

function helpers.nextTurn(state)
	state.turn = 3 - state.turn
end

return helpers
