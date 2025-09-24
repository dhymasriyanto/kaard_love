local combat = {}
local helpers = require('src.utils.helpers')

local function canCombatContinue(state)
	-- Check if there are any possible combat combinations left
	local attacker = state.players[state.turn]
	local defender = state.players[3 - state.turn]
	
	-- Check if attacker has unrevealed cards
	local attackerHasUnrevealed = false
	for i=1,3 do
		if attacker.field[i] and not attacker.revealed[i] then
			attackerHasUnrevealed = true
			break
		end
	end
	
	-- Check if defender has unrevealed cards
	local defenderHasUnrevealed = false
	for i=1,3 do
		if defender.field[i] and not defender.revealed[i] then
			defenderHasUnrevealed = true
			break
		end
	end
	
	-- Combat can continue if both players have unrevealed cards
	return attackerHasUnrevealed and defenderHasUnrevealed
end

local function autoRevealRemaining(state)
	-- Auto-reveal all remaining face-down cards in order
	for _, p in ipairs(state.players) do
		for i=1,3 do
			if p.field[i] and not p.revealed[i] then
				p.revealed[i] = true
				state.flipSound:stop(); state.flipSound:play()
				helpers.log(p.name..' auto-reveals '..p.field[i].name, state)
				-- Note: No ability effects since we removed all abilities
			end
		end
	end
end

local function hasUnrevealedCards(player)
	for i=1,3 do if player.field[i] and not player.revealed[i] then return true end end
	return false
end

function combat.canContinue(state)
	return canCombatContinue(state)
end

function combat.autoRevealRemaining(state)
	autoRevealRemaining(state)
end

function combat.hasUnrevealedCards(player)
	return hasUnrevealedCards(player)
end

return combat
