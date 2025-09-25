local game = {}

-- Cache for card back image to avoid reloading every frame
local cardBackCache = nil

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
	
	-- Initialize network module
	local network = require('src.core.network')
	gameState.network = network
	
	-- Initialize lobby
	lobby.init()
	
	gameState.phase = 'menu'
	log('Game loaded successfully!')
end

function game.update(dt)
	local gameState = getState()
	
	-- Update lobby
	if gameState.phase == 'lobby' then
		lobby.update(dt)
	end
	
	-- Update deckbuilder
	if gameState.phase == 'deckbuilder' then
		deckbuilder.update(dt, gameState)
	end
	
	-- Process network messages in multiplayer mode
	if gameState.multiplayer and gameState.network then
		local messages = gameState.network.getMessages()
		if #messages > 0 then
			print('Processing ' .. #messages .. ' network messages')
		end
		for _, message in ipairs(messages) do
			local decodedMessage = gameState.network.decodeMessage(message)
			if decodedMessage then
				print('Handling network message: ' .. decodedMessage.type)
				game.handleNetworkMessage(decodedMessage, gameState)
			end
		end
	end
	
	-- Delegate animation updates to animations module
	animations.update(dt)
	
	-- Periodic garbage collection to prevent memory leaks
	-- Only run every 5 seconds to avoid performance impact
	if not gameState.lastGC then
		gameState.lastGC = 0
	end
	gameState.lastGC = gameState.lastGC + dt
	if gameState.lastGC >= 5.0 then
		collectgarbage("collect")
		gameState.lastGC = 0
	end
end

function game.draw()
	local gameState = getState()
	
	-- Use cached card back to avoid reloading every frame
	if not cardBackCache then
		cardBackCache = loader.loadCardBack()
	end
	local cardBack = cardBackCache
	
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
	log('Game.startGame() called - Phase: ' .. gameState.phase)
	print('🚀 GAME.STARTGAME() CALLED! Phase: ' .. gameState.phase)
	print('🚀 DEBUG: Multiplayer=' .. tostring(gameState.multiplayer))
	print('🚀 DEBUG: NetworkPlayerId=' .. tostring(gameState.networkPlayerId))
	
	-- Initialize players
	if gameState.multiplayer and gameState.network and gameState.network.isMultiplayer() then
		-- In multiplayer, use multiplayer player IDs
		local myPlayerId = gameState.network.getPlayerId()
		local hostName = myPlayerId == 1 and 'Host' or 'Client'
		local clientName = myPlayerId == 1 and 'Client' or 'Host'
		gameState.players = {
			{name=hostName, hand={}, field={nil,nil,nil}, revealed={false,false,false}, deck={}, grave={}},
			{name=clientName, hand={}, field={nil,nil,nil}, revealed={false,false,false}, deck={}, grave={}}
		}
		gameState.networkPlayerId = myPlayerId
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
	gameState.deckConfirmed = {false, false}  -- Track deck confirmation for multiplayer
	gameState.phase = 'setup'  -- Set phase to setup
	
	log('Game start. Draw 5 cards each. Setup phase.')
	log('Both players place cards simultaneously, then coin toss determines first player.')
	
	print('🚀 PHASE CHANGED TO: ' .. gameState.phase)
	print('🚀 DEBUG: Phase transition should show now')
	
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
		print('📨 Received PLAYER_DECK_SELECTED message, calling handleOpponentDeck...')
		deckbuilder.handleOpponentDeck(gameState, message.data.deck)
		
		-- Mark opponent as confirmed
		local opponentId = (gameState.networkPlayerId == 1) and 2 or 1
		gameState.deckConfirmed[opponentId] = true
		print('✅ Opponent ' .. opponentId .. ' deck confirmed')
		print('🔍 DEBUG: deckConfirmed[1]=' .. tostring(gameState.deckConfirmed[1]) .. ', deckConfirmed[2]=' .. tostring(gameState.deckConfirmed[2]))
		
		-- Check if both players are ready
		if gameState.deckConfirmed[1] and gameState.deckConfirmed[2] then
			print('🎮 BOTH PLAYERS CONFIRMED! Starting game from network message...')
			game.startGame()
		end
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
	
	-- Handle lobby keyboard input
	if gameState.phase == 'lobby' then
		local lobby = require('src.ui.lobby')
		if lobby.handleKeyInput(key) then
			return
		end
	end
	
	events.keypressed(key)
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
