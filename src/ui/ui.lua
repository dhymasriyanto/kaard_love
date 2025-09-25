local ui = {}

-- Import modular UI components
local deckbuilder = require('src.ui.deckbuilder')
local board = require('src.ui.board')
local hands = require('src.ui.hands')
local menus = require('src.ui.menus')
local tooltips = require('src.ui.tooltips')
local log = require('src.ui.log')

-- Shared constants
local slotW, slotH = 96, 140
local margin = 20
local handSpacing = slotW + 12 -- no overlap; clear separation

-- Core card drawing function
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

-- Delegate to modular components
function ui.drawBoard(state, cardBack)
	board.draw(state, cardBack, ui.drawCard, board.drawVictoryIndicators)
end

function ui.drawHands(state, cardBack)
	hands.draw(state, cardBack, ui.drawCard)
end

function ui.drawDeckBuilder(state, cardBack)
	deckbuilder.draw(state, cardBack)
end

function ui.drawMenu(state)
	menus.drawMenu(state)
end

function ui.drawPassButton(state)
	menus.drawPassButton(state)
end

function ui.drawPhaseTransition(state)
	menus.drawPhaseTransition(state)
end

function ui.drawCoinTossAnimation(state)
	menus.drawCoinTossAnimation(state)
end

function ui.drawResolutionPopup(state)
	menus.drawResolutionPopup(state)
end

function ui.drawHoverTooltip(state)
	tooltips.drawHoverTooltip(state)
end

function ui.drawLog(logs, scroll)
	log.draw(logs, scroll)
end

function ui.drawDeckAndGY(state, cardBack)
	board.drawDeckAndGY(state, cardBack, ui.drawCard)
end

function ui.drawMultiplayerStatus(state)
	local multiplayer = require('src.core.multiplayer')
	
	if not multiplayer.isMultiplayer() then
		return
	end
	
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	local status = multiplayer.getConnectionStatus()
	local playerNames = multiplayer.getPlayerNames()
	local myPlayerId = multiplayer.getMyPlayerId()
	
	-- Status indicator in top-right corner
	local statusX = w - 200
	local statusY = 20
	local statusW = 180
	local statusH = 60
	
	-- Background
	love.graphics.setColor(0, 0, 0, 0.7)
	love.graphics.rectangle('fill', statusX, statusY, statusW, statusH, 8, 8)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.rectangle('line', statusX, statusY, statusW, statusH, 8, 8)
	
	-- Status text
	local statusText = "Multiplayer"
	local statusColor = {1, 1, 1, 1}
	
	if status == 'connected' then
		statusText = "Connected"
		statusColor = {0.2, 1, 0.2, 1}
	elseif status == 'connecting' then
		statusText = "Connecting..."
		statusColor = {1, 1, 0.2, 1}
	elseif status == 'error' then
		statusText = "Error"
		statusColor = {1, 0.2, 0.2, 1}
	else
		statusText = "Disconnected"
		statusColor = {0.8, 0.8, 0.8, 1}
	end
	
	love.graphics.setColor(statusColor)
	love.graphics.printf(statusText, statusX + 10, statusY + 10, statusW - 20, 'center')
	
	-- Player info
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf("You: " .. playerNames[myPlayerId], statusX + 10, statusY + 30, statusW - 20, 'center')
	
	-- Show error message if any
	local lastError = multiplayer.getLastError()
	if lastError then
		love.graphics.setColor(1, 0.2, 0.2, 1)
		love.graphics.printf(lastError, statusX + 10, statusY + 45, statusW - 20, 'center')
	end
end

-- Hit testing functions
function ui.hitHand(state, player, x, y)
	return hands.hitHand(state, player, x, y)
end

function ui.hitFieldSlot(playerIndex, x, y)
	return board.hitFieldSlot(playerIndex, x, y)
end

function ui.hitMenuButton(x, y)
	return menus.hitMenuButton(x, y)
end

function ui.hitPassButton(state, x, y, playerIndex)
	return menus.hitPassButton(state, x, y, playerIndex)
end

function ui.handleDeckBuilderClick(state, x, y, button)
	deckbuilder.handleClick(state, x, y, button)
end

-- Utility functions
function ui.getLogMaxLines()
	return log.getMaxLines()
end

function ui.isMouseInLogBox()
	return log.isMouseInLogBox()
end

return ui
