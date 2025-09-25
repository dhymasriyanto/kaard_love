local deckbuilder = {}
local network = require('src.core.network')

-- Helper functions for deck management
local function getCardCountInDeck(deck, cardName)
	if not deck then return 0 end
	for _, cardData in ipairs(deck) do
		if cardData.card.name == cardName then
			return cardData.count
		end
	end
	return 0
end

local function getMaxCopies(rarity)
	local limits = { C = 3, R = 3, E = 2, L = 1 }
	return limits[rarity] or 1
end

local function addCardToDeck(deck, card)
	local count = getCardCountInDeck(deck, card.name)
	local maxCopies = getMaxCopies(card.rarity)
	if count < maxCopies then
		for _, cardData in ipairs(deck) do
			if cardData.card.name == card.name then
				cardData.count = cardData.count + 1
				return true
			end
		end
		table.insert(deck, { card = card, count = 1 })
		return true
	end
	return false
end

local function removeCardFromDeck(deck, cardName)
	for i, cardData in ipairs(deck) do
		if cardData.card.name == cardName then
			cardData.count = cardData.count - 1
			if cardData.count <= 0 then
				table.remove(deck, i)
			end
			return true
		end
	end
	return false
end

local function generateRandomDeck(allCards, targetCards)
	-- Clear current deck
	local deck = {}
	
	-- Create a weighted pool of cards based on rarity
	local cardPool = {}
	for _, card in ipairs(allCards) do
		local weight = 1
		if card.rarity == 'C' then weight = 4      -- Common: 4x weight
		elseif card.rarity == 'R' then weight = 3  -- Rare: 3x weight  
		elseif card.rarity == 'E' then weight = 2  -- Epic: 2x weight
		elseif card.rarity == 'L' then weight = 1  -- Legendary: 1x weight
		end
		
		for i = 1, weight do
			table.insert(cardPool, card)
		end
	end
	
	-- Generate random deck respecting copy limits
	local totalCardsAdded = 0
	local attempts = 0
	while totalCardsAdded < targetCards and attempts < 1000 do
		attempts = attempts + 1
		local randomCard = cardPool[love.math.random(#cardPool)]
		local currentCount = getCardCountInDeck(deck, randomCard.name)
		local maxCopies = getMaxCopies(randomCard.rarity)
		
		if currentCount < maxCopies then
			addCardToDeck(deck, randomCard)
			totalCardsAdded = totalCardsAdded + 1
		end
	end
	
	-- If we couldn't reach target, fill with any available cards
	if totalCardsAdded < targetCards then
		for _, card in ipairs(allCards) do
			local currentCount = getCardCountInDeck(deck, card.name)
			local maxCopies = getMaxCopies(card.rarity)
			while currentCount < maxCopies and totalCardsAdded < targetCards do
				addCardToDeck(deck, card)
				currentCount = currentCount + 1
				totalCardsAdded = totalCardsAdded + 1
			end
		end
	end
	
	return deck
end

local function generateArchetypeDeck(allCards, archetype, targetCards)
	-- Clear current deck
	local deck = {}
	
	-- Filter cards by archetype
	local archetypeCards = {}
	for _, card in ipairs(allCards) do
		if card.archetype == archetype then
			table.insert(archetypeCards, card)
		end
	end
	
	-- If no cards of this archetype, return empty deck
	if #archetypeCards == 0 then
		return deck
	end
	
	-- Add all available cards of this archetype up to copy limits
	local totalCardsAdded = 0
	for _, card in ipairs(archetypeCards) do
		local maxCopies = getMaxCopies(card.rarity)
		for i = 1, maxCopies do
			if totalCardsAdded < targetCards then
				addCardToDeck(deck, card)
				totalCardsAdded = totalCardsAdded + 1
			end
		end
	end
	
	-- Pure archetype deck - no random additions
	-- If archetype doesn't have enough cards, just return what we have
	return deck
end

function deckbuilder.draw(state, cardBack)
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	
	-- Title
	love.graphics.setColor(1,1,1,1)
	if state.multiplayer then
		local playerName = state.networkPlayerId == 1 and 'Host' or 'Client'
		love.graphics.printf('Deck Builder - ' .. playerName, w*0.5 - 200, 20, 400, 'center')
	else
		love.graphics.printf('Deck Builder - Player '..state.deckBuilderPlayer, w*0.5 - 200, 20, 400, 'center')
	end
	
	-- Player switch buttons (bottom-left corner) - only show in single player mode
	if not state.multiplayer then
		local btnW, btnH = 80, 25
		local btnY = h - btnH - 10
		local p1BtnX = 10
		local p2BtnX = p1BtnX + btnW + 5
		
		-- Player 1 button
		love.graphics.setColor(state.deckBuilderPlayer == 1 and 0.3 or 0.1, 0.3, 0.8, 0.7)
		love.graphics.rectangle('fill', p1BtnX, btnY, btnW, btnH, 4, 4)
		love.graphics.setColor(1,1,1,1)
		love.graphics.printf('Player A', p1BtnX, btnY + 5, btnW, 'center')
		
		-- Player 2 button
		love.graphics.setColor(state.deckBuilderPlayer == 2 and 0.3 or 0.1, 0.3, 0.8, 0.7)
		love.graphics.rectangle('fill', p2BtnX, btnY, btnW, btnH, 4, 4)
		love.graphics.setColor(1,1,1,1)
		love.graphics.printf('Player B', p2BtnX, btnY + 5, btnW, 'center')
	end
	
	-- Deck generation buttons (centered, below title)
	local deckBtnY = 60
	local deckBtnH = 30
	
	-- Calculate button widths based on text length
	local font = love.graphics.getFont()
	local randomText = 'Random'
	local randomBtnW = math.max(80, font:getWidth(randomText) + 20) -- Min 80px, padding 20px
	
	local clearText = 'Clear'
	local clearBtnW = math.max(60, font:getWidth(clearText) + 16) -- Min 60px, padding 16px
	
	local archetypes = {'Undead', 'Spellcaster', 'Druids', 'Knights', 'Mimic', 'Spider'}
	local archetypeBtnW = {}
	local totalWidth = randomBtnW + 10 + clearBtnW + 10 -- Random + Clear + spacing
	
	-- Calculate width for each archetype button
	for i, archetype in ipairs(archetypes) do
		archetypeBtnW[i] = math.max(60, font:getWidth(archetype) + 16) -- Min 60px, padding 16px
		totalWidth = totalWidth + archetypeBtnW[i] + 5 -- Add button width + spacing
	end
	totalWidth = totalWidth - 5 -- Remove last spacing
	
	-- Center all buttons
	local startX = w*0.5 - totalWidth * 0.5
	
	-- Random Deck button
	local randomBtnX = startX
	love.graphics.setColor(0.2, 0.8, 0.2, 0.8)
	love.graphics.rectangle('fill', randomBtnX, deckBtnY, randomBtnW, deckBtnH, 4, 4)
	love.graphics.setColor(1,1,1,1)
	love.graphics.printf(randomText, randomBtnX, deckBtnY + 8, randomBtnW, 'center')
	
	-- Clear Deck button
	local clearBtnX = startX + randomBtnW + 10
	love.graphics.setColor(0.8, 0.2, 0.2, 0.8)
	love.graphics.rectangle('fill', clearBtnX, deckBtnY, clearBtnW, deckBtnH, 4, 4)
	love.graphics.setColor(1,1,1,1)
	love.graphics.printf(clearText, clearBtnX, deckBtnY + 8, clearBtnW, 'center')
	
	-- Archetype Deck buttons (centered with random and clear buttons)
	local archetypeBtnY = deckBtnY
	local currentX = startX + randomBtnW + 10 + clearBtnW + 10
	
	for i, archetype in ipairs(archetypes) do
		local btnX = currentX
		local colors = {
			Undead = {0.3, 0.3, 0.3, 0.8},        -- Dark gray/black
			Spellcaster = {0.1, 0.1, 0.8, 0.8},   -- Blue (keep)
			Druids = {0.1, 0.6, 0.1, 0.8},        -- Green (keep)
			Knights = {0.8, 0.1, 0.1, 0.8},        -- Red
			Mimic = {0.6, 0.4, 0.2, 0.8},         -- Brown
			Spider = {0.6, 0.1, 0.6, 0.8}         -- Purple
		}
		
		love.graphics.setColor(colors[archetype])
		love.graphics.rectangle('fill', btnX, archetypeBtnY, archetypeBtnW[i], deckBtnH, 4, 4)
		love.graphics.setColor(1,1,1,1)
		love.graphics.printf(archetype, btnX, archetypeBtnY + 8, archetypeBtnW[i], 'center')
		
		currentX = currentX + archetypeBtnW[i] + 5 -- Move to next button position
	end
	
	-- Available cards (left side) with scrolling
	love.graphics.setColor(0,0,0,0.3)
	love.graphics.rectangle('fill', 20, 120, w*0.4, h-180, 8, 8)
	love.graphics.setColor(1,1,1,1)
	love.graphics.print('Available Cards', 30, 130)
	
	local cardY = 160 - state.deckBuilderScroll
	-- Get current deck for this player
	local currentDeck
	if state.multiplayer then
		currentDeck = state.playerDecks[state.networkPlayerId] or {}
	else
		currentDeck = state.playerDecks[state.deckBuilderPlayer] or {}
	end
	
	local cardsPerRow = 6
	local cardW, cardH = 70, 110  -- Bigger cards for better visibility
	local cardSpacing = 8
	local archetypeSpacing = 20  -- Extra space between archetypes
	
	love.graphics.setScissor(20, 120, w*0.4, h-180)
	
	-- Group cards by archetype
	local archetypes = {}
	for _, card in ipairs(state.allCards) do
		local archetype = card.archetype or 'Other'
		if not archetypes[archetype] then
			archetypes[archetype] = {}
		end
		table.insert(archetypes[archetype], card)
	end
	
	local currentY = cardY
	for archetypeName, cards in pairs(archetypes) do
		-- Draw archetype header
		love.graphics.setColor(0.8, 0.8, 0.2, 1)
		love.graphics.print(archetypeName, 30, currentY - 15)
		
		-- Draw cards for this archetype
		for i, card in ipairs(cards) do
			local row = math.floor((i-1) / cardsPerRow)
			local col = (i-1) % cardsPerRow
			local x = 30 + col * (cardW + cardSpacing)
			local y = currentY + row * (cardH + cardSpacing)
			
			if y + cardH > 120 and y < h - 20 then
				-- Draw mini card
				love.graphics.setColor(1,1,1,1)
				if card.image then
					local iw, ih = card.image:getWidth(), card.image:getHeight()
					local sx, sy = cardW/iw, cardH/ih
					love.graphics.draw(card.image, x, y, 0, sx, sy)
				else
					love.graphics.setColor(0.5,0.5,0.5,1)
					love.graphics.rectangle('fill', x, y, cardW, cardH, 4, 4)
				end
				love.graphics.setColor(0,0,0,0.5)
				love.graphics.rectangle('line', x, y, cardW, cardH, 4, 4)
				
				-- Count in deck (top right corner)
				local count = getCardCountInDeck(currentDeck, card.name)
				local maxCopies = getMaxCopies(card.rarity)
				love.graphics.setColor(0,0,0,0.8)
				love.graphics.rectangle('fill', x + cardW - 20, y, 20, 12)
				love.graphics.setColor(1,1,1,1)
				love.graphics.printf(count..'/'..maxCopies, x + cardW - 20, y + 1, 20, 'center')
				
				-- Card name inside card at bottom center
				local font = love.graphics.getFont()
				local textHeight = font:getHeight()
				local _, wrappedText = font:getWrap(card.name, cardW)
				local numLines = #wrappedText
				local totalTextHeight = numLines * textHeight
				
				-- Background rectangle covers all lines
				local bgHeight = math.max(12, totalTextHeight + 2)
				local bgY = y + cardH - bgHeight
				love.graphics.setColor(0,0,0,0.8)
				love.graphics.rectangle('fill', x, bgY, cardW, bgHeight)
				
				-- Text positioned so bottom line aligns with card bottom
				local textY = y + cardH - totalTextHeight - 1
				love.graphics.setColor(1,1,1,1)
				love.graphics.printf(card.name, x, textY, cardW, 'center')
			end
		end
		
		-- Move to next archetype (calculate how many rows this archetype used)
		local rowsUsed = math.ceil(#cards / cardsPerRow)
		currentY = currentY + (rowsUsed * (cardH + cardSpacing)) + archetypeSpacing
	end
	love.graphics.setScissor()
	
	-- Current deck (right side) - same size as card selection grid
	local totalCards = 0
	for _, cardData in ipairs(currentDeck) do
		totalCards = totalCards + cardData.count
	end
	
	love.graphics.setColor(0,0,0,0.3)
	love.graphics.rectangle('fill', w*0.45, 120, w*0.5, h-180, 8, 8) -- Same height as card selection grid
	love.graphics.setColor(1,1,1,1)
	love.graphics.print('Current Deck: '..totalCards..'/25 (Min: 15)', w*0.45 + 10, 130) -- Card count in header
	
	local deckY = 160
	for i, cardData in ipairs(currentDeck) do
		local y = deckY + (i-1) * 25
		if y < h - 200 then -- Adjusted for new grid height
			love.graphics.print(cardData.card.name..' x'..cardData.count, w*0.45 + 10, y)
		end
	end
	
	-- Validation messages
	if state.multiplayer then
		-- Multiplayer mode - only check current player's deck
		local currentPlayerId = state.networkPlayerId
		local currentDeck = state.playerDecks[currentPlayerId] or {}
		local currentCards = 0
		for _, cardData in ipairs(currentDeck) do currentCards = currentCards + cardData.count end
		
		local validationMsg = ''
		if currentCards < 15 then 
			validationMsg = 'You need '..(15-currentCards)..' more cards'
		elseif currentCards > 25 then 
			validationMsg = 'You have too many cards ('..currentCards..'/25)'
		else 
			validationMsg = 'Your deck is ready! Press Enter to confirm.'
		end
		
		love.graphics.setColor(validationMsg:find('ready') and 0.2 or 0.8, validationMsg:find('ready') and 0.8 or 0.2, 0.2, 1)
		love.graphics.printf(validationMsg, w*0.5 - 200, h-80, 400, 'center')
		
		-- Show opponent status
		local opponentStatus = 'Waiting for opponent...'
		local opponentColor = {0.8, 0.8, 0.2, 1}
		if state.opponentDeckReady then
			opponentStatus = 'Opponent ready!'
			opponentColor = {0.2, 0.8, 0.2, 1}
		end
		
		love.graphics.setColor(opponentColor)
		love.graphics.printf(opponentStatus, w*0.5 - 200, h-50, 400, 'center')
		
		-- Show waiting popup if waiting for opponent
		if state.waitingForOpponent then
			deckbuilder.drawWaitingPopup(w, h)
		end
	else
		-- Single player mode - check both decks
		local p1Cards = 0
		for _, cardData in ipairs(state.playerDecks[1] or {}) do p1Cards = p1Cards + cardData.count end
		local p2Cards = 0
		for _, cardData in ipairs(state.playerDecks[2] or {}) do p2Cards = p2Cards + cardData.count end
		
		local validationMsg = ''
		if p1Cards < 15 then validationMsg = 'Player A needs '..(15-p1Cards)..' more cards'
		elseif p2Cards < 15 then validationMsg = 'Player B needs '..(15-p2Cards)..' more cards'
		elseif p1Cards > 25 then validationMsg = 'Player A has too many cards ('..p1Cards..'/25)'
		elseif p2Cards > 25 then validationMsg = 'Player B has too many cards ('..p2Cards..'/25)'
		else validationMsg = 'Both decks ready! Press Enter to start.'
		end
		
		love.graphics.setColor(validationMsg:find('ready') and 0.2 or 0.8, validationMsg:find('ready') and 0.8 or 0.2, 0.2, 1)
		love.graphics.printf(validationMsg, w*0.5 - 200, h-50, 400, 'center')
	end
	
	-- Instructions
	love.graphics.setColor(1,1,1,1)
	love.graphics.printf('Left-click: add card. Right-click: remove card. Mouse wheel: scroll. ESC: menu.', w*0.5 - 200, h-30, 400, 'center')
	
	-- Draw card tooltip if hovering over a card
	local hoveredCard = deckbuilder.getHoveredCard(state)
	if hoveredCard then
		deckbuilder.drawCardTooltip(hoveredCard, w, h)
	end
	
	-- Draw notification if active
	if state.notification.timer > 0 then
		deckbuilder.drawNotification(state.notification.text, w, h)
	end
end

function deckbuilder.getHoveredCard(state)
	local mx, my = love.mouse.getPosition()
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	
	-- Check if mouse is in available cards area
	if mx >= 20 and mx <= w*0.4 and my >= 120 and my <= h-60 then
		local cardsPerRow = 6
		local cardW, cardH = 70, 110
		local cardSpacing = 8
		local archetypeSpacing = 20
		local cardY = 160 - state.deckBuilderScroll
		
		-- Group cards by archetype (same logic as drawing)
		local archetypes = {}
		for _, card in ipairs(state.allCards) do
			local archetype = card.archetype or 'Other'
			if not archetypes[archetype] then
				archetypes[archetype] = {}
			end
			table.insert(archetypes[archetype], card)
		end
		
		local currentY = cardY
		for archetypeName, cards in pairs(archetypes) do
			-- Check if hover is in this archetype section
			local rowsUsed = math.ceil(#cards / cardsPerRow)
			local sectionHeight = (rowsUsed * (cardH + cardSpacing)) + archetypeSpacing
			
			if my >= currentY - 15 and my <= currentY + sectionHeight then
				-- Hover is in this archetype section, check individual cards
				for i, card in ipairs(cards) do
					local row = math.floor((i-1) / cardsPerRow)
					local col = (i-1) % cardsPerRow
					local cardX = 30 + col * (cardW + cardSpacing)
					local cardY = currentY + row * (cardH + cardSpacing)
					
					-- Check if hover is within this specific card
					if mx >= cardX and mx <= cardX + cardW and my >= cardY and my <= cardY + cardH then
						return card
					end
				end
			end
			
			currentY = currentY + sectionHeight
		end
	end
	return nil
end

function deckbuilder.drawCardTooltip(card, w, h)
	local tooltipW, tooltipH = 300, 120
	local x = w - tooltipW - 20
	local y = h - tooltipH - 20
	
	love.graphics.setColor(0,0,0,0.85)
	love.graphics.rectangle('fill', x, y, tooltipW, tooltipH, 8, 8)
	love.graphics.setColor(1,1,1,1)
	love.graphics.rectangle('line', x, y, tooltipW, tooltipH, 8, 8)
	
	-- Card name (bright yellow/gold)
	love.graphics.setColor(1, 1, 0.3, 1) -- Bright yellow
	love.graphics.printf(card.name, x + 10, y + 10, tooltipW - 20, 'center')
	
	-- Element and Strength (cyan)
	love.graphics.setColor(0.3, 1, 1, 1) -- Cyan
	love.graphics.printf(card.element..' • STR '..card.strength, x + 10, y + 30, tooltipW - 20, 'center')
	
	-- Ability description (light gray)
	love.graphics.setColor(0.9, 0.9, 0.9, 1) -- Light gray
	love.graphics.printf(card.ability or 'No ability', x + 10, y + 50, tooltipW - 20, 'center')
end

function deckbuilder.drawNotification(text, w, h)
	local notifW, notifH = 400, 50
	local x = (w - notifW) * 0.5
	local y = h * 0.3
	
	love.graphics.setColor(0.8,0.2,0.2,0.9)
	love.graphics.rectangle('fill', x, y, notifW, notifH, 8, 8)
	love.graphics.setColor(1,1,1,1)
	love.graphics.rectangle('line', x, y, notifW, notifH, 8, 8)
	love.graphics.printf(text, x + 10, y + 15, notifW - 20, 'center')
end

function deckbuilder.drawWaitingPopup(w, h)
	local popupW, popupH = 300, 150
	local x = (w - popupW) * 0.5
	local y = (h - popupH) * 0.5
	
	-- Background overlay
	love.graphics.setColor(0, 0, 0, 0.7)
	love.graphics.rectangle('fill', 0, 0, w, h)
	
	-- Popup background
	love.graphics.setColor(0, 0, 0, 0.9)
	love.graphics.rectangle('fill', x, y, popupW, popupH, 12, 12)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.rectangle('line', x, y, popupW, popupH, 12, 12)
	
	-- Title
	love.graphics.setColor(1, 1, 0, 1)
	love.graphics.printf('Waiting for Opponent', x + 10, y + 20, popupW - 20, 'center')
	
	-- Message
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf('Your opponent is still selecting their deck. Please wait...', x + 10, y + 50, popupW - 20, 'center')
	
	-- Animated dots
	local dots = ""
	local time = love.timer.getTime()
	local dotCount = math.floor((time * 2) % 4)
	dots = string.rep(".", dotCount)
	love.graphics.printf(dots, x + 10, y + 80, popupW - 20, 'center')
end

function deckbuilder.handleClick(state, x, y, button)
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	
	-- Check player switch buttons (bottom-left corner) - only in single player mode
	if not state.multiplayer then
		local btnW, btnH = 80, 25
		local btnY = h - btnH - 10
		local p1BtnX = 10
		local p2BtnX = p1BtnX + btnW + 5
		
		if x >= p1BtnX and x <= p1BtnX + btnW and y >= btnY and y <= btnY + btnH then
			state.deckBuilderPlayer = 1
			return
		elseif x >= p2BtnX and x <= p2BtnX + btnW and y >= btnY and y <= btnY + btnH then
			state.deckBuilderPlayer = 2
			return
		end
	end
	
	-- Check deck generation buttons (centered with dynamic widths)
	local deckBtnY = 60
	local deckBtnH = 30
	
	-- Calculate button widths based on text length (same as drawing)
	local font = love.graphics.getFont()
	local randomText = 'Random'
	local randomBtnW = math.max(80, font:getWidth(randomText) + 20)
	
	local clearText = 'Clear'
	local clearBtnW = math.max(60, font:getWidth(clearText) + 16)
	
	local archetypes = {'Undead', 'Spellcaster', 'Druids', 'Knights', 'Mimic', 'Spider'}
	local archetypeBtnW = {}
	local totalWidth = randomBtnW + 10 + clearBtnW + 10
	
	-- Calculate width for each archetype button
	for i, archetype in ipairs(archetypes) do
		archetypeBtnW[i] = math.max(60, font:getWidth(archetype) + 16)
		totalWidth = totalWidth + archetypeBtnW[i] + 5
	end
	totalWidth = totalWidth - 5
	
	-- Center all buttons
	local startX = w*0.5 - totalWidth * 0.5
	
	-- Random Deck button
	local randomBtnX = startX
	if x >= randomBtnX and x <= randomBtnX + randomBtnW and y >= deckBtnY and y <= deckBtnY + deckBtnH then
		-- Generate random deck for current player
		local targetCards = 20 -- Generate 20 cards by default
		local newDeck = generateRandomDeck(state.allCards, targetCards)
		
		if state.multiplayer then
			state.playerDecks[state.networkPlayerId] = newDeck
		else
			state.playerDecks[state.deckBuilderPlayer] = newDeck
		end
		
		-- Count total cards in deck
		local totalCards = 0
		for _, cardData in ipairs(newDeck) do
			totalCards = totalCards + cardData.count
		end
		
		-- Show notification
		state.notification.text = 'Random deck generated with '..totalCards..' cards!'
		state.notification.timer = 2.0
		return
	end
	
	-- Clear Deck button
	local clearBtnX = startX + randomBtnW + 10
	if x >= clearBtnX and x <= clearBtnX + clearBtnW and y >= deckBtnY and y <= deckBtnY + deckBtnH then
		-- Clear current player's deck
		if state.multiplayer then
			state.playerDecks[state.networkPlayerId] = {}
		else
			state.playerDecks[state.deckBuilderPlayer] = {}
		end
		
		-- Show notification
		state.notification.text = 'Deck cleared!'
		state.notification.timer = 1.5
		return
	end
	
	-- Check archetype deck buttons
	local archetypeBtnY = deckBtnY
	local currentX = startX + randomBtnW + 10 + clearBtnW + 10
	
	for i, archetype in ipairs(archetypes) do
		local btnX = currentX
		if x >= btnX and x <= btnX + archetypeBtnW[i] and y >= archetypeBtnY and y <= archetypeBtnY + deckBtnH then
			-- Generate pure archetype deck for current player (15 cards max)
			local targetCards = 15 -- Pure archetype deck with 15 cards
			local newDeck = generateArchetypeDeck(state.allCards, archetype, targetCards)
			
			if state.multiplayer then
				state.playerDecks[state.networkPlayerId] = newDeck
			else
				state.playerDecks[state.deckBuilderPlayer] = newDeck
			end
			
			-- Count total cards in deck
			local totalCards = 0
			for _, cardData in ipairs(newDeck) do
				totalCards = totalCards + cardData.count
			end
			
			-- Show notification
			state.notification.text = archetype..' deck generated with '..totalCards..' cards!'
			state.notification.timer = 2.0
			return
		end
		
		currentX = currentX + archetypeBtnW[i] + 5 -- Move to next button position
	end
	
	-- Check if clicking on available cards (within the actual card grid area)
	if x >= 20 and x <= w*0.4 and y >= 120 and y <= h-60 then
		local cardsPerRow = 6
		local cardW, cardH = 70, 110
		local cardSpacing = 8
		local archetypeSpacing = 20
		local cardY = 160 - state.deckBuilderScroll
		
		-- Group cards by archetype (same logic as drawing)
		local archetypes = {}
		for _, card in ipairs(state.allCards) do
			local archetype = card.archetype or 'Other'
			if not archetypes[archetype] then
				archetypes[archetype] = {}
			end
			table.insert(archetypes[archetype], card)
		end
		
		local currentY = cardY
		for archetypeName, cards in pairs(archetypes) do
			-- Check if click is in this archetype section
			local rowsUsed = math.ceil(#cards / cardsPerRow)
			local sectionHeight = (rowsUsed * (cardH + cardSpacing)) + archetypeSpacing
			
			if y >= currentY - 15 and y <= currentY + sectionHeight then
				-- Click is in this archetype section, check individual cards
				for i, card in ipairs(cards) do
					local row = math.floor((i-1) / cardsPerRow)
					local col = (i-1) % cardsPerRow
					local cardX = 30 + col * (cardW + cardSpacing)
					local cardY = currentY + row * (cardH + cardSpacing)
					
					-- Check if click is within this specific card
					if x >= cardX and x <= cardX + cardW and y >= cardY and y <= cardY + cardH then
						local currentDeck
						if state.multiplayer then
							currentDeck = state.playerDecks[state.networkPlayerId]
						else
							currentDeck = state.playerDecks[state.deckBuilderPlayer]
						end
						
						local currentCount = getCardCountInDeck(currentDeck, card.name)
						local maxCopies = getMaxCopies(card.rarity)
						
						if button == 1 then -- Left click: add
							if currentCount < maxCopies then
								addCardToDeck(currentDeck, card)
							else
								-- Show notification for max limit reached
								state.notification.text = 'Maximum copies reached for '..card.name..' ('..maxCopies..')'
								state.notification.timer = 2.0
							end
						elseif button == 2 then -- Right click: remove
							if currentCount > 0 then
								removeCardFromDeck(currentDeck, card.name)
							end
						end
						return -- Found the clicked card, exit
					end
				end
			end
			
			currentY = currentY + sectionHeight
		end
	end
end

-- Handle deck selection confirmation in multiplayer
function deckbuilder.confirmDeckSelection(state)
	if not state.multiplayer then
		return false
	end
	
	local currentPlayerId = state.networkPlayerId
	local currentDeck = state.playerDecks[currentPlayerId] or {}
	local currentCards = 0
	for _, cardData in ipairs(currentDeck) do currentCards = currentCards + cardData.count end
	
	-- Validate deck
	if currentCards < 15 then
		state.notification.text = 'You need at least 15 cards in your deck!'
		state.notification.timer = 2.0
		return false
	elseif currentCards > 25 then
		state.notification.text = 'You have too many cards ('..currentCards..'/25)!'
		state.notification.timer = 2.0
		return false
	end
	
	-- Mark deck as selected
	state.deckSelectionComplete[currentPlayerId] = true
	
	-- Send deck to opponent
	local deckParts = {}
	for _, cardData in ipairs(currentDeck) do
		if cardData.name and cardData.count then
			table.insert(deckParts, cardData.name .. ":" .. cardData.count)
		end
	end
	local deckData = table.concat(deckParts, "|")
	network.sendMessage("DECK_SELECTED:" .. deckData)
	
	-- Check if both players are ready
	if state.deckSelectionComplete[1] and state.deckSelectionComplete[2] then
		-- Both players ready, start game
		state.phase = 'setup'
		state.waitingForOpponent = false
		-- Initialize game state
		local game = require('src.core.game')
		game.startGame()
		return true
	else
		-- Wait for opponent
		state.waitingForOpponent = true
		state.notification.text = 'Deck confirmed! Waiting for opponent...'
		state.notification.timer = 2.0
		return false
	end
end

-- Handle opponent deck received
function deckbuilder.handleOpponentDeck(state, deckData)
	if not state.multiplayer then
		return
	end
	
	local opponentId = state.networkPlayerId == 1 and 2 or 1
	state.playerDecks[opponentId] = deckData
	state.deckSelectionComplete[opponentId] = true
	state.opponentDeckReady = true
	
	-- Check if both players are ready
	if state.deckSelectionComplete[1] and state.deckSelectionComplete[2] then
		-- Both players ready, start game
		state.phase = 'setup'
		state.waitingForOpponent = false
		state.notification.text = 'Both players ready! Starting game...'
		state.notification.timer = 2.0
	end
end

return deckbuilder
