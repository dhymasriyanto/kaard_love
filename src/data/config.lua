local config = {}

-- Game configuration constants
config.GAME = {
	MIN_DECK_SIZE = 15,
	MAX_DECK_SIZE = 25,
	INITIAL_HAND_SIZE = 5,
	DRAW_PER_ROUND = 2,
	MAX_ROUNDS = 3,
	FIELD_SLOTS = 3
}

config.CARD_LIMITS = {
	C = 3, -- Common
	R = 3, -- Rare
	E = 2, -- Epic
	L = 1  -- Legendary
}

config.UI = {
	SLOT_WIDTH = 96,
	SLOT_HEIGHT = 140,
	MARGIN = 20,
	HAND_SPACING = 108 -- slotW + 12
}

config.ANIMATION = {
	PHASE_TRANSITION_DURATION = 2.0,
	COIN_TOSS_DURATION = 1.0,
	RESOLUTION_POPUP_DURATION = 4.0,
	NOTIFICATION_DURATION = 2.0
}

return config
