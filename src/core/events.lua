local events = {}

-- Import modules
local ui = require('src.ui.ui')
local rules = require('src.rules.rules')
local combat = require('src.game.combat')
local resolution = require('src.game.resolution')
local setup = require('src.game.setup')
local deck = require('src.game.deck')
local helpers = require('src.utils.helpers')
local config = require('src.data.config')

-- Get game state
local function getState()
	return require('src.core.state').get()
end

-- Logging function
local function log(message)
	local gameState = getState()
	helpers.log(message, gameState)
end

-- Phase transition function
local function showPhaseTransition(text, duration)
	local gameState = getState()
	duration = duration or config.ANIMATION.PHASE_TRANSITION_DURATION
	gameState.phaseTransition.text = text
	gameState.phaseTransition.timer = duration
	gameState.phaseTransition.show = true
end

function events.mousepressed(x, y, button)
	local gameState = getState()
	
	if button ~= 1 and button ~= 2 then return end
	
	-- Handle menu clicks
	if gameState.phase == 'menu' then
		local menus = require('src.ui.menus')
		local clickedButton = menus.hitMenuButton(x, y, gameState)
		
		if clickedButton == 'singlePlayer' then
			gameState.phase = 'deckbuilder'
			gameState.multiplayer = false
			return
		elseif clickedButton == 'multiplayer' then
			gameState.phase = 'lobby'
			return
		end
	end
	
	-- Check for Next Round button click first
	if gameState.resolutionPopup.show then
		local btnX = gameState.resolutionPopup.buttonX
		local btnY = gameState.resolutionPopup.buttonY
		local btnW = gameState.resolutionPopup.buttonW
		local btnH = gameState.resolutionPopup.buttonH
		
		if x >= btnX and x <= btnX + btnW and y >= btnY and y <= btnY + btnH then
			events.handleResolutionButtonClick()
			return
		end
	end
	
	if gameState.phase == 'deckbuilder' then
		ui.handleDeckBuilderClick(gameState, x, y, button)
	elseif gameState.phase == 'setup' then
		-- In multiplayer, only allow current player to pass
		local currentPlayerId = gameState.multiplayer and gameState.networkPlayerId or 1
		
		-- Check for Player A pass button
		if ui.hitPassButton(gameState, x, y, 1) then
			if not gameState.multiplayer or currentPlayerId == 1 then
				gameState.setupPassed[1] = true
				log('Player A passes.')
				
				-- Send network message in multiplayer
				if gameState.multiplayer and gameState.network then
					gameState.network.sendSetupPassed(1)
				end
				
				if gameState.setupPassed[1] and gameState.setupPassed[2] then
					-- Both players passed, start coin toss
					setup.startCoinTossAnimation(gameState)
				end
			end
			return
		end
		
		-- Check for Player B pass button
		if ui.hitPassButton(gameState, x, y, 2) then
			if not gameState.multiplayer or currentPlayerId == 2 then
				gameState.setupPassed[2] = true
				log('Player B passes.')
				
				-- Send network message in multiplayer
				if gameState.multiplayer and gameState.network then
					gameState.network.sendSetupPassed(2)
				end
				
				if gameState.setupPassed[1] and gameState.setupPassed[2] then
					-- Both players passed, start coin toss
					setup.startCoinTossAnimation(gameState)
				end
			end
			return
		end
		
		-- Handle card placement for both players
		for playerIndex = 1, 2 do
			local p = gameState.players[playerIndex]
			
			-- In multiplayer, only allow current player to interact
			if gameState.multiplayer and gameState.networkPlayerId ~= playerIndex then
				goto continue
			end
			
			local handIndex = ui.hitHand(gameState, p, x, y)
			if handIndex then
				gameState.selectedHandIndex[playerIndex] = handIndex
				log(p.name..' selected '..p.hand[handIndex].name..' from hand.')
				break
			else
				local slot = ui.hitFieldSlot(playerIndex, x, y)
				if slot and p.field[slot]==nil and gameState.selectedHandIndex[playerIndex] then
					local idx = gameState.selectedHandIndex[playerIndex]
					local card = table.remove(p.hand, idx)
					p.field[slot] = card
					gameState.selectedHandIndex[playerIndex] = nil
					log(p.name..' placed a card face-down at slot '..slot)
					
					-- Send network message in multiplayer
					if gameState.multiplayer and gameState.network then
						gameState.network.sendCardPlaced(playerIndex, slot, card)
					end
					break
				end
			end
			
			::continue::
		end
	elseif gameState.phase == 'combat' then
		-- In multiplayer, only allow current player to interact
		if gameState.multiplayer and gameState.networkPlayerId ~= gameState.turn then
			return
		end
		
		local attacker = gameState.players[gameState.turn]
		if not gameState.pendingAttackSlot then
			-- Step 1: Choose your face-down card to reveal
			local aSlot = ui.hitFieldSlot(gameState.turn, x, y)
			if aSlot and attacker.field[aSlot] and not attacker.revealed[aSlot] then
				attacker.revealed[aSlot] = true
				gameState.flipSound:stop(); gameState.flipSound:play()
				log(attacker.name..' reveals '..attacker.field[aSlot].name)
				gameState.pendingAttackSlot = aSlot
				log('Choose an opponent card to reveal and battle.')
				
				-- Send network message in multiplayer
				if gameState.multiplayer and gameState.network then
					gameState.network.sendCardRevealed(gameState.turn, aSlot)
				end
			end
		else
			-- Step 2: Choose opponent's face-down card to reveal and fight
			local defender = gameState.players[3 - gameState.turn]
			local dSlot = ui.hitFieldSlot(3 - gameState.turn, x, y)
			if dSlot and defender.field[dSlot] and not defender.revealed[dSlot] then
				defender.revealed[dSlot] = true
				gameState.flipSound:stop(); gameState.flipSound:play()
				log(defender.name..' reveals '..defender.field[dSlot].name)
				
				-- Send network message in multiplayer
				if gameState.multiplayer and gameState.network then
					gameState.network.sendCardRevealed(3 - gameState.turn, dSlot)
				end
				
				-- resolve combat
				rules.resolveCombat(attacker, gameState.pendingAttackSlot, defender, dSlot, gameState)
				gameState.pendingAttackSlot = nil
				helpers.nextTurn(gameState)
				
				-- Send turn change in multiplayer
				if gameState.multiplayer and gameState.network then
					gameState.network.sendTurnChanged(gameState.turn)
				end
				
				-- Check if combat can continue
				if not combat.canContinue(gameState) then
					-- No more combat possible, auto-reveal remaining cards
					log('No more combat possible. Auto-revealing remaining cards.')
					combat.autoRevealRemaining(gameState)
					gameState.phase = 'resolution'
					-- Immediately show resolution popup
					resolution.showResolutionPopupImmediately(gameState)
				end
			end
		end
	end
end

function events.handleResolutionButtonClick()
	local gameState = getState()
	if not gameState.resolutionPopup.show then return false end
	
	local data = gameState.resolutionPopup.data
	
	-- Resolve the round
	local roundWinner = rules.resolveRound(gameState)
	
	-- Check if game is over (Best of 3)
	if data.isGameOver then
		local gameWinner = rules.getGameWinner(gameState)
		log('GAME OVER! '..gameState.players[gameWinner].name..' wins the match!')
		gameState.gameOver = true
		gameState.phase = 'menu' -- Return to menu
	else
		-- Continue to next round
		gameState.currentRound = gameState.currentRound + 1
		for _, p in ipairs(gameState.players) do
			p.field = {nil,nil,nil}
			p.revealed = {false,false,false}
		end
		for _, p in ipairs(gameState.players) do 
			for i=1,config.GAME.DRAW_PER_ROUND do 
				deck.draw(p) 
			end 
		end
		gameState.phase = 'setup'
		gameState.turn = gameState.coinFirst
		-- Reset pass status for new round
		gameState.setupPassed = {false, false}
		log('New round. Draw 2 each. Setup phase.')
		showPhaseTransition('ROUND '..gameState.currentRound, 2.0)
	end
	
	-- Hide popup
	gameState.resolutionPopup.show = false
	return true
end

function events.keypressed(key)
	local gameState = getState()
	
	if key == 'r' then 
		require('src.core.game').load() 
	end
	
	if gameState.phase == 'deckbuilder' then
		if key == 'escape' then
			gameState.phase = 'menu'
		elseif key == 'return' then
			-- Handle multiplayer vs single player differently
			if gameState.multiplayer then
				-- Multiplayer: use deckbuilder.confirmDeckSelection
				local deckbuilder = require('src.ui.deckbuilder')
				deckbuilder.confirmDeckSelection(gameState)
			else
				-- Single player: check both deck sizes and start game
				local p1Cards = 0
				for _, cardData in ipairs(gameState.playerDecks[1]) do
					p1Cards = p1Cards + cardData.count
				end
				local p2Cards = 0
				for _, cardData in ipairs(gameState.playerDecks[2]) do
					p2Cards = p2Cards + cardData.count
				end
				log('Deck sizes: Player 1='..p1Cards..', Player 2='..p2Cards)
				log('Required: MIN='..config.GAME.MIN_DECK_SIZE..', MAX='..config.GAME.MAX_DECK_SIZE)
				if p1Cards >= config.GAME.MIN_DECK_SIZE and p1Cards <= config.GAME.MAX_DECK_SIZE and 
				   p2Cards >= config.GAME.MIN_DECK_SIZE and p2Cards <= config.GAME.MAX_DECK_SIZE then
					log('Starting game...')
					require('src.core.game').startGame()
				else
					log('Deck sizes invalid! Cannot start game.')
				end
			end
		end
	elseif gameState.phase == 'setup' and key == 'tab' then
		-- quick local two-player toggle without passing
		helpers.nextTurn(gameState)
		log('Switched to '..gameState.players[gameState.turn].name..' (Tab).')
	end
end

function events.wheelmoved(x, y)
	local gameState = getState()
	if gameState.phase == 'deckbuilder' then
		local scrollStep = 20
		
		-- Calculate actual content height
		local cardsPerRow = 6
		local cardH = 110
		local cardSpacing = 8
		local archetypeSpacing = 20
		local totalCards = #gameState.allCards
		local totalRows = math.ceil(totalCards / cardsPerRow)
		local contentHeight = (totalRows * (cardH + cardSpacing)) + (6 * archetypeSpacing) -- 6 archetypes
		
		-- Calculate visible area height
		local visibleHeight = love.graphics.getHeight() - 180 - 160 -- Total height - top area - bottom area
		
		-- Calculate max scroll needed
		local maxScroll = math.max(0, contentHeight - visibleHeight + 50) -- Extra 50px padding at bottom
		
		gameState.deckBuilderScroll = math.max(0, math.min(maxScroll, gameState.deckBuilderScroll - y * scrollStep))
	end
end

return events
