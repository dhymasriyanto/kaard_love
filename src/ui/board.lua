local board = {}

-- Import shared constants and functions
local slotW, slotH = 96, 140
local margin = 20

local function playerOrigin(playerIndex)
	local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
	local y
	
	-- Check if in multiplayer mode
	local multiplayer = require('src.core.multiplayer')
	if multiplayer.isMultiplayer() then
		-- In multiplayer: Both players see themselves as Player 1 (bottom) and opponent as Player 2 (top)
		-- This ensures consistent POV for both host and client
		if playerIndex == 1 then
			-- Player 1 (myself) always at bottom
			y = screenH - slotH - 8 - slotH - 28
		else
			-- Player 2 (opponent) always at top
			y = 8 + slotH + 28
		end
	else
		-- Single player: Player A at bottom, Player B at top
		if playerIndex == 1 then
			-- Place Player A field above their bottom hand and GY (mirror of Player B)
			y = screenH - slotH - 8 - slotH - 28
		else
			-- Place Player B field below their top hand and GY
			y = 8 + slotH + 28
		end
	end
	
	return screenW*0.5 - (1.5*slotW + margin), y
end

local function drawPileLabel(text, x, y)
	-- Draw count inside the card instead of below it (even wider to prevent wrapping)
	love.graphics.setColor(0,0,0,0.8)
	love.graphics.rectangle('fill', x + slotW - 60, y + slotH - 20, 60, 20)
	love.graphics.setColor(1,1,1,1)
	love.graphics.printf(text, x + slotW - 60, y + slotH - 18, 60, 'center')
end

function board.draw(state, cardBack, drawCard, drawVictoryIndicators)
	for pIndex=1,2 do
		local ox, oy = playerOrigin(pIndex)
		for i=1,3 do
			local x = ox + (i-1)*(slotW+margin)
			local y = oy
			local p = state.players[pIndex]
			if p.field[i] then
				drawCard(p.field[i], x, y, p.revealed[i], cardBack)
				-- Show current strength on revealed cards (large, clear display)
				if p.revealed[i] then
					local card = p.field[i]
					local str = card.strength or card.baseStrength or 0
					love.graphics.setColor(0,0,0,0.9)
					love.graphics.rectangle('fill', x + slotW - 40, y + 5, 35, 25)
					love.graphics.setColor(1,1,1,1)
					love.graphics.printf(tostring(str), x + slotW - 40, y + 8, 35, 'center')
				end
				-- Debug: Show card name for face-down cards in multiplayer
				if not p.revealed[i] and state.multiplayer and state.multiplayer.isMultiplayer then
					local card = p.field[i]
					if card and card.name then
						love.graphics.setColor(0,0,0,0.7)
						love.graphics.rectangle('fill', x + 5, y + slotH - 20, slotW - 10, 15)
						love.graphics.setColor(1,1,1,1)
						love.graphics.printf(card.name, x + 5, y + slotH - 18, slotW - 10, 'center')
					end
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

function board.drawVictoryIndicators(state)
	if not state.roundWins then return end
	
	-- Don't draw during resolution popup to avoid flickering
	if state.resolutionPopup and state.resolutionPopup.show then return end
	
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	local circleSize = 16
	local spacing = 25
	
	-- Position indicators near turn info (left-center area)
	local centerX = 20
	local centerY = h * 0.5
	
	-- Player B indicators (above turn info) - close to turn text
	local p2X = centerX
	local p2Y = centerY - 25
	
	-- Player A indicators (below combat hint) - more space from text
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

function board.drawDeckAndGY(state, cardBack, drawCard)
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	-- Player A POV: bottom-right deck, above it GY
	local pA = state.players[1]
	local deckAx = w - slotW - 12
	local deckAy = h - slotH - 12
	drawCard({image=nil}, deckAx, deckAy, false, cardBack)
	drawPileLabel('Deck: '..#pA.deck, deckAx, deckAy)
	local gyAx = deckAx
	local gyAy = deckAy - slotH - 8
	local topA = pA.grave[#pA.grave]
	if topA then drawCard(topA, gyAx, gyAy, true, cardBack) else
		love.graphics.setColor(1,1,1,0.15); love.graphics.rectangle('line', gyAx, gyAy, slotW, slotH, 8, 8)
	end
	drawPileLabel('GY: '..#pA.grave, gyAx, gyAy)

	-- Player B POV: top-left deck, below it GY
	local pB = state.players[2]
	local deckBx = 12
	local deckBy = 12
	drawCard({image=nil}, deckBx, deckBy, false, cardBack)
	drawPileLabel('Deck: '..#pB.deck, deckBx, deckBy)
	local gyBx = deckBx
	local gyBy = deckBy + slotH + 8
	local topB = pB.grave[#pB.grave]
	if topB then drawCard(topB, gyBx, gyBy, true, cardBack) else
		love.graphics.setColor(1,1,1,0.15); love.graphics.rectangle('line', gyBx, gyBy, slotW, slotH, 8, 8)
	end
	drawPileLabel('GY: '..#pB.grave, gyBx, gyBy)
end

function board.hitFieldSlot(playerIndex, x, y)
	local ox, oy = playerOrigin(playerIndex)
	for i=1,3 do
		local sx = ox + (i-1)*(slotW+margin)
		if x>=sx and x<=sx+slotW and y>=oy and y<=oy+slotH then return i end
	end
	return nil
end

return board
