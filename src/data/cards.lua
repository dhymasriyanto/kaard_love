local cards = {}

-- Card data management
local allCards = {}

function cards.setAllCards(cards)
	allCards = cards
end

function cards.getAllCards()
	return allCards
end

return cards
