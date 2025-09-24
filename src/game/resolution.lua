local resolution = {}

local function showResolutionPopup(state, data, duration)
	duration = duration or 4.0
	state.resolutionPopup.data = data
	state.resolutionPopup.timer = duration
	state.resolutionPopup.show = true
end

local function showResolutionPopupImmediately(state)
	local sums = {0,0}
	local cardDetails = {'', ''}
	
	for pIndex=1,2 do
		local p = state.players[pIndex]
		local cards = {}
		for i=1,3 do
			local c = p.field[i]
			if c then
				local str = c.strength or 0
				sums[pIndex] = sums[pIndex] + str
				table.insert(cards, c.name..' ('..c.element..' STR '..str..')')
			end
		end
		cardDetails[pIndex] = table.concat(cards, ', ')
	end
	
	local winner = 0
	if sums[1] > sums[2] then winner = 1
	elseif sums[2] > sums[1] then winner = 2 end
	
	-- Calculate what the new scores will be after this round
	local newRoundWins = {state.roundWins[1], state.roundWins[2]}
	if winner > 0 then
		newRoundWins[winner] = newRoundWins[winner] + 1
	end
	
	local popupData = {
		round = state.currentRound,
		player1Cards = cardDetails[1],
		player1Strength = sums[1],
		player2Cards = cardDetails[2],
		player2Strength = sums[2],
		winner = winner,
		roundWins = newRoundWins,
		isGameOver = (newRoundWins[1] >= 2 or newRoundWins[2] >= 2)
	}
	
	showResolutionPopup(state, popupData, 0) -- No timer, wait for button click
end

function resolution.showResolutionPopup(state, data, duration)
	showResolutionPopup(state, data, duration)
end

function resolution.showResolutionPopupImmediately(state)
	showResolutionPopupImmediately(state)
end

return resolution
