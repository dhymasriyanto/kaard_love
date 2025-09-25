local state = {}

-- Game state management
local gameState = {
	phase = 'loading', -- loading, menu, lobby, deckbuilder, setup, combat, resolution
	players = {},
	turn = 1,
	selectedHandIndex = {nil, nil},
	pendingAttackSlot = nil,
	log = {},
	roundWins = {0, 0},
	gameOver = false,
	currentRound = 1,
	phaseTransition = { show = false, text = '', timer = 0 },
	resolutionPopup = { show = false, data = {}, timer = 0 },
	coinTossAnimation = { show = false, timer = 0, result = 0 },
	setupPassed = {false, false},
	passButtonA = nil,
	passButtonB = nil,
	coinFirst = 1,
	deckBuilderPlayer = 1,
	playerDecks = {{}, {}},
	allCards = {},
	deckBuilderScroll = 0,
	notification = { text = '', timer = 0 },
	flipSound = nil,
	background = nil,
	-- Multiplayer state
	multiplayer = false,
	networkPlayerId = 1, -- 1 for host, 2 for client
	opponentDeckReady = false,
	deckSelectionComplete = {false, false}, -- Track if each player has selected their deck
	waitingForOpponent = false,
	opponentCards = {}, -- Store opponent's cards (unrevealed)
	network = nil -- Will be set to network module
}

function state.get()
	return gameState
end

function state.set(newState)
	gameState = newState
end

function state.reset()
	gameState = {
		phase = 'loading',
		players = {},
		turn = 1,
		selectedHandIndex = {nil, nil},
		pendingAttackSlot = nil,
		log = {},
		roundWins = {0, 0},
		gameOver = false,
		currentRound = 1,
		phaseTransition = { show = false, text = '', timer = 0 },
		resolutionPopup = { show = false, data = {}, timer = 0 },
		coinTossAnimation = { show = false, timer = 0, result = 0 },
		setupPassed = {false, false},
		passButtonA = nil,
		passButtonB = nil,
		coinFirst = 1,
		deckBuilderPlayer = 1,
		playerDecks = {{}, {}},
		allCards = {},
		deckBuilderScroll = 0,
		notification = { text = '', timer = 0 },
		flipSound = nil,
		background = nil,
		-- Multiplayer state
		multiplayer = false,
		networkPlayerId = 1,
		opponentDeckReady = false,
		deckSelectionComplete = {false, false},
		waitingForOpponent = false,
		opponentCards = {},
		network = gameState.network -- Preserve network module reference
	}
end

return state
