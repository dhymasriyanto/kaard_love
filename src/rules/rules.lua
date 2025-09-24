local loader = require('src.utils.loader')
local rules = {}

local beats = {
	Sword = 'Orb',
	Orb = 'Shield',
	Shield = 'Sword',
}

local function sendToGY(player, slot)
	local card = player.field[slot]
	if not card then return end
	table.insert(player.grave, card)
	player.field[slot] = nil
	player.revealed[slot] = false
end

-- Coin toss to determine first player
function rules.coinToss(state)
	local winner = love.math.random(2)
	state.turn = winner
	table.insert(state.log, 'Coin toss: '..state.players[winner].name..' goes first!')
	return winner
end

local function combatOutcome(a, d)
	if beats[a.element] == d.element then return 1 end
	if beats[d.element] == a.element then return -1 end
	-- same or neutral: compare strength
	if (a.strength or 0) > (d.strength or 0) then return 1 end
	if (a.strength or 0) < (d.strength or 0) then return -1 end
	return 0
end

function rules.resolveCombat(attacker, aSlot, defender, dSlot, state)
	local a = attacker.field[aSlot]
	local d = defender.field[dSlot]
	if not a or not d then return end
	
	local result = combatOutcome(a, d)
	local combatMsg = ''
	
	if result == 1 then
		-- attacker wins
		sendToGY(defender, dSlot)
		if beats[a.element] == d.element then
			combatMsg = a.name..' ('..a.element..') defeats '..d.name..' ('..d.element..') - '..a.element..' beats '..d.element..'!'
		else
			combatMsg = a.name..' ('..a.element..' STR '..a.strength..') defeats '..d.name..' ('..d.element..' STR '..d.strength..') - Higher strength!'
		end
		table.insert(state.log, combatMsg)
	elseif result == -1 then
		-- defender wins
		sendToGY(attacker, aSlot)
		if beats[d.element] == a.element then
			combatMsg = d.name..' ('..d.element..') defeats '..a.name..' ('..a.element..') - '..d.element..' beats '..a.element..'!'
		else
			combatMsg = d.name..' ('..d.element..' STR '..d.strength..') defeats '..a.name..' ('..a.element..' STR '..a.strength..') - Higher strength!'
		end
		table.insert(state.log, combatMsg)
	else
		-- tie: both to GY
		sendToGY(defender, dSlot)
		sendToGY(attacker, aSlot)
		combatMsg = a.name..' ('..a.element..' STR '..a.strength..') and '..d.name..' ('..d.element..' STR '..d.strength..') tie! Both destroyed.'
		table.insert(state.log, combatMsg)
	end
end

function rules.resolveRound(state)
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
	
	-- Log detailed strength calculation
	table.insert(state.log, '=== ROUND RESOLUTION ===')
	table.insert(state.log, state.players[1].name..' remaining cards: '..cardDetails[1])
	table.insert(state.log, state.players[1].name..' total strength: '..sums[1])
	table.insert(state.log, state.players[2].name..' remaining cards: '..cardDetails[2])
	table.insert(state.log, state.players[2].name..' total strength: '..sums[2])
	
	local resultText = 'Round result: '
	local winner = 0
	if sums[1] > sums[2] then 
		resultText = resultText..state.players[1].name..' wins ('..sums[1]..' vs '..sums[2]..')'
		winner = 1
	elseif sums[2] > sums[1] then 
		resultText = resultText..state.players[2].name..' wins ('..sums[2]..' vs '..sums[1]..')'
		winner = 2
	else 
		resultText = resultText..'Draw ('..sums[1]..')'
	end
	table.insert(state.log, resultText)
	
	-- Update Best of 3 scores
	if winner > 0 then
		state.roundWins[winner] = state.roundWins[winner] + 1
		table.insert(state.log, state.players[winner].name..' wins round! Score: '..state.roundWins[1]..'-'..state.roundWins[2])
	end
	
	-- move remaining to GY
	for _, p in ipairs(state.players) do
		for i=1,3 do if p.field[i] then table.insert(p.grave, p.field[i]); p.field[i]=nil end end
	end
	
	return winner
end

-- Check if game is over (Best of 3)
function rules.isGameOver(state)
	return state.roundWins[1] >= 2 or state.roundWins[2] >= 2
end

-- Get game winner
function rules.getGameWinner(state)
	if state.roundWins[1] >= 2 then return 1
	elseif state.roundWins[2] >= 2 then return 2
	else return 0 end
end

return rules


