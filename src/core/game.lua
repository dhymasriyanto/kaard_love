local game = {}

-- Import all modules
local loader = require('src.utils.loader')
local ui = require('src.ui.ui')
local menus = require('src.ui.menus')

-- Game modules
local setup = require('src.game.setup')
local deck = require('src.game.deck')

-- Core modules
local state = require('src.core.state')
local events = require('src.core.events')
local animations = require('src.core.animations')

-- UI modules
local lobby = require('src.ui.lobby')
local deckbuilder = require('src.ui.deckbuilder')
local network = require('src.core.network')

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

-- Phase transition functions (delegated to animations module)
local function showPhaseTransition(text, duration)
	animations.showPhaseTransition(text, duration)
end

local function showResolutionPopup(data, duration)
	animations.showResolutionPopup(data, duration)
end

-- Game initialization
function game.load()
	local gameState = getState()
	gameState.phase = 'loading'
	gameState.allCards = loader.loadCards('docs/list_card.csv')
	gameState.flipSound = loader.loadSound('assets/sounds/flip.wav')
	gameState.background = loader.loadBackground()
	gameState.deckSelectionComplete = {false, false}
	gameState.waitingForOpponent = false
	
	-- Initialize lobby
	lobby.init()
	
	gameState.phase = 'menu'
	log('Game loaded successfully!')
end

function game.update(dt)
	local gameState = getState()
	
	-- Update network once per frame for all phases
	if gameState.multiplayer then
		network.update(dt)
	end
	
	-- Update lobby
	if gameState.phase == 'lobby' then
		lobby.update(dt)
	end
	
	-- Handle network messages in deckbuilder (with rate limiting)
	if gameState.phase == 'deckbuilder' and gameState.multiplayer then
		local messages = network.getMessages()
		-- Process max 3 messages per frame to prevent lag in multiplayer
		local maxMessages = math.min(3, #messages)
		for i = 1, maxMessages do
			game.handleNetworkMessage(messages[i])
		end
	end
	
	-- Delegate animation updates to animations module
	animations.update(dt)
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
	elseif gameState.phase == 'lobby' then
		lobby.draw(gameState)
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
	
	-- Initialize players
	if gameState.multiplayer then
		-- In multiplayer, use network player IDs
		local myPlayerId = gameState.networkPlayerId
		local hostName = myPlayerId == 1 and 'Host' or 'Client'
		local clientName = myPlayerId == 1 and 'Client' or 'Host'
		gameState.players = {
			{name=hostName, hand={}, field={nil,nil,nil}, revealed={false,false,false}, deck={}, grave={}},
			{name=clientName, hand={}, field={nil,nil,nil}, revealed={false,false,false}, deck={}, grave={}}
		}
	else
		gameState.players = {
			{name='Player A', hand={}, field={nil,nil,nil}, revealed={false,false,false}, deck={}, grave={}},
			{name='Player B', hand={}, field={nil,nil,nil}, revealed={false,false,false}, deck={}, grave={}}
		}
	end
	
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
	
	-- Show round start transition
	showPhaseTransition('ROUND '..gameState.currentRound, 2.0)
end

-- Handle network messages (delegated to multiplayer module)
function game.handleNetworkMessage(message, gameState)
	if message.type == network.MESSAGE_TYPES.PLAYER_READY then
		-- Handle player ready status
		local lobby = require('src.ui.lobby')
		lobby.handleNetworkMessage(message, gameState)
	elseif message.type == network.MESSAGE_TYPES.PLAYER_DECK_SELECTED then
		deckbuilder.handleOpponentDeck(gameState, message.data.deck)
	elseif message.type == network.MESSAGE_TYPES.GAME_START then
		-- Host started the game, transition to deck builder
		gameState.phase = 'deckbuilder'
		gameState.multiplayer = true
		gameState.networkPlayerId = gameState.network.getPlayerId()
	elseif message.type == network.MESSAGE_TYPES.CARD_PLACED then
		-- Handle card placement from opponent
		local playerId = message.data.playerId
		local slotIndex = message.data.slotIndex
		local cardData = message.data.card
		
		if gameState.players[playerId] and gameState.players[playerId].field[slotIndex] == nil then
			gameState.players[playerId].field[slotIndex] = cardData
			-- Remove card from opponent's hand
			for i, handCard in ipairs(gameState.players[playerId].hand) do
				if handCard.name == cardData.name then
					table.remove(gameState.players[playerId].hand, i)
					break
				end
			end
		end
	elseif message.type == network.MESSAGE_TYPES.CARD_REVEALED then
		-- Handle card reveal from opponent
		local playerId = message.data.playerId
		local slotIndex = message.data.slotIndex
		
		if gameState.players[playerId] and gameState.players[playerId].field[slotIndex] then
			gameState.players[playerId].revealed[slotIndex] = true
		end
	elseif message.type == network.MESSAGE_TYPES.SETUP_PASSED then
		-- Handle setup phase pass from opponent
		local playerId = message.data.playerId
		gameState.setupPassed[playerId] = true
		
		-- Check if both players passed
		if gameState.setupPassed[1] and gameState.setupPassed[2] then
			-- Start coin toss
			setup.startCoinTossAnimation(gameState)
		end
	elseif message.type == network.MESSAGE_TYPES.TURN_CHANGED then
		-- Handle turn change from opponent
		gameState.turn = message.data.turn
	elseif message.type == network.MESSAGE_TYPES.GAME_STATE_SYNC then
		-- Handle game state synchronization
		local syncState = message.data.state
		-- Update relevant parts of game state
		gameState.players = syncState.players or gameState.players
		gameState.turn = syncState.turn or gameState.turn
		gameState.setupPassed = syncState.setupPassed or gameState.setupPassed
	elseif message.type == network.MESSAGE_TYPES.COIN_TOSS_RESULT then
		-- Handle coin toss result from host
		gameState.coinFirst = message.data.result
		gameState.turn = gameState.coinFirst
		gameState.coinTossAnimation.result = message.data.result
		log('Coin toss result: ' .. (gameState.coinFirst == 1 and 'Host' or 'Client') .. ' goes first')
	end
end

-- Event handlers (delegated to events module)
function game.mousepressed(x, y, button)
	local gameState = getState()
	
	-- Handle lobby clicks
	if gameState.phase == 'lobby' then
		lobby.handleClick(x, y, button, gameState)
		return
	end
	
	events.mousepressed(x, y, button)
end

function game.handleResolutionButtonClick()
	return events.handleResolutionButtonClick()
end

function game.keypressed(key)
	local gameState = getState()
	
	-- Debug key presses (reduced for performance)
	-- if key == 'return' then
	--	print("Return key pressed! Phase:", gameState.phase, "Multiplayer:", gameState.multiplayer)
	-- end
	
	-- Handle lobby keyboard input
	if gameState.phase == 'lobby' then
		local lobby = require('src.ui.lobby')
		if lobby.handleKeyInput(key) then
			return
		end
	end
	
	-- Handle deck builder Enter key in multiplayer
	if gameState.phase == 'deckbuilder' and gameState.multiplayer and key == 'return' then
		deckbuilder.confirmDeckSelection(gameState)
		return
	end
	
	events.keypressed(key)
end

function game.handleNetworkMessage(message)
	local gameState = getState()
	
	if message:match("^DECK_SELECTED:") then
		local deckData = message:match("DECK_SELECTED:(.+)")
		local opponentId = gameState.networkPlayerId == 1 and 2 or 1
		
		-- Parse deck data
		local opponentDeck = {}
		for cardStr in deckData:gmatch("[^|]+") do
			local name, count = cardStr:match("([^:]+):(%d+)")
			if name and count then
				table.insert(opponentDeck, {name = name, count = tonumber(count)})
			end
		end
		
		-- Store opponent deck
		gameState.playerDecks[opponentId] = opponentDeck
		gameState.deckSelectionComplete[opponentId] = true
		
		print("Received opponent deck with", #opponentDeck, "card types")
		
		-- Check if both players are ready
		if gameState.deckSelectionComplete[1] and gameState.deckSelectionComplete[2] then
			gameState.phase = 'setup'
			gameState.waitingForOpponent = false
			print("Both players ready! Starting setup phase...")
			-- Initialize game state
			game.startGame()
		end
	end
end

function game.wheelmoved(x, y)
	events.wheelmoved(x, y)
end

function game.textinput(text)
	local gameState = getState()
	
	-- Handle lobby text input
	if gameState.phase == 'lobby' then
		local lobby = require('src.ui.lobby')
		if lobby.handleTextInput(text) then
			return
		end
	end
end

return game
