local game = {}

-- Import all modules
local loader = require('src.utils.loader')
local ui = require('src.ui.ui')
local rules = require('src.rules.rules')
local menus = require('src.ui.menus')

-- Game modules
local combat = require('src.game.combat')
local setup = require('src.game.setup')
local resolution = require('src.game.resolution')
local deck = require('src.game.deck')

-- Core modules
local state = require('src.core.state')
local multiplayer = require('src.core.multiplayer')

-- Utils
local helpers = require('src.utils.helpers')
local config = require('src.data.config')

-- Get game state
local function getState()
	return state.get()
end

-- Logging function
local function log(message)
	local gameState = getState()
	helpers.log(message, gameState)
end

-- Phase transition functions
local function showPhaseTransition(text, duration)
	local gameState = getState()
	duration = duration or config.ANIMATION.PHASE_TRANSITION_DURATION
	gameState.phaseTransition.text = text
	gameState.phaseTransition.timer = duration
	gameState.phaseTransition.show = true
end

local function showResolutionPopup(data, duration)
	local gameState = getState()
	duration = duration or config.ANIMATION.RESOLUTION_POPUP_DURATION
	gameState.resolutionPopup.data = data
	gameState.resolutionPopup.timer = duration
	gameState.resolutionPopup.show = true
end

-- Game initialization
function game.load()
	local gameState = getState()
	gameState.phase = 'loading'
	gameState.allCards = loader.loadCards('docs/list_card.csv')
	gameState.flipSound = loader.loadSound('assets/sounds/flip.wav')
	gameState.background = loader.loadBackground()
	gameState.phase = 'menu'
	
	-- Initialize multiplayer
	multiplayer.init()
	
	log('Game loaded successfully!')
end

function game.update(dt)
	local gameState = getState()
	
	-- Update multiplayer
	multiplayer.update(dt)
	
	-- Update multiplayer state in game state
	gameState.multiplayer.isMultiplayer = multiplayer.isMultiplayer()
	
	-- Check if client should enter deck builder
	if multiplayer.isMultiplayer() and multiplayer.isInDeckBuilder() and gameState.phase == 'menu' then
		gameState.phase = 'deckbuilder'
		gameState.deckBuilderPlayer = multiplayer.getMyPlayerId()
		log('Entering multiplayer deck builder as ' .. (multiplayer.getMode() == 'host' and 'Host' or 'Client'))
	end
	
	-- Update notification timer
	if gameState.notification.timer > 0 then
		gameState.notification.timer = gameState.notification.timer - dt
		if gameState.notification.timer <= 0 then
			gameState.notification.text = ''
		end
	end
	
	-- Update phase transition timer
	if gameState.phaseTransition.timer > 0 then
		gameState.phaseTransition.timer = gameState.phaseTransition.timer - dt
		if gameState.phaseTransition.timer <= 0 then
			gameState.phaseTransition.show = false
		end
	end
	
	-- Update resolution popup timer
	if gameState.resolutionPopup.timer > 0 then
		gameState.resolutionPopup.timer = gameState.resolutionPopup.timer - dt
		if gameState.resolutionPopup.timer <= 0 then
			gameState.resolutionPopup.show = false
		end
	end
	
	-- Update coin toss animation timer
	if gameState.coinTossAnimation.timer > 0 then
		gameState.coinTossAnimation.timer = gameState.coinTossAnimation.timer - dt
		if gameState.coinTossAnimation.timer <= 0 then
			-- Animation finished, set first player and start combat
			gameState.turn = gameState.coinTossAnimation.result
			gameState.coinFirst = gameState.turn
			gameState.coinTossAnimation.show = false
			gameState.phase = 'combat'
			log(gameState.players[gameState.turn].name..' goes first!')
			
			-- Send game state sync in multiplayer
			if multiplayer.isMultiplayer() then
				multiplayer.sendGameState()
			end
			
			-- Check if combat is even possible
			if not combat.canContinue(gameState) then
				-- No combat possible, auto-reveal all cards and go to resolution
				log('No combat possible. Auto-revealing all cards.')
				combat.autoRevealRemaining(gameState)
				gameState.phase = 'resolution'
				resolution.showResolutionPopupImmediately(gameState)
			else
				showPhaseTransition('COMBAT PHASE', 2.0)
			end
		end
	end
end

function game.draw()
	local gameState = getState()
	local cardBack = loader.loadCardBack()
	
	-- Draw game background
	if gameState.background then
		love.graphics.setColor(1,1,1,1)
		love.graphics.draw(gameState.background, 0, 0, 0, love.graphics.getWidth()/gameState.background:getWidth(), love.graphics.getHeight()/gameState.background:getHeight())
	end
	
	if gameState.phase == 'menu' then
		ui.drawMenu(gameState)
	elseif gameState.phase == 'deckbuilder' then
		ui.drawDeckBuilder(gameState, cardBack)
	elseif gameState.phase == 'setup' then
		ui.drawBoard(gameState, cardBack)
		ui.drawHands(gameState, cardBack)
		ui.drawDeckAndGY(gameState, cardBack)
		ui.drawPassButton(gameState)
	elseif gameState.phase == 'combat' then
		ui.drawBoard(gameState, cardBack)
		ui.drawHands(gameState, cardBack)
		ui.drawDeckAndGY(gameState, cardBack)
	elseif gameState.phase == 'resolution' then
		ui.drawBoard(gameState, cardBack)
		ui.drawHands(gameState, cardBack)
		ui.drawDeckAndGY(gameState, cardBack)
	end
	
	-- Always draw these overlays
	ui.drawLog(gameState.log, 0)
	ui.drawHoverTooltip(gameState)
	ui.drawMultiplayerStatus(gameState)
	
	-- Draw turn indicator
	if gameState.phase == 'combat' then
		local screenH = love.graphics.getHeight()
		love.graphics.setColor(1,1,1,1)
		love.graphics.print('Turn: '..gameState.players[gameState.turn].name, 16, screenH*0.5 - 10)
	end
	
	-- Draw phase transitions and popups (always)
	menus.drawPhaseTransition(gameState)
	menus.drawCoinTossAnimation(gameState)
	menus.drawResolutionPopup(gameState)
end

-- Game start function
function game.startGame()
	local gameState = getState()
	local playerNames = multiplayer.getPlayerNames()
	
	-- Initialize players
	gameState.players = {
		{name=playerNames[1], hand={}, field={nil,nil,nil}, revealed={false,false,false}, deck={}, grave={}},
		{name=playerNames[2], hand={}, field={nil,nil,nil}, revealed={false,false,false}, deck={}, grave={}}
	}
	
	-- Create decks from deck builder data
	for pIndex = 1, 2 do
		local deckData = gameState.playerDecks[pIndex]
		gameState.players[pIndex].deck = deck.createFromDeckData(deckData)
		deck.shuffle(gameState.players[pIndex].deck)
		deck.draw(gameState.players[pIndex], config.GAME.INITIAL_HAND_SIZE)
	end
	
	-- Reset game state
	gameState.turn = 1
	gameState.selectedHandIndex = {nil, nil}
	gameState.pendingAttackSlot = nil
	gameState.roundWins = {0, 0}
	gameState.gameOver = false
	gameState.currentRound = 1
	gameState.setupPassed = {false, false}
	gameState.coinFirst = 1
	gameState.phase = 'setup'  -- Set phase to setup
	
	log('Game start. Draw 5 cards each. Setup phase.')
	log('Both players place cards simultaneously, then coin toss determines first player.')
	
	-- Send initial game state in multiplayer
	if multiplayer.isMultiplayer() then
		multiplayer.sendGameState()
	end
	
	-- Show round start transition
	showPhaseTransition('ROUND '..gameState.currentRound, 2.0)
end

-- Event handlers
function game.mousepressed(x, y, button)
	local gameState = getState()
	
	if button ~= 1 and button ~= 2 then return end
	
	-- Check for Next Round button click first
	if gameState.resolutionPopup.show then
		local btnX = gameState.resolutionPopup.buttonX
		local btnY = gameState.resolutionPopup.buttonY
		local btnW = gameState.resolutionPopup.buttonW
		local btnH = gameState.resolutionPopup.buttonH
		
		if x >= btnX and x <= btnX + btnW and y >= btnY and y <= btnY + btnH then
			game.handleResolutionButtonClick()
			return
		end
	end
	
	if gameState.phase == 'menu' then
		-- Check if in lobby first
		if multiplayer.isInLobby() then
			local lobbyHit = menus.hitLobbyButton(x, y)
			if lobbyHit == 'ready' then
				local currentReady = multiplayer.isMyReady()
				multiplayer.setMyReady(not currentReady)
				log('You are ' .. (not currentReady and 'ready' or 'not ready'))
			elseif lobbyHit == 'start' then
				if multiplayer.startGame() then
					multiplayer.startDeckBuilder()
					-- Set deck builder player based on multiplayer role
					if multiplayer.isMultiplayer() then
						gameState.deckBuilderPlayer = multiplayer.getMyPlayerId()
					end
					gameState.phase = 'deckbuilder'
					log('Starting multiplayer deck builder!')
				end
			elseif lobbyHit == 'cancel' then
				multiplayer.disconnect()
				log('Disconnected from multiplayer game')
			end
			return
		end
		
		local menuInput = menus.getMultiplayerInput()
		if menuInput.showInput then
			-- Handle multiplayer input clicks
			local inputHit = menus.hitMultiplayerInput(x, y)
			if inputHit == 'host_input' then
				menus.setActiveInput('host_input')
			elseif inputHit == 'port_input' then
				menus.setActiveInput('port_input')
			elseif inputHit == 'connect' then
				game.handleMultiplayerConnect()
			elseif inputHit == 'cancel' then
				menus.hideMultiplayerInput()
			end
		else
			-- Handle main menu clicks
			local menuType = menus.hitMenuButton(x, y)
			if menuType == 'deckbuilder' then
				gameState.phase = 'deckbuilder'
			elseif menuType == 'host' then
				menus.showMultiplayerInput('host')
			elseif menuType == 'join' then
				menus.showMultiplayerInput('join')
			end
		end
	elseif gameState.phase == 'deckbuilder' then
		ui.handleDeckBuilderClick(gameState, x, y, button)
	elseif gameState.phase == 'setup' then
		-- Check for Player A pass button
		if ui.hitPassButton(gameState, x, y, 1) then
			-- In setup phase, both players can pass regardless of turn
			-- Turn-based restrictions only apply after setup
			
			gameState.setupPassed[1] = true
			log('Player A passes.')
			
			-- Send action to opponent in multiplayer
			if multiplayer.isMultiplayer() then
				multiplayer.sendAction('pass_setup', {playerIndex = 1})
				-- Sync game state after pass
				multiplayer.sendGameState()
			end
			
			if gameState.setupPassed[1] and gameState.setupPassed[2] then
				-- Both players passed, start coin toss
				setup.startCoinTossAnimation(gameState)
			end
			return
		end
		
		-- Check for Player B pass button
		if ui.hitPassButton(gameState, x, y, 2) then
			-- In setup phase, both players can pass regardless of turn
			-- Turn-based restrictions only apply after setup
			
			gameState.setupPassed[2] = true
			log('Player B passes.')
			
			-- Send action to opponent in multiplayer
			if multiplayer.isMultiplayer() then
				multiplayer.sendAction('pass_setup', {playerIndex = 2})
				-- Sync game state after pass
				multiplayer.sendGameState()
			end
			
			if gameState.setupPassed[1] and gameState.setupPassed[2] then
				-- Both players passed, start coin toss
				setup.startCoinTossAnimation(gameState)
			end
			return
		end
		
		-- Handle card placement for both players
		for playerIndex = 1, 2 do
			local p = gameState.players[playerIndex]
			
		-- In setup phase, both players can place cards
		-- Turn-based restrictions only apply after setup (combat phase)
		if multiplayer.isMultiplayer() and gameState.phase ~= 'setup' and playerIndex ~= multiplayer.getMyPlayerId() then
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
					p.field[slot] = table.remove(p.hand, idx)
					gameState.selectedHandIndex[playerIndex] = nil
					log(p.name..' placed a card face-down at slot '..slot)
					
					-- Send action to opponent in multiplayer
					if multiplayer.isMultiplayer() then
						multiplayer.sendAction('card_placement', {
							playerIndex = playerIndex,
							handIndex = idx,
							slot = slot
						})
						-- Sync game state after card placement
						multiplayer.sendGameState()
					end
					break
				end
			end
			
			::continue::
		end
	elseif gameState.phase == 'combat' then
		-- In multiplayer, only allow actions for current player
		if multiplayer.isMultiplayer() and gameState.turn ~= multiplayer.getMyPlayerId() then
			log('Wait for your turn!')
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
				
				-- Send action to opponent in multiplayer
				if multiplayer.isMultiplayer() then
					multiplayer.sendAction('reveal_card', {
						playerIndex = gameState.turn,
						slot = aSlot
					})
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
				
				-- Send action to opponent in multiplayer
				if multiplayer.isMultiplayer() then
					multiplayer.sendAction('combat_action', {
						attackerSlot = gameState.pendingAttackSlot,
						defenderSlot = dSlot
					})
				end
				
				-- resolve combat
				rules.resolveCombat(attacker, gameState.pendingAttackSlot, defender, dSlot, gameState)
				gameState.pendingAttackSlot = nil
				helpers.nextTurn(gameState)
				
				-- Send game state sync in multiplayer
				if multiplayer.isMultiplayer() then
					multiplayer.sendGameState()
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

function game.handleResolutionButtonClick()
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

function game.keypressed(key)
	local gameState = getState()
	
	if key == 'r' then game.load() end
	
	-- Handle text input for multiplayer
	local menuInput = menus.getMultiplayerInput()
	if menuInput.showInput then
		if key == 'escape' then
			menus.hideMultiplayerInput()
		elseif key == 'return' then
			game.handleMultiplayerConnect()
		else
			menus.addToActiveInput(key)
		end
		return
	end
	
	if gameState.phase == 'deckbuilder' then
		if key == 'escape' then
			if multiplayer.isMultiplayer() then
				-- In multiplayer, go back to lobby
				gameState.phase = 'menu'
				multiplayer.disconnect()
				log('Disconnected from multiplayer game')
			else
				gameState.phase = 'menu'
			end
		elseif key == 'return' then
			if multiplayer.isMultiplayer() then
				-- In multiplayer, check if both decks are ready
				if multiplayer.canStartGameFromDeckBuilder() then
					-- Both decks ready, start game
					-- Deck data is already in gameState.playerDecks from deck builder
					game.startGame()
					log('Starting multiplayer game!')
				else
					-- Check my deck size and set as ready
					local myPlayerId = multiplayer.getMyPlayerId()
					local myCards = 0
					for _, cardData in ipairs(gameState.playerDecks[myPlayerId]) do
						myCards = myCards + cardData.count
					end
					log('My deck size: ' .. myCards)
					log('Required: MIN='..config.GAME.MIN_DECK_SIZE..', MAX='..config.GAME.MAX_DECK_SIZE)
					if myCards >= config.GAME.MIN_DECK_SIZE and myCards <= config.GAME.MAX_DECK_SIZE then
						multiplayer.setMyDeckReady(gameState.playerDecks[myPlayerId])
						log('Deck ready! Waiting for opponent...')
					else
						log('Deck size invalid! Cannot mark as ready.')
					end
				end
			else
				-- Single player, check both deck sizes and start game
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
					game.startGame()
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

function game.wheelmoved(x, y)
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

-- Handle multiplayer connection
function game.handleMultiplayerConnect()
	local menuInput = menus.getMultiplayerInput()
	local host = menuInput.hostInput.text
	local port = tonumber(menuInput.portInput.text) or 12345
	
	if menuInput.inputType == 'host' then
		-- Start hosting
		local success, err = multiplayer.startHost(port)
		if success then
			log('Hosting game on port ' .. port)
			menus.hideMultiplayerInput()
			-- Stay in menu to show lobby
		else
			log('Failed to host: ' .. err)
		end
	elseif menuInput.inputType == 'join' then
		-- Join game
		local success, err = multiplayer.joinGame(host, port)
		if success then
			log('Connected to ' .. host .. ':' .. port)
			menus.hideMultiplayerInput()
			-- Stay in menu to show lobby
		else
			log('Failed to connect: ' .. err)
		end
	end
end

return game
