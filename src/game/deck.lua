local deck = {}

function deck.shuffle(t)
	for i = #t, 2, -1 do
		local j = love.math.random(i)
		t[i], t[j] = t[j], t[i]
	end
end

function deck.draw(player, count)
	count = count or 1
	for i = 1, count do
		if #player.deck > 0 then
			local card = table.remove(player.deck, 1)
			table.insert(player.hand, card)
		end
	end
end

function deck.createFromDeckData(deckData)
	local deck = {}
	for _, cardData in ipairs(deckData) do
		for i = 1, cardData.count do
			table.insert(deck, cardData.card)
		end
	end
	return deck
end

return deck
