-- Simple lobby for multiplayer
local network = require('src.core.network')

local lobby = {}

-- Lobby state
local state = {
    mode = 'menu', -- 'menu', 'host', 'client', 'waiting'
    hostPort = '25565',
    clientIP = '127.0.0.1',
    clientPort = '25565',
    hostReady = false,
    clientReady = false,
    errorMessage = '',
    statusMessage = '',
    -- Input handling
    inputMode = 'none', -- 'none', 'host_port', 'client_ip', 'client_port'
    inputText = '',
    inputCursor = 0,
    inputBlinkTimer = 0,
    -- Click protection
    lastClickTime = 0,
    clickCooldown = 0.2 -- 200ms cooldown between clicks
}

-- Initialize
function lobby.init()
    network.init()
    state.mode = 'menu'
    state.hostReady = false
    state.clientReady = false
    state.errorMessage = ''
    state.statusMessage = ''
    print("Lobby: Initialized")
end

-- Draw lobby
function lobby.draw(gameState)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('MULTIPLAYER LOBBY', 0, 50, w, 'center')
    
    if state.mode == 'menu' then
        lobby.drawMenu(w, h)
    elseif state.mode == 'host' then
        lobby.drawHost(w, h)
    elseif state.mode == 'client' then
        lobby.drawClient(w, h)
    elseif state.mode == 'waiting' then
        lobby.drawWaiting(w, h)
    end
    
    -- Error message
    if state.errorMessage ~= '' then
        love.graphics.setColor(1, 0.2, 0.2, 1)
        love.graphics.printf(state.errorMessage, 0, h - 100, w, 'center')
    end
    
    -- Status message
    if state.statusMessage ~= '' then
        love.graphics.setColor(0.2, 1, 0.2, 1)
        love.graphics.printf(state.statusMessage, 0, h - 80, w, 'center')
    end
end

function lobby.drawMenu(w, h)
    love.graphics.setColor(0.3, 0.3, 0.8, 1)
    love.graphics.rectangle('fill', w/2 - 100, h/2 - 60, 200, 40)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('HOST GAME', w/2 - 100, h/2 - 50, 200, 'center')
    
    love.graphics.setColor(0.8, 0.3, 0.3, 1)
    love.graphics.rectangle('fill', w/2 - 100, h/2 - 10, 200, 40)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('JOIN GAME', w/2 - 100, h/2, 200, 'center')
    
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.rectangle('fill', w/2 - 100, h/2 + 40, 200, 40)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('BACK TO GAME', w/2 - 100, h/2 + 50, 200, 'center')
end

function lobby.drawHost(w, h)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('HOST GAME', 0, 120, w, 'center')
    
    -- Port input field
    local portInputX = w/2 - 100
    local portInputY = 160
    local portInputW = 200
    local portInputH = 30
    
    -- Draw port label
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('Port:', portInputX - 80, portInputY + 8, 70, 'right')
    
    -- Draw port input box
    local portColor = state.inputMode == 'host_port' and {0.3, 0.3, 0.8, 0.5} or {0, 0, 0, 0.3}
    love.graphics.setColor(portColor)
    love.graphics.rectangle('fill', portInputX, portInputY, portInputW, portInputH, 4, 4)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle('line', portInputX, portInputY, portInputW, portInputH, 4, 4)
    
    -- Draw port text
    local portText = state.inputMode == 'host_port' and state.inputText or state.hostPort
    love.graphics.printf(portText, portInputX + 5, portInputY + 8, portInputW - 10, 'left')
    
    -- Draw cursor for port input
    if state.inputMode == 'host_port' then
        state.inputBlinkTimer = state.inputBlinkTimer + love.timer.getDelta()
        if math.floor(state.inputBlinkTimer * 2) % 2 == 0 then
            local font = love.graphics.getFont()
            local textWidth = font:getWidth(portText)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.rectangle('fill', portInputX + 5 + textWidth, portInputY + 8, 1, 16)
        end
    end
    
    -- Store input bounds for click detection
    state.hostPortInput = {x = portInputX, y = portInputY, w = portInputW, h = portInputH}
    
    -- Start Host button
    if not network.isHost() then
        love.graphics.setColor(0.2, 0.8, 0.2, 1)
        love.graphics.rectangle('fill', w/2 - 75, 210, 150, 40)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf('START HOST', w/2 - 75, 220, 150, 'center')
        state.startHostButton = {x = w/2 - 75, y = 210, w = 150, h = 40}
    else
        local connStatus = network.isConnected() and 'Client Connected!' or 'Waiting for client...'
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(connStatus, 0, 220, w, 'center')
        
        local readyStatus = state.hostReady and 'READY' or 'NOT READY'
        love.graphics.printf('Host Status: ' .. readyStatus, 0, 250, w, 'center')
        
        if network.isConnected() then
            local clientStatus = state.clientReady and 'READY' or 'NOT READY'
            love.graphics.printf('Client Status: ' .. clientStatus, 0, 270, w, 'center')
        end
        
        -- Ready button
        local buttonColor = state.hostReady and {0.8, 0.2, 0.2, 1} or {0.2, 0.8, 0.2, 1}
        local buttonText = state.hostReady and 'NOT READY' or 'READY'
        love.graphics.setColor(buttonColor)
        love.graphics.rectangle('fill', w/2 - 75, 300, 150, 40)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(buttonText, w/2 - 75, 310, 150, 'center')
        state.hostReadyButton = {x = w/2 - 75, y = 300, w = 150, h = 40}
        
        -- Start game button (if both ready)
        if state.hostReady and state.clientReady and network.isConnected() then
            love.graphics.setColor(0.2, 0.8, 0.2, 1)
            love.graphics.rectangle('fill', w/2 - 75, 350, 150, 40)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf('START GAME', w/2 - 75, 360, 150, 'center')
            state.startGameButton = {x = w/2 - 75, y = 350, w = 150, h = 40}
        end
    end
end

function lobby.drawClient(w, h)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('JOIN GAME', 0, 120, w, 'center')
    
    -- IP input field
    local ipInputX = w/2 - 100
    local ipInputY = 160
    local ipInputW = 200
    local ipInputH = 30
    
    -- Draw IP label
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('Host IP:', ipInputX - 80, ipInputY + 8, 70, 'right')
    
    -- Draw IP input box
    local ipColor = state.inputMode == 'client_ip' and {0.3, 0.3, 0.8, 0.5} or {0, 0, 0, 0.3}
    love.graphics.setColor(ipColor)
    love.graphics.rectangle('fill', ipInputX, ipInputY, ipInputW, ipInputH, 4, 4)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle('line', ipInputX, ipInputY, ipInputW, ipInputH, 4, 4)
    
    -- Draw IP text
    local ipText = state.inputMode == 'client_ip' and state.inputText or state.clientIP
    love.graphics.printf(ipText, ipInputX + 5, ipInputY + 8, ipInputW - 10, 'left')
    
    -- Draw cursor for IP input
    if state.inputMode == 'client_ip' then
        state.inputBlinkTimer = state.inputBlinkTimer + love.timer.getDelta()
        if math.floor(state.inputBlinkTimer * 2) % 2 == 0 then
            local font = love.graphics.getFont()
            local textWidth = font:getWidth(ipText)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.rectangle('fill', ipInputX + 5 + textWidth, ipInputY + 8, 1, 16)
        end
    end
    
    -- Port input field
    local portInputX = w/2 - 100
    local portInputY = 200
    local portInputW = 200
    local portInputH = 30
    
    -- Draw Port label
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('Port:', portInputX - 80, portInputY + 8, 70, 'right')
    
    -- Draw Port input box
    local portColor = state.inputMode == 'client_port' and {0.3, 0.3, 0.8, 0.5} or {0, 0, 0, 0.3}
    love.graphics.setColor(portColor)
    love.graphics.rectangle('fill', portInputX, portInputY, portInputW, portInputH, 4, 4)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle('line', portInputX, portInputY, portInputW, portInputH, 4, 4)
    
    -- Draw Port text
    local portText = state.inputMode == 'client_port' and state.inputText or state.clientPort
    love.graphics.printf(portText, portInputX + 5, portInputY + 8, portInputW - 10, 'left')
    
    -- Draw cursor for Port input
    if state.inputMode == 'client_port' then
        state.inputBlinkTimer = state.inputBlinkTimer + love.timer.getDelta()
        if math.floor(state.inputBlinkTimer * 2) % 2 == 0 then
            local font = love.graphics.getFont()
            local textWidth = font:getWidth(portText)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.rectangle('fill', portInputX + 5 + textWidth, portInputY + 8, 1, 16)
        end
    end
    
    -- Store input bounds for click detection
    state.clientIPInput = {x = ipInputX, y = ipInputY, w = ipInputW, h = ipInputH}
    state.clientPortInput = {x = portInputX, y = portInputY, w = portInputW, h = portInputH}
    
    local connStatus = network.isConnected() and 'Connected!' or 'Not connected'
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('Status: ' .. connStatus, 0, 250, w, 'center')
    
    -- Connect button
    if not network.isConnected() then
        love.graphics.setColor(0.2, 0.8, 0.2, 1)
        love.graphics.rectangle('fill', w/2 - 75, 280, 150, 40)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf('CONNECT', w/2 - 75, 290, 150, 'center')
        state.connectButton = {x = w/2 - 75, y = 280, w = 150, h = 40}
    else
        -- Ready button
        local buttonColor = state.clientReady and {0.8, 0.2, 0.2, 1} or {0.2, 0.8, 0.2, 1}
        local buttonText = state.clientReady and 'NOT READY' or 'READY'
        love.graphics.setColor(buttonColor)
        love.graphics.rectangle('fill', w/2 - 75, 280, 150, 40)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(buttonText, w/2 - 75, 290, 150, 'center')
        state.clientReadyButton = {x = w/2 - 75, y = 280, w = 150, h = 40}
        
        local hostStatus = state.hostReady and 'READY' or 'NOT READY'
        love.graphics.printf('Host Status: ' .. hostStatus, 0, 330, w, 'center')
    end
end

function lobby.drawWaiting(w, h)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('WAITING FOR GAME TO START...', 0, h/2, w, 'center')
end

-- Handle clicks
function lobby.handleClick(x, y, button, gameState)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local currentTime = love.timer.getTime()
    
    -- Click cooldown protection
    if currentTime - state.lastClickTime < state.clickCooldown then
        return
    end
    state.lastClickTime = currentTime
    
    if state.mode == 'menu' then
        -- Host button
        if x >= w/2 - 100 and x <= w/2 + 100 and y >= h/2 - 60 and y <= h/2 - 20 then
            print("Lobby: Host button clicked")
            state.mode = 'host'
        -- Join button
        elseif x >= w/2 - 100 and x <= w/2 + 100 and y >= h/2 - 10 and y <= h/2 + 30 then
            print("Lobby: Join button clicked")
            state.mode = 'client'
        -- Back button
        elseif x >= w/2 - 100 and x <= w/2 + 100 and y >= h/2 + 40 and y <= h/2 + 80 then
            print("Lobby: Back button clicked")
            gameState.phase = 'menu'
        end
        
    elseif state.mode == 'host' then
        -- Check input field clicks
        if state.hostPortInput and x >= state.hostPortInput.x and x <= state.hostPortInput.x + state.hostPortInput.w and
           y >= state.hostPortInput.y and y <= state.hostPortInput.y + state.hostPortInput.h then
            state.inputMode = 'host_port'
            state.inputText = state.hostPort
            state.inputBlinkTimer = 0
        -- Start Host button
        elseif state.startHostButton and x >= state.startHostButton.x and x <= state.startHostButton.x + state.startHostButton.w and
               y >= state.startHostButton.y and y <= state.startHostButton.y + state.startHostButton.h then
            lobby.startHost()
        -- Ready button
        elseif state.hostReadyButton and x >= state.hostReadyButton.x and x <= state.hostReadyButton.x + state.hostReadyButton.w and
               y >= state.hostReadyButton.y and y <= state.hostReadyButton.y + state.hostReadyButton.h then
            state.hostReady = not state.hostReady
            if network.isConnected() then
                local message = "READY:" .. (state.hostReady and "1" or "0")
                network.sendMessage(message)
                print("Lobby: Host ready:", state.hostReady)
            end
        -- Start game button
        elseif state.startGameButton and x >= state.startGameButton.x and x <= state.startGameButton.x + state.startGameButton.w and
               y >= state.startGameButton.y and y <= state.startGameButton.y + state.startGameButton.h then
            network.sendMessage("START_GAME")
            gameState.phase = 'deckbuilder'
            gameState.multiplayer = true
            gameState.networkPlayerId = 1
        else
            -- Click outside, save input
            if state.inputMode == 'host_port' then
                state.hostPort = state.inputText
                state.inputMode = 'none'
            end
        end
        
    elseif state.mode == 'client' then
        -- Check input field clicks
        if state.clientIPInput and x >= state.clientIPInput.x and x <= state.clientIPInput.x + state.clientIPInput.w and
           y >= state.clientIPInput.y and y <= state.clientIPInput.y + state.clientIPInput.h then
            state.inputMode = 'client_ip'
            state.inputText = state.clientIP
            state.inputBlinkTimer = 0
        elseif state.clientPortInput and x >= state.clientPortInput.x and x <= state.clientPortInput.x + state.clientPortInput.w and
               y >= state.clientPortInput.y and y <= state.clientPortInput.y + state.clientPortInput.h then
            state.inputMode = 'client_port'
            state.inputText = state.clientPort
            state.inputBlinkTimer = 0
        -- Connect button
        elseif state.connectButton and x >= state.connectButton.x and x <= state.connectButton.x + state.connectButton.w and
               y >= state.connectButton.y and y <= state.connectButton.y + state.connectButton.h then
            lobby.connectToHost()
        -- Ready button
        elseif state.clientReadyButton and x >= state.clientReadyButton.x and x <= state.clientReadyButton.x + state.clientReadyButton.w and
               y >= state.clientReadyButton.y and y <= state.clientReadyButton.y + state.clientReadyButton.h then
            state.clientReady = not state.clientReady
            local message = "READY:" .. (state.clientReady and "1" or "0")
            network.sendMessage(message)
            print("Lobby: Client ready:", state.clientReady)
        else
            -- Click outside, save input
            if state.inputMode == 'client_ip' then
                state.clientIP = state.inputText
                state.inputMode = 'none'
            elseif state.inputMode == 'client_port' then
                state.clientPort = state.inputText
                state.inputMode = 'none'
            end
        end
    end
end

-- Start hosting
function lobby.startHost()
    print("Lobby: Starting host...")
    local port = tonumber(state.hostPort) or 12345
    local success, message = network.startHost(port)
    
    if success then
        state.mode = 'host'
        state.statusMessage = message
        state.errorMessage = ''
        print("Lobby: Host started successfully")
        
        -- Set callback to send ready status when client connects
        network.setOnClientConnected(function()
            local message = "READY:" .. (state.hostReady and "1" or "0")
            network.sendMessage(message)
            print("Lobby: Sent initial ready status to client:", message)
        end)
    else
        state.errorMessage = message
        print("Lobby: Host start failed:", message)
    end
end

-- Connect to host
function lobby.connectToHost()
    print("Lobby: Connecting to host...")
    local ip = state.clientIP
    local port = tonumber(state.clientPort) or 12345
    local success, message = network.connectToHost(ip, port)
    
    if success then
        state.statusMessage = message
        state.errorMessage = ''
        print("Lobby: Connection attempt started")
    else
        state.errorMessage = message
        print("Lobby: Connection failed:", message)
    end
end

-- Update lobby
function lobby.update(dt)
    network.update(dt)
    
    -- Process received messages
    local messages = network.getMessages()
    for _, msg in ipairs(messages) do
        lobby.handleMessage(msg)
    end
end

-- Handle received messages
function lobby.handleMessage(message)    
    if message:match("^READY:") then
        local readyStr = message:match("READY:(%d)")
        local ready = readyStr == "1"
        if network.isHost() then
            state.clientReady = ready
        else
            state.hostReady = ready
            print("Lobby: Host ready status updated:", ready)
        end
    elseif message == "START_GAME" then
        print("Lobby: Game starting...")
        local gameState = require('src.core.state').get()
        gameState.phase = 'deckbuilder'
        gameState.multiplayer = true
        gameState.networkPlayerId = 2 -- Client is player 2
    end
end

-- Handle keyboard input
function lobby.handleKeyInput(key)
    if state.inputMode ~= 'none' then
        if key == 'backspace' then
            state.inputText = state.inputText:sub(1, -2)
        elseif key == 'return' or key == 'enter' then
            -- Save input and exit input mode
            if state.inputMode == 'host_port' then
                state.hostPort = state.inputText
            elseif state.inputMode == 'client_ip' then
                state.clientIP = state.inputText
            elseif state.inputMode == 'client_port' then
                state.clientPort = state.inputText
            end
            state.inputMode = 'none'
        elseif key == 'escape' then
            -- Cancel input
            state.inputMode = 'none'
        end
        state.inputBlinkTimer = 0
        return true
    end
    return false
end

-- Handle text input
function lobby.handleTextInput(text)
    if state.inputMode ~= 'none' then
        -- Only allow certain characters based on input type
        if state.inputMode == 'host_port' or state.inputMode == 'client_port' then
            -- Only allow digits for port
            if text:match('^%d$') and #state.inputText < 5 then
                state.inputText = state.inputText .. text
            end
        elseif state.inputMode == 'client_ip' then
            -- Allow digits, dots, and letters for IP/hostname
            if text:match('^[%w%.]$') and #state.inputText < 50 then
                state.inputText = state.inputText .. text
            end
        end
        state.inputBlinkTimer = 0
        return true
    end
    return false
end

return lobby
