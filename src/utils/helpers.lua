local helpers = {}

function helpers.log(message, gameState)
	if not gameState or not gameState.log then
		print(message)
		return
	end
	table.insert(gameState.log, message)
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
