local menus = {}

-- Menu UI
local menuButtons = {
	{ x = 0, y = 0, w = 200, h = 60, text = 'Build Deck', type = 'deckbuilder' },
	{ x = 0, y = 0, w = 200, h = 60, text = 'Host Game', type = 'host' },
	{ x = 0, y = 0, w = 200, h = 60, text = 'Join Game', type = 'join' }
}

-- Multiplayer input state
local multiplayerInput = {
	hostInput = { text = 'localhost', active = false },
	portInput = { text = '12345', active = false },
	showInput = false,
	inputType = 'host' -- 'host' or 'join'
}

function menus.drawMenu(state)
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	
	-- Title
	love.graphics.setColor(1,1,1,1)
	love.graphics.printf('Kaard - Simple TCG', w*0.5 - 200, h*0.2, 400, 'center')
	
	-- Check if in lobby
	local multiplayer = require('src.core.multiplayer')
	if multiplayer.isInLobby() then
		menus.drawLobby()
		return
	end
	
	-- Position buttons vertically
	local buttonSpacing = 80
	local startY = h*0.4
	local centerX = (w - menuButtons[1].w) * 0.5
	
	for i, btn in ipairs(menuButtons) do
		btn.x = centerX
		btn.y = startY + (i-1) * buttonSpacing
		
		-- Button background
		love.graphics.setColor(0,0,0,0.7)
		love.graphics.rectangle('fill', btn.x, btn.y, btn.w, btn.h, 8, 8)
		love.graphics.setColor(1,1,1,1)
		love.graphics.rectangle('line', btn.x, btn.y, btn.w, btn.h, 8, 8)
		
		-- Button text
		love.graphics.printf(btn.text, btn.x, btn.y + 20, btn.w, 'center')
	end
	
	-- Draw multiplayer input if active
	if multiplayerInput.showInput then
		menus.drawMultiplayerInput()
	end
end

function menus.drawMultiplayerInput()
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	local inputW, inputH = 400, 200
	local x = (w - inputW) * 0.5
	local y = (h - inputH) * 0.5
	
	-- Background
	love.graphics.setColor(0, 0, 0, 0.8)
	love.graphics.rectangle('fill', x, y, inputW, inputH, 8, 8)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.rectangle('line', x, y, inputW, inputH, 8, 8)
	
	-- Title
	local title = multiplayerInput.inputType == 'host' and 'Host Game' or 'Join Game'
	love.graphics.printf(title, x + 20, y + 20, inputW - 40, 'center')
	
	-- Host input
	love.graphics.printf('Host:', x + 20, y + 60, 100, 'left')
	local hostX = x + 120
	local hostY = y + 55
	local hostW = 200
	local hostH = 25
	
	love.graphics.setColor(0.2, 0.2, 0.2, 1)
	love.graphics.rectangle('fill', hostX, hostY, hostW, hostH)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.rectangle('line', hostX, hostY, hostW, hostH)
	
	if multiplayerInput.hostInput.active then
		love.graphics.setColor(0, 0, 1, 1)
		love.graphics.rectangle('line', hostX, hostY, hostW, hostH)
	end
	
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf(multiplayerInput.hostInput.text, hostX + 5, hostY + 5, hostW - 10, 'left')
	
	-- Port input
	love.graphics.printf('Port:', x + 20, y + 100, 100, 'left')
	local portX = x + 120
	local portY = y + 95
	local portW = 200
	local portH = 25
	
	love.graphics.setColor(0.2, 0.2, 0.2, 1)
	love.graphics.rectangle('fill', portX, portY, portW, portH)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.rectangle('line', portX, portY, portW, portH)
	
	if multiplayerInput.portInput.active then
		love.graphics.setColor(0, 0, 1, 1)
		love.graphics.rectangle('line', portX, portY, portW, portH)
	end
	
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf(multiplayerInput.portInput.text, portX + 5, portY + 5, portW - 10, 'left')
	
	-- Buttons
	local btnW, btnH = 80, 30
	local btnSpacing = 20
	
	-- Connect button
	local connectX = x + (inputW - btnW*2 - btnSpacing) * 0.5
	local connectY = y + 140
	
	love.graphics.setColor(0.2, 0.8, 0.2, 0.8)
	love.graphics.rectangle('fill', connectX, connectY, btnW, btnH, 4, 4)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.rectangle('line', connectX, connectY, btnW, btnH, 4, 4)
	love.graphics.printf('Connect', connectX, connectY + 8, btnW, 'center')
	
	-- Cancel button
	local cancelX = connectX + btnW + btnSpacing
	
	love.graphics.setColor(0.8, 0.2, 0.2, 0.8)
	love.graphics.rectangle('fill', cancelX, connectY, btnW, btnH, 4, 4)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.rectangle('line', cancelX, connectY, btnW, btnH, 4, 4)
	love.graphics.printf('Cancel', cancelX, connectY + 8, btnW, 'center')
	
	-- Store button positions for click detection
	multiplayerInput.connectButton = {x = connectX, y = connectY, w = btnW, h = btnH}
	multiplayerInput.cancelButton = {x = cancelX, y = connectY, w = btnW, h = btnH}
	multiplayerInput.hostInputBox = {x = hostX, y = hostY, w = hostW, h = hostH}
	multiplayerInput.portInputBox = {x = portX, y = portY, w = portW, h = portH}
end

function menus.hitMenuButton(x, y)
	for _, btn in ipairs(menuButtons) do
		if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
			return btn.type
		end
	end
	return nil
end

function menus.hitMultiplayerInput(x, y)
	if not multiplayerInput.showInput then return nil end
	
	-- Check input boxes
	if multiplayerInput.hostInputBox and 
	   x >= multiplayerInput.hostInputBox.x and x <= multiplayerInput.hostInputBox.x + multiplayerInput.hostInputBox.w and
	   y >= multiplayerInput.hostInputBox.y and y <= multiplayerInput.hostInputBox.y + multiplayerInput.hostInputBox.h then
		return 'host_input'
	end
	
	if multiplayerInput.portInputBox and 
	   x >= multiplayerInput.portInputBox.x and x <= multiplayerInput.portInputBox.x + multiplayerInput.portInputBox.w and
	   y >= multiplayerInput.portInputBox.y and y <= multiplayerInput.portInputBox.y + multiplayerInput.portInputBox.h then
		return 'port_input'
	end
	
	-- Check buttons
	if multiplayerInput.connectButton and 
	   x >= multiplayerInput.connectButton.x and x <= multiplayerInput.connectButton.x + multiplayerInput.connectButton.w and
	   y >= multiplayerInput.connectButton.y and y <= multiplayerInput.connectButton.y + multiplayerInput.connectButton.h then
		return 'connect'
	end
	
	if multiplayerInput.cancelButton and 
	   x >= multiplayerInput.cancelButton.x and x <= multiplayerInput.cancelButton.x + multiplayerInput.cancelButton.w and
	   y >= multiplayerInput.cancelButton.y and y <= multiplayerInput.cancelButton.y + multiplayerInput.cancelButton.h then
		return 'cancel'
	end
	
	return nil
end

function menus.showMultiplayerInput(inputType)
	multiplayerInput.showInput = true
	multiplayerInput.inputType = inputType
	multiplayerInput.hostInput.active = false
	multiplayerInput.portInput.active = false
end

function menus.hideMultiplayerInput()
	multiplayerInput.showInput = false
	multiplayerInput.hostInput.active = false
	multiplayerInput.portInput.active = false
end

function menus.getMultiplayerInput()
	return multiplayerInput
end

function menus.setActiveInput(inputType)
	multiplayerInput.hostInput.active = (inputType == 'host_input')
	multiplayerInput.portInput.active = (inputType == 'port_input')
end

function menus.addToActiveInput(char)
	if multiplayerInput.hostInput.active then
		if char == '\b' then
			multiplayerInput.hostInput.text = string.sub(multiplayerInput.hostInput.text, 1, -2)
		else
			multiplayerInput.hostInput.text = multiplayerInput.hostInput.text .. char
		end
	elseif multiplayerInput.portInput.active then
		if char == '\b' then
			multiplayerInput.portInput.text = string.sub(multiplayerInput.portInput.text, 1, -2)
		elseif string.match(char, '%d') then -- Only allow digits
			multiplayerInput.portInput.text = multiplayerInput.portInput.text .. char
		end
	end
end

function menus.drawLobby()
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	local multiplayer = require('src.core.multiplayer')
	
	local lobbyW, lobbyH = 500, 300
	local x = (w - lobbyW) * 0.5
	local y = (h - lobbyH) * 0.5
	
	-- Background
	love.graphics.setColor(0, 0, 0, 0.8)
	love.graphics.rectangle('fill', x, y, lobbyW, lobbyH, 8, 8)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.rectangle('line', x, y, lobbyW, lobbyH, 8, 8)
	
	-- Title
	local title = multiplayer.getMode() == 'host' and 'Hosting Game' or 'Joining Game'
	love.graphics.printf(title, x + 20, y + 20, lobbyW - 40, 'center')
	
	-- Connection info
	local status = multiplayer.getConnectionStatus()
	local statusColor = {1, 1, 1, 1}
	if status == 'connected' then
		statusColor = {0.2, 1, 0.2, 1}
	elseif status == 'connecting' then
		statusColor = {1, 1, 0.2, 1}
	elseif status == 'error' then
		statusColor = {1, 0.2, 0.2, 1}
	end
	
	love.graphics.setColor(statusColor)
	love.graphics.printf('Status: ' .. status, x + 20, y + 60, lobbyW - 40, 'center')
	
	-- Debug: show multiplayer mode
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf('Mode: ' .. multiplayer.getMode(), x + 20, y + 80, lobbyW - 40, 'center')
	
	-- Player info
	local playerNames = multiplayer.getPlayerNames()
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf('Players:', x + 20, y + 100, lobbyW - 40, 'left')
	
	-- Player 1
	local p1Color = {0.8, 0.8, 0.8, 1}
	if multiplayer.getMyPlayerId() == 1 then
		p1Color = {0.2, 0.8, 0.2, 1}
	end
	love.graphics.setColor(p1Color)
	love.graphics.printf('• ' .. playerNames[1], x + 40, y + 120, lobbyW - 60, 'left')
	
	-- Player 2
	local p2Color = {0.8, 0.8, 0.8, 1}
	if multiplayer.getMyPlayerId() == 2 then
		p2Color = {0.2, 0.8, 0.2, 1}
	end
	love.graphics.setColor(p2Color)
	love.graphics.printf('• ' .. playerNames[2], x + 40, y + 140, lobbyW - 60, 'left')
	
	-- Ready status
	local lobbyPhase = multiplayer.getLobbyPhase()
	-- Debug: show lobby phase
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf('Lobby Phase: ' .. lobbyPhase, x + 20, y + 160, lobbyW - 40, 'left')
	
	if lobbyPhase == 'ready' or lobbyPhase == 'waiting' then
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.printf('Ready Status:', x + 20, y + 180, lobbyW - 40, 'left')
		
		-- My ready status
		local myReady = multiplayer.isMyReady()
		local myReadyColor = myReady and {0.2, 1, 0.2, 1} or {0.8, 0.8, 0.8, 1}
		love.graphics.setColor(myReadyColor)
		love.graphics.printf('You: ' .. (myReady and 'Ready' or 'Not Ready'), x + 40, y + 200, lobbyW - 60, 'left')
		
		-- Opponent ready status
		local opponentReady = multiplayer.isOpponentReady()
		local opponentReadyColor = opponentReady and {0.2, 1, 0.2, 1} or {0.8, 0.8, 0.8, 1}
		love.graphics.setColor(opponentReadyColor)
		love.graphics.printf('Opponent: ' .. (opponentReady and 'Ready' or 'Not Ready'), x + 40, y + 220, lobbyW - 60, 'left')
		
		-- Ready button
		local btnW, btnH = 120, 40
		local btnX = x + (lobbyW - btnW) * 0.5
		local btnY = y + 250
		
		local btnColor = myReady and {0.8, 0.2, 0.2, 0.8} or {0.2, 0.8, 0.2, 0.8}
		local btnText = myReady and 'Not Ready' or 'Ready'
		
		love.graphics.setColor(btnColor)
		love.graphics.rectangle('fill', btnX, btnY, btnW, btnH, 8, 8)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.rectangle('line', btnX, btnY, btnW, btnH, 8, 8)
		love.graphics.printf(btnText, btnX, btnY + 12, btnW, 'center')
		
		-- Store button position for click detection
		multiplayerInput.readyButton = {x = btnX, y = btnY, w = btnW, h = btnH}
		
		-- Start game button (if both ready AND host)
		if multiplayer.canStartGame() and multiplayer.getMode() == 'host' then
			local startBtnW, startBtnH = 150, 40
			local startBtnX = x + (lobbyW - startBtnW) * 0.5
			local startBtnY = btnY + btnH + 10
			
			love.graphics.setColor(0.2, 0.8, 0.2, 0.8)
			love.graphics.rectangle('fill', startBtnX, startBtnY, startBtnW, startBtnH, 8, 8)
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.rectangle('line', startBtnX, startBtnY, startBtnW, startBtnH, 8, 8)
			love.graphics.printf('Start Game', startBtnX, startBtnY + 12, startBtnW, 'center')
			
			-- Store button position for click detection
			multiplayerInput.startButton = {x = startBtnX, y = startBtnY, w = startBtnW, h = startBtnH}
		elseif multiplayer.canStartGame() and multiplayer.getMode() == 'client' then
			-- Client waiting for host to start
			local waitBtnW, waitBtnH = 150, 40
			local waitBtnX = x + (lobbyW - waitBtnW) * 0.5
			local waitBtnY = btnY + btnH + 10
			
			love.graphics.setColor(0.6, 0.6, 0.6, 0.8)
			love.graphics.rectangle('fill', waitBtnX, waitBtnY, waitBtnW, waitBtnH, 8, 8)
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.rectangle('line', waitBtnX, waitBtnY, waitBtnW, waitBtnH, 8, 8)
			love.graphics.printf('Waiting for Host...', waitBtnX, waitBtnY + 12, waitBtnW, 'center')
			
			-- No click detection for client
			multiplayerInput.startButton = nil
		end
	else
		-- Waiting for opponent
		love.graphics.setColor(1, 1, 0.2, 1)
		love.graphics.printf('Waiting for opponent...', x + 20, y + 180, lobbyW - 40, 'center')
	end
	
	-- Cancel button
	local cancelBtnW, cancelBtnH = 80, 30
	local cancelBtnX = x + 20
	local cancelBtnY = y + lobbyH - cancelBtnH - 20
	
	love.graphics.setColor(0.8, 0.2, 0.2, 0.8)
	love.graphics.rectangle('fill', cancelBtnX, cancelBtnY, cancelBtnW, cancelBtnH, 4, 4)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.rectangle('line', cancelBtnX, cancelBtnY, cancelBtnW, cancelBtnH, 4, 4)
	love.graphics.printf('Cancel', cancelBtnX, cancelBtnY + 8, cancelBtnW, 'center')
	
	-- Store button position for click detection
	multiplayerInput.cancelLobbyButton = {x = cancelBtnX, y = cancelBtnY, w = cancelBtnW, h = cancelBtnH}
end

function menus.hitLobbyButton(x, y)
	local multiplayer = require('src.core.multiplayer')
	
	if not multiplayer.isInLobby() then
		return nil
	end
	
	-- Check ready button
	if multiplayerInput.readyButton and 
	   x >= multiplayerInput.readyButton.x and x <= multiplayerInput.readyButton.x + multiplayerInput.readyButton.w and
	   y >= multiplayerInput.readyButton.y and y <= multiplayerInput.readyButton.y + multiplayerInput.readyButton.h then
		return 'ready'
	end
	
	-- Check start game button
	if multiplayerInput.startButton and 
	   x >= multiplayerInput.startButton.x and x <= multiplayerInput.startButton.x + multiplayerInput.startButton.w and
	   y >= multiplayerInput.startButton.y and y <= multiplayerInput.startButton.y + multiplayerInput.startButton.h then
		return 'start'
	end
	
	-- Check cancel button
	if multiplayerInput.cancelLobbyButton and 
	   x >= multiplayerInput.cancelLobbyButton.x and x <= multiplayerInput.cancelLobbyButton.x + multiplayerInput.cancelLobbyButton.w and
	   y >= multiplayerInput.cancelLobbyButton.y and y <= multiplayerInput.cancelLobbyButton.y + multiplayerInput.cancelLobbyButton.h then
		return 'cancel'
	end
	
	return nil
end

function menus.drawPassButton(state)
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
		-- Show different text for multiplayer
		if state.multiplayer and state.multiplayer.isMultiplayer then
			local multiplayer = require('src.core.multiplayer')
			local playerName = multiplayer.getMode() == 'host' and 'OPPONENT' or 'YOU'
			love.graphics.printf(playerName .. ' PASS', btnX, btnBY + 12, btnW, 'center')
		else
			love.graphics.printf('PLAYER B PASS', btnX, btnBY + 12, btnW, 'center')
		end
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
		-- Show different text for multiplayer
		if state.multiplayer and state.multiplayer.isMultiplayer then
			local multiplayer = require('src.core.multiplayer')
			local playerName = multiplayer.getMode() == 'host' and 'YOU' or 'OPPONENT'
			love.graphics.printf(playerName .. ' PASS', btnX, btnAY + 12, btnW, 'center')
		else
			love.graphics.printf('PLAYER A PASS', btnX, btnAY + 12, btnW, 'center')
		end
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

function menus.hitPassButton(state, x, y, playerIndex)
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

function menus.drawPhaseTransition(state)
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

function menus.drawCoinTossAnimation(state)
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

function menus.drawResolutionPopup(state)
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
	
	-- Helper function to calculate text height
	local function getTextHeight(text, width)
		local font = love.graphics.getFont()
		local _, wrappedText = font:getWrap(text, width)
		return #wrappedText * font:getHeight()
	end
	
	-- Player 1 info
	local currentY = y + 60
	love.graphics.setColor(0.2, 0.8, 0.2, 1)
	love.graphics.printf('Player A:', x + 30, currentY, popupW - 60, 'left')
	currentY = currentY + 20
	
	love.graphics.setColor(1, 1, 1, 1)
	local player1CardsText = 'Cards: '..(data.player1Cards or 'None')
	love.graphics.printf(player1CardsText, x + 30, currentY, popupW - 60, 'left')
	currentY = currentY + getTextHeight(player1CardsText, popupW - 60) + 5
	
	love.graphics.printf('Total Strength: '..data.player1Strength, x + 30, currentY, popupW - 60, 'left')
	currentY = currentY + 25 -- Add spacing before Player B
	
	-- Player 2 info
	love.graphics.setColor(0.2, 0.8, 0.2, 1)
	love.graphics.printf('Player B:', x + 30, currentY, popupW - 60, 'left')
	currentY = currentY + 20
	
	love.graphics.setColor(1, 1, 1, 1)
	local player2CardsText = 'Cards: '..(data.player2Cards or 'None')
	love.graphics.printf(player2CardsText, x + 30, currentY, popupW - 60, 'left')
	currentY = currentY + getTextHeight(player2CardsText, popupW - 60) + 5
	
	love.graphics.printf('Total Strength: '..data.player2Strength, x + 30, currentY, popupW - 60, 'left')
	currentY = currentY + 25 -- Add spacing before winner announcement
	
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
	
	love.graphics.printf(winnerText, x + 20, currentY, popupW - 40, 'center')
	currentY = currentY + 25
	
	-- Score
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf('Match Score: '..data.roundWins[1]..' - '..data.roundWins[2], x + 20, currentY, popupW - 40, 'center')
	currentY = currentY + 40 -- Increased spacing
	
	-- Check if game is over and show winner announcement
	if data.isGameOver then
		local winnerName = data.winner == 1 and 'Player A' or 'Player B'
		love.graphics.setColor(1, 1, 0, 1) -- Yellow
		love.graphics.printf(winnerName..' IS THE WINNER!', x + 20, currentY, popupW - 40, 'center')
		currentY = currentY + 40 -- Add spacing after winner announcement
	end
	
	-- Button (Next Round or Exit)
	local btnW, btnH = 200, 40
	local btnX = x + (popupW - btnW) * 0.5
	local btnY = currentY + 20 -- Move button lower
	
	local buttonText = 'NEXT ROUND'
	local buttonColor = {0.2, 0.8, 0.2, 0.8} -- Green
	
	-- Check if game is over
	if data.isGameOver then
		buttonText = 'EXIT'
		buttonColor = {0.8, 0.2, 0.2, 0.8} -- Red
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

return menus
