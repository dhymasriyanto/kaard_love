local hands = {}

-- Import shared constants
local slotW, slotH = 96, 140
local handSpacing = slotW + 12 -- no overlap; clear separation

local function handOrigin(playerIndex, count)
	local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
	local y = playerIndex==1 and (screenH - slotH - 8) or 8
	local visible = math.min(math.max(count, 1), 12)
	local totalW = (visible-1) * handSpacing + slotW
	local x = (screenW - totalW) * 0.5
	return x, y
end

function hands.draw(state, cardBack, drawCard)
	for pIndex=1,2 do
		local p = state.players[pIndex]
		local x, y = handOrigin(pIndex, #p.hand)
		
		-- Show hand cards based on phase:
		-- - Setup phase: show all cards face-up for both players
		-- - Combat phase: current player shows actual cards, opponent shows face-down
		-- - Multiplayer: always show opponent's cards as face-down
		local showActualCards = (state.phase == 'setup') or (pIndex == state.turn)
		if state.multiplayer and state.networkPlayerId ~= pIndex then
			showActualCards = false -- Always show opponent's cards as face-down in multiplayer
		end
		
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
					drawCard(card, cx, cy, true, cardBack)
				else
					-- Show card back (opponent's hand during their turn)
					drawCard(card, cx, cy, false, cardBack)
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

function hands.hitHand(state, player, x, y)
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

return hands
