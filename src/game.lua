local M = {}

local loader = require('src.loader')
local ui = require('src.ui')
local rules = require('src.rules')

local state = {
	phase = 'loading', -- loading, menu, deckbuilder, setup, combat, resolution
	players = {},
	turn = 1,
	coinFirst = 1,
	background = nil,
	cardBack = nil,
	flipSound = nil,
	log = {},
	selectedHandIndex = {nil, nil},
	setupPassed = {false, false},
	pendingAttackSlot = nil,
	-- Coin toss animation
	coinTossAnimation = { show = false, timer = 0, result = 0 },
	logScroll = 0,
	-- Best of 3 system
	roundWins = {0, 0}, -- Track wins for each player
	gameOver = false,
	currentRound = 1, -- Track current round number
		-- Phase transitions
	phaseTransition = { text = '', timer = 0, show = false },
	resolutionPopup = { show = false, timer = 0, data = {}, buttonX = 0, buttonY = 0, buttonW = 0, buttonH = 0 },
	-- Deck building
	allCards = {},
	currentDeck = {},
	playerDecks = {{}, {}}, -- Separate decks for each player
	deckBuilderPlayer = 1,
	deckBuilderScroll = 0,
	notification = { text = '', timer = 0 },
}

local function log(msg)
	table.insert(state.log, msg)
end

local function showNotification(text, duration)
	duration = duration or 2.0
	state.notification.text = text
	state.notification.timer = duration
end

local function showPhaseTransition(text, duration)
	duration = duration or 2.0
	state.phaseTransition.text = text
	state.phaseTransition.timer = duration
	state.phaseTransition.show = true
end

local function showResolutionPopup(data, duration)
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
	
	showResolutionPopup(popupData, 0) -- No timer, wait for button click
end

local function startCoinTossAnimation()
	state.coinTossAnimation.show = true
	state.coinTossAnimation.timer = 3.0 -- 3 seconds animation
	state.coinTossAnimation.result = love.math.random(2) -- Random result
	log('Coin toss begins...')
end

local function handleResolutionButtonClick()
	if not state.resolutionPopup.show then return false end
	
	local data = state.resolutionPopup.data
	
	-- Resolve the round
	local roundWinner = rules.resolveRound(state)
	
	-- Check if game is over (Best of 3)
	if data.isGameOver then
		local gameWinner = rules.getGameWinner(state)
		log('GAME OVER! '..state.players[gameWinner].name..' wins the match!')
		state.gameOver = true
		state.phase = 'menu' -- Return to menu
	else
		-- Continue to next round
		state.currentRound = state.currentRound + 1
		for _, p in ipairs(state.players) do
			p.field = {nil,nil,nil}
			p.revealed = {false,false,false}
		end
		for _, p in ipairs(state.players) do for i=1,2 do loader.draw(p) end end
		state.phase = 'setup'
		state.turn = state.coinFirst
		log('New round. Draw 2 each. Setup phase.')
		showPhaseTransition('ROUND '..state.currentRound, 2.0)
	end
	
	-- Hide popup
	state.resolutionPopup.show = false
	return true
end

function M.load()
	state.background = love.graphics.newImage('assets/background.png')
	state.cardBack = love.graphics.newImage('assets/card_back.png')
	state.flipSound = love.audio.newSource('assets/flip.wav', 'static')

	-- Load all available cards
	state.allCards = loader.loadCards('docs/list_card.csv')
	
	-- Initialize deck builder
	state.currentDeck = {}
	state.playerDecks = {{}, {}}
	state.deckBuilderPlayer = 1
	state.deckBuilderScroll = 0
	
	state.phase = 'menu'
end

local function startGame()
	-- Build decks from player selections
	local finalDecks = {}
	for pIndex = 1, 2 do
		local deck = {}
		for _, cardData in ipairs(state.playerDecks[pIndex]) do
			for i = 1, cardData.count do
				local card = {}
				for k, v in pairs(cardData.card) do card[k] = v end
				card.strength = card.baseStrength or card.strength
				table.insert(deck, card)
			end
		end
		loader.shuffle(deck)
		finalDecks[pIndex] = deck
	end

	state.players = {
		{ name = 'Player A', deck = finalDecks[1], hand = {}, field = {nil,nil,nil}, grave = {}, revealed = {false,false,false} },
		{ name = 'Player B', deck = finalDecks[2], hand = {}, field = {nil,nil,nil}, grave = {}, revealed = {false,false,false} },
	}

	for _, p in ipairs(state.players) do
		for i=1,5 do loader.draw(p) end
	end

	state.phase = 'setup'
	state.selectedHandIndex = {nil, nil}
	state.setupPassed = {false, false}
	state.pendingAttackSlot = nil
	state.roundWins = {0, 0}
	state.gameOver = false
	state.currentRound = 1
	
	log('Game start. Draw 5 cards each. Setup phase.')
	log('Both players place cards simultaneously, then coin toss determines first player.')
	
	-- Turn will be determined by coin toss after both players pass
	state.turn = 1 -- Temporary, will be set after coin toss
	state.coinFirst = 1 -- Will be set after coin toss
	
	-- Show round start transition
	showPhaseTransition('ROUND '..state.currentRound, 2.0)
end

function M.update(dt)
	-- Update notification timer
	if state.notification.timer > 0 then
		state.notification.timer = state.notification.timer - dt
		if state.notification.timer <= 0 then
			state.notification.text = ''
		end
	end
	
	-- Update phase transition timer
	if state.phaseTransition.timer > 0 then
		state.phaseTransition.timer = state.phaseTransition.timer - dt
		if state.phaseTransition.timer <= 0 then
			state.phaseTransition.show = false
		end
	end
	
	-- Update resolution popup timer
	if state.resolutionPopup.timer > 0 then
		state.resolutionPopup.timer = state.resolutionPopup.timer - dt
		if state.resolutionPopup.timer <= 0 then
			state.resolutionPopup.show = false
		end
	end
	
	-- Update coin toss animation timer
	if state.coinTossAnimation.timer > 0 then
		state.coinTossAnimation.timer = state.coinTossAnimation.timer - dt
		if state.coinTossAnimation.timer <= 0 then
			-- Animation finished, set first player and start combat
			state.turn = state.coinTossAnimation.result
			state.coinFirst = state.turn
			state.coinTossAnimation.show = false
			state.phase = 'combat'
			log(state.players[state.turn].name..' goes first!')
			showPhaseTransition('COMBAT PHASE', 2.0)
		end
	end
end

local function currentPlayer()
	return state.players[state.turn]
end

function M.draw()
	love.graphics.setColor(1,1,1,1)
	if state.background then love.graphics.draw(state.background, 0, 0, 0, love.graphics.getWidth()/state.background:getWidth(), love.graphics.getHeight()/state.background:getHeight()) end

	if state.phase == 'menu' then
		ui.drawMenu(state)
	elseif state.phase == 'deckbuilder' then
		ui.drawDeckBuilder(state, state.cardBack)
	else
		ui.drawBoard(state, state.cardBack)
		ui.drawHands(state, state.cardBack)
		ui.drawDeckAndGY(state, state.cardBack)
		ui.drawPassButton(state)
		ui.drawHoverTooltip(state)
		ui.drawLog(state.log, state.logScroll)

		-- Turn indicator (left center)
		local screenH = love.graphics.getHeight()
		love.graphics.setColor(1,1,1,1)
		love.graphics.print('Turn: '..currentPlayer().name, 16, screenH*0.5 - 10)
		
		-- Draw phase transitions and popups
		drawPhaseTransition(state)
		drawCoinTossAnimation(state)
		drawResolutionPopup(state)
	end
end

local function allFieldsFilled(player)
	for i=1,3 do if player.field[i]==nil then return false end end
	return true
end

local function allRevealed()
	for _, p in ipairs(state.players) do
		for i=1,3 do if p.field[i] and not p.revealed[i] then return false end end
	end
	return true
end

local function hasUnrevealedCards(player)
	for i=1,3 do if player.field[i] and not player.revealed[i] then return true end end
	return false
end

local function autoRevealRemaining(state)
	-- Auto-reveal all remaining face-down cards in order
	for _, p in ipairs(state.players) do
		for i=1,3 do
			if p.field[i] and not p.revealed[i] then
				p.revealed[i] = true
				state.flipSound:stop(); state.flipSound:play()
				log(p.name..' auto-reveals '..p.field[i].name)
				rules.onFlip(p, i, state)
			end
		end
	end
end

local function nextTurn()
	state.turn = 3 - state.turn
end

local function startCombatIfReady()
	if (allFieldsFilled(state.players[1]) and allFieldsFilled(state.players[2])) or (state.setupPassed[1] and state.setupPassed[2]) then
		state.phase = 'combat'
		log('Combat phase begins. '..state.players[state.coinFirst].name..' goes first.')
		state.turn = state.coinFirst
		showPhaseTransition('COMBAT PHASE', 2.0)
	end
end

function M.mousepressed(x, y, button)
	if button ~= 1 and button ~= 2 then return end
	
	-- Check for Next Round button click first
	if state.resolutionPopup.show then
		local btnX = state.resolutionPopup.buttonX
		local btnY = state.resolutionPopup.buttonY
		local btnW = state.resolutionPopup.buttonW
		local btnH = state.resolutionPopup.buttonH
		
		if x >= btnX and x <= btnX + btnW and y >= btnY and y <= btnY + btnH then
			handleResolutionButtonClick()
			return
		end
	end
	
	if state.phase == 'menu' then
		if ui.hitMenuButton(x, y) then
			state.phase = 'deckbuilder'
		end
	elseif state.phase == 'deckbuilder' then
		ui.handleDeckBuilderClick(state, x, y, button)
	elseif state.phase == 'setup' then
		-- Check for Player A pass button
		if ui.hitPassButton(state, x, y, 1) then
			state.setupPassed[1] = true
			log('Player A passes.')
			if state.setupPassed[1] and state.setupPassed[2] then
				-- Both players passed, start coin toss
				startCoinTossAnimation()
			end
			return
		end
		
		-- Check for Player B pass button
		if ui.hitPassButton(state, x, y, 2) then
			state.setupPassed[2] = true
			log('Player B passes.')
			if state.setupPassed[1] and state.setupPassed[2] then
				-- Both players passed, start coin toss
				startCoinTossAnimation()
			end
			return
		end
		
		-- Handle card placement for both players
		for playerIndex = 1, 2 do
			local p = state.players[playerIndex]
			local handIndex = ui.hitHand(state, p, x, y)
			if handIndex then
				state.selectedHandIndex[playerIndex] = handIndex
				log(p.name..' selected '..p.hand[handIndex].name..' from hand.')
				break
			else
				local slot = ui.hitFieldSlot(playerIndex, x, y)
				if slot and p.field[slot]==nil and state.selectedHandIndex[playerIndex] then
					local idx = state.selectedHandIndex[playerIndex]
					p.field[slot] = table.remove(p.hand, idx)
					state.selectedHandIndex[playerIndex] = nil
					log(p.name..' placed a card face-down at slot '..slot)
					break
				end
			end
		end
	elseif state.phase == 'combat' then
		local attacker = currentPlayer()
		if not state.pendingAttackSlot then
			-- Step 1: Choose your face-down card to reveal
			local aSlot = ui.hitFieldSlot(state.turn, x, y)
			if aSlot and attacker.field[aSlot] and not attacker.revealed[aSlot] then
				attacker.revealed[aSlot] = true
				state.flipSound:stop(); state.flipSound:play()
				log(attacker.name..' reveals '..attacker.field[aSlot].name)
				state.pendingAttackSlot = aSlot
				log('Choose an opponent card to reveal and battle.')
			end
		else
			-- Step 2: Choose opponent's face-down card to reveal and fight
			local defender = state.players[3 - state.turn]
			local dSlot = ui.hitFieldSlot(3 - state.turn, x, y)
			if dSlot and defender.field[dSlot] and not defender.revealed[dSlot] then
				defender.revealed[dSlot] = true
				state.flipSound:stop(); state.flipSound:play()
				log(defender.name..' reveals '..defender.field[dSlot].name)
				-- resolve combat
				rules.resolveCombat(attacker, state.pendingAttackSlot, defender, dSlot, state)
				state.pendingAttackSlot = nil
				nextTurn()
				-- Check if combat can continue
				if not hasUnrevealedCards(currentPlayer()) then
					-- Current player has no unrevealed cards, auto-reveal remaining
					autoRevealRemaining(state)
					state.phase = 'resolution'
					-- Immediately show resolution popup
					showResolutionPopupImmediately(state)
				end
			end
		end
		elseif state.phase == 'resolution' then
		-- Resolution popup is already shown immediately when phase changes
		-- No additional logic needed here
	end
end

function M.keypressed(key)
	if key == 'r' then M.load() end
	if state.phase == 'deckbuilder' then
		if key == 'escape' then
			state.phase = 'menu'
		elseif key == 'return' then
			-- Check both deck sizes and start game
			local p1Cards = 0
			for _, cardData in ipairs(state.playerDecks[1]) do
				p1Cards = p1Cards + cardData.count
			end
			local p2Cards = 0
			for _, cardData in ipairs(state.playerDecks[2]) do
				p2Cards = p2Cards + cardData.count
			end
			if p1Cards >= 15 and p1Cards <= 25 and p2Cards >= 15 and p2Cards <= 25 then
				startGame()
			end
		end
	elseif state.phase == 'setup' and key == 'tab' then
		-- quick local two-player toggle without passing
		nextTurn()
		log('Switched to '..currentPlayer().name..' (Tab).')
	end
end

function M.wheelmoved(dx, dy)
	if state.phase == 'deckbuilder' then
		-- Calculate max scroll for deck builder with archetype grouping
		local cardsPerRow = 6
		local cardH = 110
		local cardSpacing = 8
		local archetypeSpacing = 20
		local h = love.graphics.getHeight()
		local availableHeight = h - 180 -- Even more padding at bottom (120 to h-60)
		
		-- Group cards by archetype (same logic as UI)
		local archetypes = {}
		for _, card in ipairs(state.allCards) do
			local archetype = card.archetype or 'Other'
			if not archetypes[archetype] then
				archetypes[archetype] = {}
			end
			table.insert(archetypes[archetype], card)
		end
		
		-- Calculate total height needed for all archetypes
		local totalHeight = 0
		for archetypeName, cards in pairs(archetypes) do
			local rowsUsed = math.ceil(#cards / cardsPerRow)
			totalHeight = totalHeight + (rowsUsed * (cardH + cardSpacing)) + archetypeSpacing
		end
		-- Add extra padding at the bottom so cards don't get cut off
		totalHeight = totalHeight + 40
		
		local maxScroll = math.max(0, totalHeight - availableHeight)
		local scrollStep = 20 -- Fixed scroll step
		local newScroll = state.deckBuilderScroll - dy * scrollStep
		state.deckBuilderScroll = math.max(0, math.min(maxScroll, newScroll))
	end
	-- Log is now non-scrollable, so no scroll handling needed
end

return M


