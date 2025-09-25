-- New simplified lobby system
local network = require('src.core.network')

local lobby = {}

-- Simple state management
local state = {
    mode = 'menu', -- 'menu', 'host_setup', 'client_setup', 'host_waiting', 'client_waiting'
    hostPort = '25565',
    clientIP = '127.0.0.1',
    clientPort = '25565',
    hostReady = false,
    clientReady = false,
    statusMessage = '',
    errorMessage = '',
    -- Input fields
    inputMode = 'none',
    inputText = '',
    inputCursor = 0,
    inputBlinkTimer = 0
}

-- Initialize
function lobby.init()
    network.init()
    state.mode = 'menu'
    state.hostReady = false
    state.clientReady = false
    state.statusMessage = ''
    state.errorMessage = ''
    print("Lobby: Initialized")
end

-- Draw main lobby
function lobby.draw(gameState)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('MULTIPLAYER LOBBY', 0, 50, w, 'center')
    
    if state.mode == 'menu' then
        lobby.drawMenu(w, h)
    elseif state.mode == 'host_setup' then
        lobby.drawHostSetup(w, h)
    elseif state.mode == 'client_setup' then
        lobby.drawClientSetup(w, h)
    elseif state.mode == 'host_waiting' then
        lobby.drawHostWaiting(w, h)
    elseif state.mode == 'client_waiting' then
        lobby.drawClientWaiting(w, h)
    end
    
    -- Status messages
    if state.errorMessage ~= '' then
        love.graphics.setColor(1, 0.2, 0.2, 1)
        love.graphics.printf(state.errorMessage, 0, h - 100, w, 'center')
    end
    
    if state.statusMessage ~= '' then
        love.graphics.setColor(0.2, 1, 0.2, 1)
        love.graphics.printf(state.statusMessage, 0, h - 80, w, 'center')
    end
end

function lobby.drawMenu(w, h)
    -- Host button
    love.graphics.setColor(0.3, 0.3, 0.8, 1)
    love.graphics.rectangle('fill', w/2 - 100, h/2 - 60, 200, 40)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('HOST GAME', w/2 - 100, h/2 - 50, 200, 'center')
    
    -- Join button
    love.graphics.setColor(0.8, 0.3, 0.3, 1)
    love.graphics.rectangle('fill', w/2 - 100, h/2 - 10, 200, 40)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('JOIN GAME', w/2 - 100, h/2, 200, 'center')
    
    -- Back button
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.rectangle('fill', w/2 - 100, h/2 + 40, 200, 40)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('BACK TO GAME', w/2 - 100, h/2 + 50, 200, 'center')
end

function lobby.drawHostSetup(w, h)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('HOST SETUP', 0, 120, w, 'center')
    
    -- Port input
    love.graphics.printf('Port:', w/2 - 150, 180, 100, 'right')
    lobby.drawInputField(w/2 - 50, 170, 100, 30, 'host_port', state.hostPort)
    
    -- Start Host button
    love.graphics.setColor(0.2, 0.8, 0.2, 1)
    love.graphics.rectangle('fill', w/2 - 75, 220, 150, 40)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('START HOST', w/2 - 75, 230, 150, 'center')
    
    -- Back button
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.rectangle('fill', w/2 - 75, 270, 150, 40)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('BACK', w/2 - 75, 280, 150, 'center')
end

function lobby.drawClientSetup(w, h)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('CLIENT SETUP', 0, 120, w, 'center')
    
    -- IP input
    love.graphics.printf('Host IP:', w/2 - 150, 160, 100, 'right')
    lobby.drawInputField(w/2 - 50, 150, 100, 30, 'client_ip', state.clientIP)
    
    -- Port input
    love.graphics.printf('Port:', w/2 - 150, 200, 100, 'right')
    lobby.drawInputField(w/2 - 50, 190, 100, 30, 'client_port', state.clientPort)
    
    -- Connect button
    love.graphics.setColor(0.2, 0.8, 0.2, 1)
    love.graphics.rectangle('fill', w/2 - 75, 240, 150, 40)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('CONNECT', w/2 - 75, 250, 150, 'center')
    
    -- Back button
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.rectangle('fill', w/2 - 75, 290, 150, 40)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('BACK', w/2 - 75, 300, 150, 'center')
end

function lobby.drawHostWaiting(w, h)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('HOST WAITING', 0, 120, w, 'center')
    
    -- Connection status
    local connStatus = network.isConnected() and 'Client Connected!' or 'Waiting for client...'
    love.graphics.printf(connStatus, 0, 160, w, 'center')
    
    -- Host ready button
    local hostColor = state.hostReady and {0.8, 0.2, 0.2, 1} or {0.2, 0.8, 0.2, 1}
    local hostText = state.hostReady and 'NOT READY' or 'READY'
    love.graphics.setColor(hostColor)
    love.graphics.rectangle('fill', w/2 - 75, 200, 150, 40)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(hostText, w/2 - 75, 210, 150, 'center')
    
    -- Client status
    if network.isConnected() then
        local clientText = state.clientReady and 'READY' or 'NOT READY'
        love.graphics.printf('Client: ' .. clientText, 0, 260, w, 'center')
        
        -- Start game button (only if both ready)
        if state.hostReady and state.clientReady then
            love.graphics.setColor(0.8, 0.8, 0.2, 1)
            love.graphics.rectangle('fill', w/2 - 75, 290, 150, 40)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf('START GAME', w/2 - 75, 300, 150, 'center')
        end
    end
    
    -- Disconnect button
    love.graphics.setColor(0.8, 0.2, 0.2, 1)
    love.graphics.rectangle('fill', w/2 - 75, 350, 150, 40)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('DISCONNECT', w/2 - 75, 360, 150, 'center')
end

function lobby.drawClientWaiting(w, h)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('CLIENT WAITING', 0, 120, w, 'center')
    
    -- Connection status
    local connStatus = network.isConnected() and 'Connected!' or 'Not connected'
    love.graphics.printf('Status: ' .. connStatus, 0, 160, w, 'center')
    
    -- Client ready button (only if connected)
    if network.isConnected() then
        local clientColor = state.clientReady and {0.8, 0.2, 0.2, 1} or {0.2, 0.8, 0.2, 1}
        local clientText = state.clientReady and 'NOT READY' or 'READY'
        love.graphics.setColor(clientColor)
        love.graphics.rectangle('fill', w/2 - 75, 200, 150, 40)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(clientText, w/2 - 75, 210, 150, 'center')
        
        -- Host status
        local hostText = state.hostReady and 'READY' or 'NOT READY'
        love.graphics.printf('Host: ' .. hostText, 0, 260, w, 'center')
    end
    
    -- Disconnect button
    love.graphics.setColor(0.8, 0.2, 0.2, 1)
    love.graphics.rectangle('fill', w/2 - 75, 320, 150, 40)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('DISCONNECT', w/2 - 75, 330, 150, 'center')
end

function lobby.drawInputField(x, y, w, h, mode, value)
    local isActive = state.inputMode == mode
    local color = isActive and {0.3, 0.3, 0.8, 0.5} or {0, 0, 0, 0.3}
    
    love.graphics.setColor(color)
    love.graphics.rectangle('fill', x, y, w, h, 4, 4)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle('line', x, y, w, h, 4, 4)
    
    local text = isActive and state.inputText or value
    love.graphics.printf(text, x + 5, y + 8, w - 10, 'left')
    
    -- Cursor
    if isActive then
        state.inputBlinkTimer = state.inputBlinkTimer + love.timer.getDelta()
        if math.floor(state.inputBlinkTimer * 2) % 2 == 0 then
            local font = love.graphics.getFont()
            local textWidth = font:getWidth(text)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.rectangle('fill', x + 5 + textWidth, y + 8, 1, 16)
        end
    end
end

-- Handle clicks
function lobby.handleClick(x, y, button, gameState)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    if state.mode == 'menu' then
        -- Host button
        if x >= w/2 - 100 and x <= w/2 + 100 and y >= h/2 - 60 and y <= h/2 - 20 then
            state.mode = 'host_setup'
        -- Join button
        elseif x >= w/2 - 100 and x <= w/2 + 100 and y >= h/2 - 10 and y <= h/2 + 30 then
            state.mode = 'client_setup'
        -- Back button
        elseif x >= w/2 - 100 and x <= w/2 + 100 and y >= h/2 + 40 and y <= h/2 + 80 then
            gameState.phase = 'menu'
        end
        
    elseif state.mode == 'host_setup' then
        -- Port input
        if x >= w/2 - 50 and x <= w/2 + 50 and y >= 170 and y <= 200 then
            state.inputMode = 'host_port'
            state.inputText = state.hostPort
            state.inputBlinkTimer = 0
        -- Start Host button
        elseif x >= w/2 - 75 and x <= w/2 + 75 and y >= 220 and y <= 260 then
            lobby.startHost()
        -- Back button
        elseif x >= w/2 - 75 and x <= w/2 + 75 and y >= 270 and y <= 310 then
            state.mode = 'menu'
        else
            state.inputMode = 'none'
        end
        
    elseif state.mode == 'client_setup' then
        -- IP input
        if x >= w/2 - 50 and x <= w/2 + 50 and y >= 150 and y <= 180 then
            state.inputMode = 'client_ip'
            state.inputText = state.clientIP
            state.inputBlinkTimer = 0
        -- Port input
        elseif x >= w/2 - 50 and x <= w/2 + 50 and y >= 190 and y <= 220 then
            state.inputMode = 'client_port'
            state.inputText = state.clientPort
            state.inputBlinkTimer = 0
        -- Connect button
        elseif x >= w/2 - 75 and x <= w/2 + 75 and y >= 240 and y <= 280 then
            lobby.connectToHost()
        -- Back button
        elseif x >= w/2 - 75 and x <= w/2 + 75 and y >= 290 and y <= 330 then
            state.mode = 'menu'
        else
            state.inputMode = 'none'
        end
        
    elseif state.mode == 'host_waiting' then
        -- Host ready button
        if x >= w/2 - 75 and x <= w/2 + 75 and y >= 200 and y <= 240 then
            lobby.toggleHostReady()
        -- Start game button
        elseif x >= w/2 - 75 and x <= w/2 + 75 and y >= 290 and y <= 330 then
            lobby.startGame(gameState)
        -- Disconnect button
        elseif x >= w/2 - 75 and x <= w/2 + 75 and y >= 350 and y <= 390 then
            lobby.disconnect()
        end
        
    elseif state.mode == 'client_waiting' then
        -- Client ready button
        if x >= w/2 - 75 and x <= w/2 + 75 and y >= 200 and y <= 240 then
            lobby.toggleClientReady()
        -- Disconnect button
        elseif x >= w/2 - 75 and x <= w/2 + 75 and y >= 320 and y <= 360 then
            lobby.disconnect()
        end
    end
end

-- Handle keyboard input
function lobby.handleKeyInput(key)
    if state.inputMode == 'none' then
        return
    end
    
    if key == 'backspace' then
        state.inputText = state.inputText:sub(1, -2)
    elseif key == 'return' then
        lobby.saveInput()
    elseif key == 'escape' then
        state.inputMode = 'none'
    end
end

function lobby.handleTextInput(text)
    if state.inputMode == 'none' then
        return
    end
    
    -- Only allow numbers and dots for IP/port
    if state.inputMode == 'host_port' or state.inputMode == 'client_port' then
        if text:match('%d') then
            state.inputText = state.inputText .. text
        end
    elseif state.inputMode == 'client_ip' then
        if text:match('[%d%.]') then
            state.inputText = state.inputText .. text
        end
    end
end

function lobby.saveInput()
    if state.inputMode == 'host_port' then
        state.hostPort = state.inputText
    elseif state.inputMode == 'client_ip' then
        state.clientIP = state.inputText
    elseif state.inputMode == 'client_port' then
        state.clientPort = state.inputText
    end
    state.inputMode = 'none'
end

-- Network functions
function lobby.startHost()
    local port = tonumber(state.hostPort) or 25565
    local success, message = network.startHost(port)
    
    if success then
        state.mode = 'host_waiting'
        state.statusMessage = message
        state.errorMessage = ''
        print("Host started on port", port)
        
        -- Set callback for when client connects
        network.setOnClientConnected(function()
            print("Client connected!")
            -- Send initial ready status
            network.sendMessage("READY:" .. (state.hostReady and "1" or "0"))
        end)
    else
        state.errorMessage = message
        print("Host start failed:", message)
    end
end

function lobby.connectToHost()
    local ip = state.clientIP
    local port = tonumber(state.clientPort) or 25565
    local success, message = network.connectToHost(ip, port)
    
    if success then
        state.mode = 'client_waiting'
        state.statusMessage = message
        state.errorMessage = ''
        print("Connecting to", ip .. ":" .. port)
    else
        state.errorMessage = message
        print("Connection failed:", message)
    end
end

function lobby.toggleHostReady()
    state.hostReady = not state.hostReady
    if network.isConnected() then
        network.sendMessage("READY:" .. (state.hostReady and "1" or "0"))
        print("Host ready:", state.hostReady)
    end
end

function lobby.toggleClientReady()
    state.clientReady = not state.clientReady
    if network.isConnected() then
        network.sendMessage("READY:" .. (state.clientReady and "1" or "0"))
        print("Client ready:", state.clientReady)
    end
end

function lobby.startGame(gameState)
    if state.hostReady and state.clientReady then
        network.sendMessage("START_GAME")
        gameState.phase = 'deckbuilder'
        gameState.multiplayer = true
        gameState.networkPlayerId = 1
        -- Initialize deck selection tracking
        gameState.deckSelectionComplete = {false, false}
        gameState.deckConfirmed = {false, false}
        print("Game starting!")
    end
end

function lobby.disconnect()
    network.disconnect()
    state.mode = 'menu'
    state.hostReady = false
    state.clientReady = false
    state.statusMessage = ''
    state.errorMessage = ''
    print("Disconnected")
end

-- Update function
function lobby.update(dt)
    network.update(dt)
    
    -- Process messages
    local messages = network.getMessages()
    for _, msg in ipairs(messages) do
        lobby.handleMessage(msg)
    end
end

function lobby.handleMessage(message)
    if message:match("^READY:") then
        local ready = message:match("READY:(%d)") == "1"
        if network.isHost() then
            state.clientReady = ready
            print("Client ready:", ready)
        else
            state.hostReady = ready
            print("Host ready:", ready)
        end
    elseif message == "START_GAME" then
        print("Game starting from lobby - going to deckbuilder!")
        local gameState = require('src.core.state').get()
        gameState.waitingForOpponent = false
        gameState.phase = 'deckbuilder'
        gameState.multiplayer = true
        gameState.networkPlayerId = 2
    elseif message == "START_SETUP_PHASE" then
        print("Setup phase starting from deckbuilder!")
        local gameState = require('src.core.state').get()
        gameState.waitingForOpponent = false
        local game = require('src.core.game')
        game.startGame()
    else
        -- Handle structured messages
        local decodedMessage = network.decodeMessage(message)
        if decodedMessage then
            print('Lobby handling structured message: ' .. decodedMessage.type)
            local gameState = require('src.core.state').get()
            local game = require('src.core.game')
            game.handleNetworkMessage(decodedMessage, gameState)
        end
    end
end

return lobby
