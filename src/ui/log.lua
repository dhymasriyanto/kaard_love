local log = {}

local LOG_BOX = { w = 240, h = 160, x = 0, y = 0, lineH = 16, padding = 8, headerH = 22 }

function log.getMaxLines()
    return math.floor((LOG_BOX.h - LOG_BOX.headerH - LOG_BOX.padding) / LOG_BOX.lineH)
end

function log.isMouseInLogBox()
    local boxW, boxH = LOG_BOX.w, LOG_BOX.h
    local x = love.graphics.getWidth() - boxW - 8
    local y = 8
    local mx, my = love.mouse.getPosition()
    return mx>=x and mx<=x+boxW and my>=y and my<=y+boxH
end

function log.draw(logs, scroll)
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
            love.graphics.setColor(0.8, 0.2, 0.8, 1) -- Magenta for special effects
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

return log
