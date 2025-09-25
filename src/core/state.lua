local state = {}

-- Game state management
local gameState = {
	phase = 'loading', -- loading, menu, deckbuilder, setup, combat, resolution
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
	multiplayer = { isMultiplayer = false }
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
		multiplayer = { isMultiplayer = false }
	}
end

return state
