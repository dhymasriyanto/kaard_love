local tooltips = {}

-- Import shared constants
local slotW, slotH = 96, 140
local handSpacing = slotW + 12

local function handOrigin(playerIndex, count)
	local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
	local y = playerIndex==1 and (screenH - slotH - 8) or 8
	local visible = math.min(math.max(count, 1), 12)
	local totalW = (visible-1) * handSpacing + slotW
	local x = (screenW - totalW) * 0.5
	return x, y
end

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
	return screenW*0.5 - (1.5*slotW + 20), y
end

local function getHoverCard(state)
    local mx, my = love.mouse.getPosition()
    
    -- During setup phase: both players can hover all cards
    if state.phase == 'setup' then
        -- Check all hands (both players)
        for pIndex=1,2 do
            if not state.players or not state.players[pIndex] then
                goto continue_setup_hands
            end
            local p = state.players[pIndex]
            local xLeft, yTop = handOrigin(pIndex, #p.hand)
            for i=1,#p.hand do
                local x1 = xLeft + (i-1)*handSpacing
                if mx>=x1 and mx<=x1+slotW and my>=yTop and my<=yTop+slotH then
                    return p.hand[i]
                end
            end
            ::continue_setup_hands::
        end
        
        -- Check all fields (both players)
        for pIndex=1,2 do
            if not state.players or not state.players[pIndex] then
                goto continue_setup_fields
            end
            local p = state.players[pIndex]
            local ox, oy = playerOrigin(pIndex)
            for i=1,3 do
                local x = ox + (i-1)*(slotW+20)
                local y = oy
                if mx>=x and mx<=x+slotW and my>=y and my<=y+slotH then
                    local c = p.field[i]
                    if c then return c end
                end
            end
            ::continue_setup_fields::
        end
    else
        -- During combat phase: only current player can hover their cards
        -- hands first (only current player's hand)
        if not state.players or not state.turn or not state.players[state.turn] then
            return nil
        end
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
            if not state.players or not state.players[pIndex] then
                goto continue
            end
            local p = state.players[pIndex]
            local ox, oy = playerOrigin(pIndex)
            for i=1,3 do
                local x = ox + (i-1)*(slotW+20)
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
            ::continue::
        end
    end
    return nil
end

function tooltips.drawHoverTooltip(state)
    local card = getHoverCard(state)
    if not card then return end
    local screenH = love.graphics.getHeight()
    local x
    local w, h = 360, 110
    -- place just above Player A hand
    local y = screenH - slotH - 24 - h
    x = 12
    love.graphics.setColor(0,0,0,0.75)
    love.graphics.rectangle('fill', x, y, w, h, 8, 8)
    love.graphics.setColor(1,1,1,1)
    love.graphics.rectangle('line', x, y, w, h, 8, 8)
    
    local function sanitizeUtf8(s)
        if not s then return '' end
        if love.utf8 and pcall(love.utf8.len, s) then return s end
        s = s:gsub('[^%z\32-\126]', '')
        return s
    end
    
    -- Card name (yellow/gold)
    local name = sanitizeUtf8(card.name or 'Unknown')
    love.graphics.setColor(1, 1, 0.3, 1) -- Bright yellow
    love.graphics.print(name, x+10, y+8)
    
    -- Element and Strength (cyan)
    local element = card.element or '?'
    local strength = tostring(card.strength or card.baseStrength or 0)
    love.graphics.setColor(0.3, 1, 1, 1) -- Cyan
    love.graphics.print(element..'  STR '..strength, x+10, y+26)
    
    -- Ability description (light gray)
    local ability = sanitizeUtf8(card.ability or '')
    love.graphics.setColor(0.9, 0.9, 0.9, 1) -- Light gray
    love.graphics.printf(ability, x+10, y+42, w-20)
end

return tooltips
