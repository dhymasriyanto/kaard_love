local ui = {}

local slotW, slotH = 96, 140
local margin = 20
local handSpacing = nil -- set after slotW
handSpacing = slotW + 12 -- no overlap; clear separation
local passBtn = { x = 0, y = 0, w = 120, h = 40 }

local function playerOrigin(playerIndex)
	local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
	local y
	if playerIndex == 1 then
		-- Place Player A field above their bottom hand and GY (mirror of Player B)
		y = screenH - slotH - 8 - slotH - 28
	else
		-- Place Player B field below their top hand and GY
		y = 8 + slotH + 28
	end
	return screenW*0.5 - (1.5*slotW + margin), y
end

local function handOrigin(playerIndex, count)
	local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
	local y = playerIndex==1 and (screenH - slotH - 8) or 8
	local visible = math.min(math.max(count, 1), 12)
	local totalW = (visible-1) * handSpacing + slotW
	local x = (screenW - totalW) * 0.5
	return x, y
end

function ui.drawCard(card, x, y, revealed, cardBack)
	love.graphics.setColor(1,1,1,1)
	if revealed and card.image then
		local iw, ih = card.image:getWidth(), card.image:getHeight()
		local sx, sy = slotW/iw, slotH/ih
		love.graphics.draw(card.image, x, y, 0, sx, sy)
	else
		local iw, ih = cardBack:getWidth(), cardBack:getHeight()
		local sx, sy = slotW/iw, slotH/ih
		love.graphics.draw(cardBack, x, y, 0, sx, sy)
	end
	-- frame
	love.graphics.setColor(0,0,0,0.5)
	love.graphics.rectangle('line', x, y, slotW, slotH, 8, 8)
end

function ui.drawBoard(state, cardBack)
	for pIndex=1,2 do
		local ox, oy = playerOrigin(pIndex)
		for i=1,3 do
			local x = ox + (i-1)*(slotW+margin)
			local y = oy
			local p = state.players[pIndex]
			if p.field[i] then
				ui.drawCard(p.field[i], x, y, p.revealed[i], cardBack)
				-- Show current strength on revealed cards (large, clear display)
				if p.revealed[i] then
					local card = p.field[i]
					local str = card.strength or card.baseStrength or 0
					love.graphics.setColor(0,0,0,0.9)
					love.graphics.rectangle('fill', x + slotW - 40, y + 5, 35, 25)
					love.graphics.setColor(1,1,1,1)
					love.graphics.printf(tostring(str), x + slotW - 40, y + 8, 35, 'center')
				end
			else
				love.graphics.setColor(1,1,1,0.15)
				love.graphics.rectangle('line', x, y, slotW, slotH, 8, 8)
			end
			-- indicator for current player's pending attack slot
			if state.phase=='combat' and pIndex==state.turn and state.pendingAttackSlot==i then
				love.graphics.setColor(1,1,0,0.7)
				love.graphics.rectangle('line', x-3, y-3, slotW+6, slotH+6, 10, 10)
			end
            -- setup placement glow (for both players)
            if state.phase=='setup' and state.selectedHandIndex[pIndex] then
                local mx, my = love.mouse.getPosition()
                if mx>=x and mx<=x+slotW and my>=y and my<=y+slotH and p.field[i]==nil then
                    love.graphics.setColor(1,1,0,0.25)
                    love.graphics.rectangle('fill', x, y, slotW, slotH, 10, 10)
                    love.graphics.setColor(1,1,0,0.8)
                    love.graphics.rectangle('line', x-2, y-2, slotW+4, slotH+4, 10, 10)
                end
            end
		end
	end
	
	-- Draw Best of 3 victory indicators
	drawVictoryIndicators(state)
	
	if state.phase=='combat' then
		love.graphics.setColor(1,1,1,1)
		local hint = state.pendingAttackSlot and 'Choose opponent card' or 'Choose your card to attack'
		local screenH = love.graphics.getHeight()
		love.graphics.print(hint, 16, screenH*0.5 + 10)
	end
end

function ui.drawHands(state, cardBack)
	for pIndex=1,2 do
		local p = state.players[pIndex]
		local x, y = handOrigin(pIndex, #p.hand)
		
		-- Show hand cards based on phase:
		-- - Setup phase: show all cards face-up for both players
		-- - Combat phase: current player shows actual cards, opponent shows face-down
		local showActualCards = (state.phase == 'setup') or (pIndex == state.turn)
		
		for i=1,#p.hand do
			local cx = x + (i-1)*handSpacing
			local cy = y
			-- draw slot box to visually separate
			love.graphics.setColor(1,1,1,0.15)
			love.graphics.rectangle('line', cx, cy, slotW, slotH, 8, 8)
			local card = p.hand[i]
			if card then
				-- Animation for selected cards during setup phase (both players)
				if state.phase=='setup' and state.selectedHandIndex[pIndex]==i then
					local t = love.timer.getTime()
					if pIndex == 1 then
						-- Player A (bottom): animate upward
						cy = cy - 8 - math.sin(t*8)*2
					else
						-- Player B (top): animate downward
						cy = cy + 8 + math.sin(t*8)*2
					end
				end
				
				if showActualCards then
					-- Show actual card (current player or setup phase)
					ui.drawCard(card, cx, cy, true, cardBack)
				else
					-- Show card back (opponent's hand during their turn)
					ui.drawCard(card, cx, cy, false, cardBack)
				end
			end
		end
		love.graphics.setColor(1,1,1,1)
		local selected = state.selectedHandIndex[pIndex]
		local info = p.name..' Hand: '..#p.hand
		if state.phase=='setup' then
			info = info .. (selected and ('  Selected: '..(p.hand[selected] and p.hand[selected].name or '')) or '  (click hand to select)')
		end
		-- Position text above cards for both players
		local textY = pIndex == 1 and (y - 20) or (y + slotH + 6)
		love.graphics.print(info, x, textY)
	end
end

local function drawPileLabel(text, x, y)
	-- Draw count inside the card instead of below it (even wider to prevent wrapping)
	love.graphics.setColor(0,0,0,0.8)
	love.graphics.rectangle('fill', x + slotW - 60, y + slotH - 20, 60, 20)
	love.graphics.setColor(1,1,1,1)
	love.graphics.printf(text, x + slotW - 60, y + slotH - 18, 60, 'center')
end

function drawVictoryIndicators(state)
	if not state.roundWins then return end
	
	-- Don't draw during resolution popup to avoid flickering
	if state.resolutionPopup and state.resolutionPopup.show then return end
	
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	local circleSize = 16
	local spacing = 25
	
	-- Position indicators near turn info (left-center area)
	local centerX = 20
	local centerY = h * 0.5
	
	-- Player B indicators (above turn info)
	local p2X = centerX
	local p2Y = centerY - 40
	
	-- Player A indicators (below combat hint)
	local p1X = centerX
	local p1Y = centerY + 40
	
	-- Draw Player B indicators (top)
	for i = 1, 3 do
		local x = p2X + (i-1) * spacing
		local y = p2Y
		local wins = state.roundWins[2] or 0
		
		if i <= wins then
			love.graphics.setColor(0.2, 0.8, 0.2, 1) -- Green for wins
		else
			love.graphics.setColor(0.3, 0.3, 0.3, 1) -- Gray for not won
		end
		love.graphics.circle('fill', x, y, circleSize/2)
		love.graphics.setColor(1,1,1,1)
		love.graphics.circle('line', x, y, circleSize/2)
	end
	
	-- Draw Player A indicators (bottom)
	for i = 1, 3 do
		local x = p1X + (i-1) * spacing
		local y = p1Y
		local wins = state.roundWins[1] or 0
		
		if i <= wins then
			love.graphics.setColor(0.2, 0.8, 0.2, 1) -- Green for wins
		else
			love.graphics.setColor(0.3, 0.3, 0.3, 1) -- Gray for not won
		end
		love.graphics.circle('fill', x, y, circleSize/2)
		love.graphics.setColor(1,1,1,1)
		love.graphics.circle('line', x, y, circleSize/2)
	end
end

local function drawDeckAndGY(state, cardBack)
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	-- Player A POV: bottom-right deck, above it GY
	local pA = state.players[1]
	local deckAx = w - slotW - 12
	local deckAy = h - slotH - 12
	ui.drawCard({image=nil}, deckAx, deckAy, false, cardBack)
	drawPileLabel('Deck: '..#pA.deck, deckAx, deckAy)
	local gyAx = deckAx
	local gyAy = deckAy - slotH - 8
	local topA = pA.grave[#pA.grave]
	if topA then ui.drawCard(topA, gyAx, gyAy, true, cardBack) else
		love.graphics.setColor(1,1,1,0.15); love.graphics.rectangle('line', gyAx, gyAy, slotW, slotH, 8, 8)
	end
	drawPileLabel('GY: '..#pA.grave, gyAx, gyAy)

	-- Player B POV: top-left deck, below it GY
	local pB = state.players[2]
	local deckBx = 12
	local deckBy = 12
	ui.drawCard({image=nil}, deckBx, deckBy, false, cardBack)
	drawPileLabel('Deck: '..#pB.deck, deckBx, deckBy)
	local gyBx = deckBx
	local gyBy = deckBy + slotH + 8
	local topB = pB.grave[#pB.grave]
	if topB then ui.drawCard(topB, gyBx, gyBy, true, cardBack) else
		love.graphics.setColor(1,1,1,0.15); love.graphics.rectangle('line', gyBx, gyBy, slotW, slotH, 8, 8)
	end
	drawPileLabel('GY: '..#pB.grave, gyBx, gyBy)
end

function ui.hitHand(state, player, x, y)
    local pIndex = (player.name == 'Player A') and 1 or 2
    local xLeft, baseY = handOrigin(pIndex, #player.hand)
    -- expand vertical range a bit to include raised animation
    local yTop = baseY - 14
    local yBottom = baseY + slotH
    if y < yTop or y > yBottom then return nil end
    for i=1,#player.hand do
        local x1 = xLeft + (i-1)*handSpacing
        local y1 = baseY
        if state.phase=='setup' and pIndex==state.turn and state.selectedHandIndex[pIndex]==i then
            local t = love.timer.getTime()
            y1 = y1 - 8 - math.sin(t*8)*2
        end
        if x >= x1 and x <= x1 + slotW and y >= y1-4 and y <= y1 + slotH then
            return i
        end
    end
    return nil
end

function ui.hitFieldSlot(playerIndex, x, y)
	local ox, oy = playerOrigin(playerIndex)
	for i=1,3 do
		local sx = ox + (i-1)*(slotW+margin)
		if x>=sx and x<=sx+slotW and y>=oy and y<=oy+slotH then return i end
	end
	return nil
end

local LOG_BOX = { w = 240, h = 160, x = 0, y = 0, lineH = 16, padding = 8, headerH = 22 }

function ui.getLogMaxLines()
    return math.floor((LOG_BOX.h - LOG_BOX.headerH - LOG_BOX.padding) / LOG_BOX.lineH)
end

function ui.isMouseInLogBox()
    local boxW, boxH = LOG_BOX.w, LOG_BOX.h
    local x = love.graphics.getWidth() - boxW - 8
    local y = 8
    local mx, my = love.mouse.getPosition()
    return mx>=x and mx<=x+boxW and my>=y and my<=y+boxH
end

function ui.drawLog(logs, scroll)
    local boxW, boxH = LOG_BOX.w, LOG_BOX.h
    local x = love.graphics.getWidth() - boxW - 8
    local y = 8
    love.graphics.setColor(0,0,0,0.8)
    love.graphics.rectangle('fill', x, y, boxW, boxH, 8, 8)
    love.graphics.setColor(1,1,1,1)
    love.graphics.rectangle('line', x, y, boxW, boxH, 8, 8)
    love.graphics.print('Current Event:', x+8, y+6)
    
    local textX, textY = x + LOG_BOX.padding, y + LOG_BOX.headerH
    local textW = boxW - LOG_BOX.padding*2

    -- Show only the most recent event (single entry)
    if #logs > 0 then
        local currentEvent = logs[#logs]
        
        -- Color code the current event
        if currentEvent:find('wins') or currentEvent:find('Round result') then
            love.graphics.setColor(0.2, 0.8, 0.2, 1) -- Green for wins/results
        elseif currentEvent:find('reveals') or currentEvent:find('placed') then
            love.graphics.setColor(0.8, 0.8, 0.2, 1) -- Yellow for actions
        elseif currentEvent:find('discards') or currentEvent:find('loses') then
            love.graphics.setColor(0.8, 0.2, 0.2, 1) -- Red for losses/discards
        elseif currentEvent:find('Flip:') or currentEvent:find('ability') or currentEvent:find('STR') or currentEvent:find('→') then
            love.graphics.setColor(0.2, 0.8, 0.8, 1) -- Cyan for ability effects
        elseif currentEvent:find('used') or currentEvent:find('negated') then
            love.graphics.setColor(0.8, 0.2, 0.8, 1) -- Spellcasternta for special effects
        else
            love.graphics.setColor(1, 1, 1, 1) -- White for general messages
        end
        
        -- Draw the current event with proper wrapping
        love.graphics.printf(currentEvent, textX, textY, textW, 'left')
    else
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        love.graphics.print('No events yet...', textX, textY)
    end
end

local function getHoverCard(state)
    local mx, my = love.mouse.getPosition()
    -- hands first (only current player's hand)
    local p = state.players[state.turn]
    local xLeft, yTop = handOrigin(state.turn, #p.hand)
    for i=1,#p.hand do
        local x1 = xLeft + (i-1)*handSpacing
        if mx>=x1 and mx<=x1+slotW and my>=yTop and my<=yTop+slotH then
            return p.hand[i]
        end
    end
    -- fields (revealed cards for all players, face-down cards only for current player)
    for pIndex=1,2 do
        local p = state.players[pIndex]
        local ox, oy = playerOrigin(pIndex)
        for i=1,3 do
            local x = ox + (i-1)*(slotW+margin)
            local y = oy
            if mx>=x and mx<=x+slotW and my>=y and my<=y+slotH then
                local c = p.field[i]
                if c then
                    -- Show revealed cards for all players
                    if p.revealed[i] then return c end
                    -- Show face-down cards only for current player
                    if not p.revealed[i] and pIndex == state.turn then return c end
                end
            end
        end
    end
    return nil
end

function ui.drawHoverTooltip(state)
    local card = getHoverCard(state)
    if not card then return end
    local screenH = love.graphics.getHeight()
    local x
    local w, h = 360, 110
    -- place just above Player A hand
    local y = screenH - slotH - 24 - h
    x = 12
    love.graphics.setColor(0,0,0,0.65)
    love.graphics.rectangle('fill', x, y, w, h, 8, 8)
    love.graphics.setColor(1,1,1,1)
    local function sanitizeUtf8(s)
        if not s then return '' end
        if love.utf8 and pcall(love.utf8.len, s) then return s end
        s = s:gsub('[^%z\32-\126]', '')
        return s
    end
    local name = sanitizeUtf8(card.name or 'Unknown')
    local ability = sanitizeUtf8(card.ability or '')
    love.graphics.print(name, x+10, y+8)
    local line2 = (card.element or '?')..'  STR '..tostring(card.strength or card.baseStrength or 0)
    love.graphics.print(line2, x+10, y+26)
    love.graphics.printf(ability, x+10, y+42, w-20)
end

function ui.drawPassButton(state)
	if state.phase ~= 'setup' then return end
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	
	-- Pass buttons in center-right, stacked vertically
	local btnW, btnH = 120, 40
	local btnX = w - btnW - 16
	local centerY = h * 0.5
	
	-- Player B pass button (top, above center)
	local btnBY = centerY - btnH - 10
	
	-- Player A pass button (bottom, below center)
	local btnAY = centerY + 10
	
	-- Draw Player B pass button (top)
	if not state.setupPassed[2] then
		love.graphics.setColor(0,0,0,0.45)
		love.graphics.rectangle('fill', btnX, btnBY, btnW, btnH, 8, 8)
		love.graphics.setColor(1,1,1,1)
		love.graphics.rectangle('line', btnX, btnBY, btnW, btnH, 8, 8)
		love.graphics.printf('PLAYER B PASS', btnX, btnBY + 12, btnW, 'center')
	else
		love.graphics.setColor(0.2,0.8,0.2,0.8)
		love.graphics.rectangle('fill', btnX, btnBY, btnW, btnH, 8, 8)
		love.graphics.setColor(1,1,1,1)
		love.graphics.printf('PASSED', btnX, btnBY + 12, btnW, 'center')
	end
	
	-- Draw Player A pass button (bottom)
	if not state.setupPassed[1] then
		love.graphics.setColor(0,0,0,0.45)
		love.graphics.rectangle('fill', btnX, btnAY, btnW, btnH, 8, 8)
		love.graphics.setColor(1,1,1,1)
		love.graphics.rectangle('line', btnX, btnAY, btnW, btnH, 8, 8)
		love.graphics.printf('PLAYER A PASS', btnX, btnAY + 12, btnW, 'center')
	else
		love.graphics.setColor(0.2,0.8,0.2,0.8)
		love.graphics.rectangle('fill', btnX, btnAY, btnW, btnH, 8, 8)
		love.graphics.setColor(1,1,1,1)
		love.graphics.printf('PASSED', btnX, btnAY + 12, btnW, 'center')
	end
	
	-- Store button positions for click detection
	state.passButtonA = {x = btnX, y = btnAY, w = btnW, h = btnH}
	state.passButtonB = {x = btnX, y = btnBY, w = btnW, h = btnH}
end

function ui.hitPassButton(state, x, y, playerIndex)
	if not state.passButtonA or not state.passButtonB then return false end
	
	if playerIndex == 1 then
		-- Check Player A button
		return x >= state.passButtonA.x and x <= state.passButtonA.x + state.passButtonA.w and 
		       y >= state.passButtonA.y and y <= state.passButtonA.y + state.passButtonA.h
	elseif playerIndex == 2 then
		-- Check Player B button
		return x >= state.passButtonB.x and x <= state.passButtonB.x + state.passButtonB.w and 
		       y >= state.passButtonB.y and y <= state.passButtonB.y + state.passButtonB.h
	end
	
	return false
end

-- expose deck/gy drawer to game
function ui.drawDeckAndGY(state, cardBack)
    return drawDeckAndGY(state, cardBack)
end

-- Menu UI
local menuBtn = { x = 0, y = 0, w = 200, h = 60 }

function ui.drawMenu(state)
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	menuBtn.x = (w - menuBtn.w) * 0.5
	menuBtn.y = (h - menuBtn.h) * 0.5
	
	love.graphics.setColor(0,0,0,0.7)
	love.graphics.rectangle('fill', menuBtn.x, menuBtn.y, menuBtn.w, menuBtn.h, 8, 8)
	love.graphics.setColor(1,1,1,1)
	love.graphics.rectangle('line', menuBtn.x, menuBtn.y, menuBtn.w, menuBtn.h, 8, 8)
	love.graphics.printf('Build Deck', menuBtn.x, menuBtn.y + 20, menuBtn.w, 'center')
	
	love.graphics.setColor(1,1,1,1)
	love.graphics.printf('Kaard - Simple TCG', w*0.5 - 200, h*0.3, 400, 'center')
end

function ui.hitMenuButton(x, y)
	return x>=menuBtn.x and x<=menuBtn.x+menuBtn.w and y>=menuBtn.y and y<=menuBtn.y+menuBtn.h
end

-- Deck Builder UI
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

function ui.drawDeckBuilder(state, cardBack)
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	
	-- Title
	love.graphics.setColor(1,1,1,1)
	love.graphics.printf('Deck Builder - Player '..state.deckBuilderPlayer, w*0.5 - 200, 20, 400, 'center')
	
	-- Player switch buttons (bottom-left corner)
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
			Undead = {0.3, 0.1, 0.1, 0.8},    -- Dark red
			Spellcaster = {0.1, 0.1, 0.8, 0.8},      -- Blue  
			Druids = {0.1, 0.6, 0.1, 0.8},     -- Green
			Knights = {0.6, 0.6, 0.1, 0.8},    -- Yellow
			Mimic = {0.6, 0.1, 0.6, 0.8},      -- Purple
			Spider = {0.8, 0.4, 0.1, 0.8}      -- Orange
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
	
	-- Get current deck for card count display
	local currentDeck = state.playerDecks[state.deckBuilderPlayer] or {}
	
	local cardY = 160 - state.deckBuilderScroll
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
	local currentDeck = state.playerDecks[state.deckBuilderPlayer] or {}
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
	
	-- Instructions
	love.graphics.setColor(1,1,1,1)
	love.graphics.printf('Left-click: add card. Right-click: remove card. Mouse wheel: scroll. ESC: menu.', w*0.5 - 200, h-30, 400, 'center')
	
	-- Draw card tooltip if hovering over a card
	local hoveredCard = getHoveredDeckBuilderCard(state)
	if hoveredCard then
		drawCardTooltip(hoveredCard, w, h)
	end
	
	-- Draw notification if active
	if state.notification.timer > 0 then
		drawNotification(state.notification.text, w, h)
	end
end

function getHoveredDeckBuilderCard(state)
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

function drawCardTooltip(card, w, h)
	local tooltipW, tooltipH = 300, 120
	local x = w - tooltipW - 20
	local y = h - tooltipH - 20
	
	love.graphics.setColor(0,0,0,0.9)
	love.graphics.rectangle('fill', x, y, tooltipW, tooltipH, 8, 8)
	love.graphics.setColor(1,1,1,1)
	love.graphics.rectangle('line', x, y, tooltipW, tooltipH, 8, 8)
	
	-- Card name
	love.graphics.setColor(1,1,0,1)
	love.graphics.printf(card.name, x + 10, y + 10, tooltipW - 20, 'center')
	
	-- Element and Strength
	love.graphics.setColor(1,1,1,1)
	love.graphics.printf(card.element..' • STR '..card.strength, x + 10, y + 30, tooltipW - 20, 'center')
	
	-- Ability description
	love.graphics.setColor(0.8,0.8,0.8,1)
	love.graphics.printf(card.ability or 'No ability', x + 10, y + 50, tooltipW - 20, 'center')
end

function drawNotification(text, w, h)
	local notifW, notifH = 400, 50
	local x = (w - notifW) * 0.5
	local y = h * 0.3
	
	love.graphics.setColor(0.8,0.2,0.2,0.9)
	love.graphics.rectangle('fill', x, y, notifW, notifH, 8, 8)
	love.graphics.setColor(1,1,1,1)
	love.graphics.rectangle('line', x, y, notifW, notifH, 8, 8)
	love.graphics.printf(text, x + 10, y + 15, notifW - 20, 'center')
end

function drawPhaseTransition(state)
	if not state.phaseTransition.show then return end
	
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	local text = state.phaseTransition.text
	
	-- Large centered text with fade effect
	local alpha = math.min(1.0, state.phaseTransition.timer / 0.5)
	love.graphics.setColor(1, 1, 1, alpha)
	
	-- Use large font for phase transitions
	local font = love.graphics.getFont()
	local scale = 3.0
	love.graphics.push()
	love.graphics.scale(scale, scale)
	
	local textW = font:getWidth(text) * scale
	local textH = font:getHeight() * scale
	local x = (w - textW) * 0.5 / scale
	local y = (h - textH) * 0.5 / scale
	
	love.graphics.printf(text, x, y, textW / scale, 'center')
	love.graphics.pop()
end

function drawCoinTossAnimation(state)
	if not state.coinTossAnimation.show then return end
	
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	local timer = state.coinTossAnimation.timer
	local result = state.coinTossAnimation.result
	
	-- Background overlay
	love.graphics.setColor(0, 0, 0, 0.7)
	love.graphics.rectangle('fill', 0, 0, w, h)
	
	-- Spinning circle animation
	local centerX, centerY = w * 0.5, h * 0.5
	local radius = 80
	local time = love.timer.getTime()
	local spinSpeed = 8.0
	
	-- Draw spinning circle
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.circle('line', centerX, centerY, radius)
	
	-- Draw spinning indicator
	local angle = time * spinSpeed
	local indicatorX = centerX + math.cos(angle) * radius
	local indicatorY = centerY + math.sin(angle) * radius
	love.graphics.setColor(1, 0, 0, 1)
	love.graphics.circle('fill', indicatorX, indicatorY, 8)
	
	-- Show result in last 0.5 seconds
	if timer <= 0.5 then
		local resultText = result == 1 and 'A' or 'B'
		local alpha = (0.5 - timer) / 0.5
		love.graphics.setColor(1, 1, 0, alpha)
		
		-- Large result text
		local font = love.graphics.getFont()
		local scale = 4.0
		love.graphics.push()
		love.graphics.scale(scale, scale)
		
		local textW = font:getWidth(resultText) * scale
		local textH = font:getHeight() * scale
		local x = (w - textW) * 0.5 / scale
		local y = (h - textH) * 0.5 / scale
		
		love.graphics.printf(resultText, x, y, textW / scale, 'center')
		love.graphics.pop()
	end
	
	-- Title text
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf('COIN TOSS', w*0.5 - 100, centerY - 150, 200, 'center')
end

function drawResolutionPopup(state)
	if not state.resolutionPopup.show then return end
	
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	local data = state.resolutionPopup.data
	
	-- Large popup background
	local popupW, popupH = 600, 400
	local x = (w - popupW) * 0.5
	local y = (h - popupH) * 0.5
	
	-- Background with transparency
	love.graphics.setColor(0, 0, 0, 0.8)
	love.graphics.rectangle('fill', x, y, popupW, popupH, 12, 12)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.rectangle('line', x, y, popupW, popupH, 12, 12)
	
	-- Title
	love.graphics.setColor(1, 1, 0, 1)
	love.graphics.printf('ROUND '..data.round..' RESOLUTION', x + 20, y + 20, popupW - 40, 'center')
	
	-- Player 1 info
	love.graphics.setColor(0.2, 0.8, 0.2, 1)
	love.graphics.printf('Player A:', x + 30, y + 60, popupW - 60, 'left')
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf('Cards: '..(data.player1Cards or 'None'), x + 30, y + 80, popupW - 60, 'left')
	love.graphics.printf('Total Strength: '..data.player1Strength, x + 30, y + 100, popupW - 60, 'left')
	
	-- Player 2 info
	love.graphics.setColor(0.2, 0.8, 0.2, 1)
	love.graphics.printf('Player B:', x + 30, y + 140, popupW - 60, 'left')
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf('Cards: '..(data.player2Cards or 'None'), x + 30, y + 160, popupW - 60, 'left')
	love.graphics.printf('Total Strength: '..data.player2Strength, x + 30, y + 180, popupW - 60, 'left')
	
	-- Winner announcement
	local winnerText = ''
	if data.winner == 1 then
		winnerText = 'Player A WINS!'
		love.graphics.setColor(0.2, 0.8, 0.2, 1)
	elseif data.winner == 2 then
		winnerText = 'Player B WINS!'
		love.graphics.setColor(0.2, 0.8, 0.2, 1)
	else
		winnerText = 'DRAW!'
		love.graphics.setColor(0.8, 0.8, 0.2, 1)
	end
	
	love.graphics.printf(winnerText, x + 20, y + 220, popupW - 40, 'center')
	
	-- Score
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf('Match Score: '..data.roundWins[1]..' - '..data.roundWins[2], x + 20, y + 260, popupW - 40, 'center')
	
	-- Button (Next Round or Exit)
	local btnW, btnH = 200, 40
	local btnX = x + (popupW - btnW) * 0.5
	local btnY = y + 320
	
	local buttonText = 'NEXT ROUND'
	local buttonColor = {0.2, 0.8, 0.2, 0.8} -- Green
	
	-- Check if game is over
	if data.isGameOver then
		buttonText = 'EXIT'
		buttonColor = {0.8, 0.2, 0.2, 0.8} -- Red
		
		-- Show winner announcement above button
		local winnerName = data.winner == 1 and 'Player A' or 'Player B'
		love.graphics.setColor(1, 1, 0, 1) -- Yellow
		love.graphics.printf(winnerName..' IS THE WINNER!', x + 20, y + 280, popupW - 40, 'center')
	end
	
	love.graphics.setColor(buttonColor)
	love.graphics.rectangle('fill', btnX, btnY, btnW, btnH, 8, 8)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.rectangle('line', btnX, btnY, btnW, btnH, 8, 8)
	love.graphics.printf(buttonText, btnX, btnY + 12, btnW, 'center')
	
	-- Store button position for click detection
	state.resolutionPopup.buttonX = btnX
	state.resolutionPopup.buttonY = btnY
	state.resolutionPopup.buttonW = btnW
	state.resolutionPopup.buttonH = btnH
end

function ui.handleDeckBuilderClick(state, x, y, button)
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	
	-- Check player switch buttons (bottom-left corner)
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
		state.playerDecks[state.deckBuilderPlayer] = newDeck
		
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
		state.playerDecks[state.deckBuilderPlayer] = {}
		
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
			state.playerDecks[state.deckBuilderPlayer] = newDeck
			
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
						local currentDeck = state.playerDecks[state.deckBuilderPlayer]
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

return ui


