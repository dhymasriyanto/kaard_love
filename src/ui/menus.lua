local menus = {}

-- Menu UI
local menuBtn = { x = 0, y = 0, w = 200, h = 60 }

function menus.drawMenu(state)
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	
	-- Title
	love.graphics.setColor(1,1,1,1)
	love.graphics.printf('Kaard - Simple TCG', w*0.5 - 200, h*0.3, 400, 'center')
	
	-- Single Player button
	menuBtn.x = (w - menuBtn.w) * 0.5
	menuBtn.y = (h - menuBtn.h) * 0.5 - 40
	
	love.graphics.setColor(0,0,0,0.7)
	love.graphics.rectangle('fill', menuBtn.x, menuBtn.y, menuBtn.w, menuBtn.h, 8, 8)
	love.graphics.setColor(1,1,1,1)
	love.graphics.rectangle('line', menuBtn.x, menuBtn.y, menuBtn.w, menuBtn.h, 8, 8)
	love.graphics.printf('Single Player', menuBtn.x, menuBtn.y + 20, menuBtn.w, 'center')
	
	-- Multiplayer button
	local multiplayerBtn = {x = menuBtn.x, y = menuBtn.y + menuBtn.h + 20, w = menuBtn.w, h = menuBtn.h}
	
	love.graphics.setColor(0,0,0,0.7)
	love.graphics.rectangle('fill', multiplayerBtn.x, multiplayerBtn.y, multiplayerBtn.w, multiplayerBtn.h, 8, 8)
	love.graphics.setColor(1,1,1,1)
	love.graphics.rectangle('line', multiplayerBtn.x, multiplayerBtn.y, multiplayerBtn.w, multiplayerBtn.h, 8, 8)
	love.graphics.printf('Multiplayer', multiplayerBtn.x, multiplayerBtn.y + 20, multiplayerBtn.w, 'center')
	
	-- Store button positions for click detection
	state.menuButtons = {
		singlePlayer = {x = menuBtn.x, y = menuBtn.y, w = menuBtn.w, h = menuBtn.h},
		multiplayer = {x = multiplayerBtn.x, y = multiplayerBtn.y, w = multiplayerBtn.w, h = multiplayerBtn.h}
	}
end

function menus.hitMenuButton(x, y, state)
	if not state.menuButtons then
		return nil
	end
	
	-- Check single player button
	if x >= state.menuButtons.singlePlayer.x and x <= state.menuButtons.singlePlayer.x + state.menuButtons.singlePlayer.w and
	   y >= state.menuButtons.singlePlayer.y and y <= state.menuButtons.singlePlayer.y + state.menuButtons.singlePlayer.h then
		return 'singlePlayer'
	end
	
	-- Check multiplayer button
	if x >= state.menuButtons.multiplayer.x and x <= state.menuButtons.multiplayer.x + state.menuButtons.multiplayer.w and
	   y >= state.menuButtons.multiplayer.y and y <= state.menuButtons.multiplayer.y + state.menuButtons.multiplayer.h then
		return 'multiplayer'
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
	local popupW, popupH = 600, 500
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
	love.graphics.printf('Total Strength: '..data.player1Strength, x + 30, y + 120, popupW - 60, 'left')
	
	-- Player 2 info
	love.graphics.setColor(0.2, 0.8, 0.2, 1)
	love.graphics.printf('Player B:', x + 30, y + 160, popupW - 60, 'left')
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf('Cards: '..(data.player2Cards or 'None'), x + 30, y + 180, popupW - 60, 'left')
	love.graphics.printf('Total Strength: '..data.player2Strength, x + 30, y + 220, popupW - 60, 'left')
	
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
	
	love.graphics.printf(winnerText, x + 20, y + 260, popupW - 40, 'center')
	
	-- Score
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf('Match Score: '..data.roundWins[1]..' - '..data.roundWins[2], x + 20, y + 300, popupW - 40, 'center')
	
	-- Button (Next Round or Exit)
	local btnW, btnH = 200, 40
	local btnX = x + (popupW - btnW) * 0.5
	local btnY = y + 360
	
	local buttonText = 'NEXT ROUND'
	local buttonColor = {0.2, 0.8, 0.2, 0.8} -- Green
	
	-- Check if game is over
	if data.isGameOver then
		buttonText = 'EXIT'
		buttonColor = {0.8, 0.2, 0.2, 0.8} -- Red
		
		-- Show winner announcement above button
		local winnerName = data.winner == 1 and 'Player A' or 'Player B'
		love.graphics.setColor(1, 1, 0, 1) -- Yellow
		love.graphics.printf(winnerName..' IS THE WINNER!', x + 20, y + 340, popupW - 40, 'center')
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
