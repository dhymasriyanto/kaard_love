local lobby = {}

-- Lobby state
local lobbyState = {
    mode = 'menu', -- 'menu', 'host', 'client', 'waiting', 'ready'
    hostIP = 'localhost',
    hostPort = '12345',
    connectionStatus = '',
    errorMessage = '',
    hostReady = false,
    clientReady = false,
    bothReady = false,
    inputMode = 'none', -- 'none', 'ip', 'port'
    inputText = '',
    inputCursor = 0,
    inputBlinkTimer = 0
}

-- UI elements
local lobbyElements = {
    hostButton = {x = 0, y = 0, w = 200, h = 50},
    clientButton = {x = 0, y = 0, w = 200, h = 50},
    ipInput = {x = 0, y = 0, w = 200, h = 30},
    connectButton = {x = 0, y = 0, w = 100, h = 30},
    backButton = {x = 0, y = 0, w = 100, h = 30},
    startButton = {x = 0, y = 0, w = 150, h = 40},
    readyButton = {x = 0, y = 0, w = 150, h = 40}
}

-- Initialize lobby
function lobby.init()
    lobbyState.mode = 'menu'
    lobbyState.hostIP = 'localhost'
    lobbyState.hostPort = '12345'
    lobbyState.connectionStatus = ''
    lobbyState.errorMessage = ''
    lobbyState.hostReady = false
    lobbyState.clientReady = false
    lobbyState.bothReady = false
    lobbyState.inputMode = 'none'
    lobbyState.inputText = ''
    lobbyState.inputCursor = 0
    lobbyState.inputBlinkTimer = 0
end

-- Draw lobby UI
function lobby.draw(state)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('Multiplayer Lobby', w*0.5 - 200, 50, 400, 'center')
    
    if lobbyState.mode == 'menu' then
        lobby.drawMainMenu(w, h)
    elseif lobbyState.mode == 'host' then
        lobby.drawHostLobby(w, h, state)
    elseif lobbyState.mode == 'client' then
        lobby.drawClientLobby(w, h, state)
    elseif lobbyState.mode == 'waiting' then
        lobby.drawWaitingLobby(w, h, state)
    elseif lobbyState.mode == 'ready' then
        lobby.drawReadyLobby(w, h, state)
    end
    
    -- Draw error message if any
    if lobbyState.errorMessage ~= '' then
        love.graphics.setColor(0.8, 0.2, 0.2, 1)
        love.graphics.printf(lobbyState.errorMessage, w*0.5 - 200, h - 100, 400, 'center')
    end
    
    -- Draw connection status
    if lobbyState.connectionStatus ~= '' then
        love.graphics.setColor(0.2, 0.8, 0.2, 1)
        love.graphics.printf(lobbyState.connectionStatus, w*0.5 - 200, h - 80, 400, 'center')
    end
end

-- Draw main menu
function lobby.drawMainMenu(w, h)
    -- Host button
    lobbyElements.hostButton.x = w*0.5 - lobbyElements.hostButton.w - 10
    lobbyElements.hostButton.y = h*0.5 - 50
    
    love.graphics.setColor(0.2, 0.8, 0.2, 0.8)
    love.graphics.rectangle('fill', lobbyElements.hostButton.x, lobbyElements.hostButton.y, 
                           lobbyElements.hostButton.w, lobbyElements.hostButton.h, 8, 8)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle('line', lobbyElements.hostButton.x, lobbyElements.hostButton.y, 
                          lobbyElements.hostButton.w, lobbyElements.hostButton.h, 8, 8)
    love.graphics.printf('Host Game', lobbyElements.hostButton.x, lobbyElements.hostButton.y + 15, 
                        lobbyElements.hostButton.w, 'center')
    
    -- Client button
    lobbyElements.clientButton.x = w*0.5 + 10
    lobbyElements.clientButton.y = h*0.5 - 50
    
    love.graphics.setColor(0.2, 0.2, 0.8, 0.8)
    love.graphics.rectangle('fill', lobbyElements.clientButton.x, lobbyElements.clientButton.y, 
                           lobbyElements.clientButton.w, lobbyElements.clientButton.h, 8, 8)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle('line', lobbyElements.clientButton.x, lobbyElements.clientButton.y, 
                          lobbyElements.clientButton.w, lobbyElements.clientButton.h, 8, 8)
    love.graphics.printf('Join Game', lobbyElements.clientButton.x, lobbyElements.clientButton.y + 15, 
                        lobbyElements.clientButton.w, 'center')
    
    -- Back button
    lobbyElements.backButton.x = 20
    lobbyElements.backButton.y = h - 50
    
    love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
    love.graphics.rectangle('fill', lobbyElements.backButton.x, lobbyElements.backButton.y, 
                           lobbyElements.backButton.w, lobbyElements.backButton.h, 8, 8)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('Back', lobbyElements.backButton.x, lobbyElements.backButton.y + 8, 
                        lobbyElements.backButton.w, 'center')
end

-- Draw host lobby
function lobby.drawHostLobby(w, h, state)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('Host Game', w*0.5 - 200, 80, 400, 'center')
    
    -- Port input
    local portInput = {x = w*0.5 - 100, y = 120, w = 200, h = 30}
    
    local portColor = lobbyState.inputMode == 'port' and {0.3, 0.3, 0.8, 0.5} or {0, 0, 0, 0.3}
    love.graphics.setColor(portColor)
    love.graphics.rectangle('fill', portInput.x, portInput.y, portInput.w, portInput.h, 4, 4)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle('line', portInput.x, portInput.y, portInput.w, portInput.h, 4, 4)
    
    -- Port text with cursor
    local portText = lobbyState.inputMode == 'port' and lobbyState.inputText or lobbyState.hostPort
    love.graphics.printf(portText, portInput.x + 5, portInput.y + 8, portInput.w - 10, 'left')
    
    -- Draw cursor for port input
    if lobbyState.inputMode == 'port' then
        lobbyState.inputBlinkTimer = lobbyState.inputBlinkTimer + love.timer.getDelta()
        if math.floor(lobbyState.inputBlinkTimer * 2) % 2 == 0 then
            local font = love.graphics.getFont()
            local textWidth = font:getWidth(portText)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.rectangle('fill', portInput.x + 5 + textWidth, portInput.y + 8, 1, 16)
        end
    end
    
    -- Label
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('Port:', portInput.x - 80, portInput.y + 8, 70, 'right')
    
    -- Start Host button
    local startHostButton = {x = w*0.5 - 100, y = portInput.y + 50, w = 200, h = 40}
    
    love.graphics.setColor(0.2, 0.8, 0.2, 0.8)
    love.graphics.rectangle('fill', startHostButton.x, startHostButton.y, startHostButton.w, startHostButton.h, 8, 8)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('Start Host', startHostButton.x, startHostButton.y + 8, startHostButton.w, 'center')
    
    -- Store button position for click handling
    lobbyElements.startHostButton = startHostButton
    
    -- Connection status (only show if host is started)
    if state.network and state.network.isHost() then
        local connectionStatus = 'Waiting for players...'
        local connectionColor = {0.8, 0.8, 0.2, 1}
        if state.network.isConnected() then
            connectionStatus = 'Client connected!'
            connectionColor = {0.2, 0.8, 0.2, 1}
        end
        
        love.graphics.setColor(connectionColor)
        love.graphics.printf(connectionStatus, w*0.5 - 200, startHostButton.y + 60, 400, 'center')
        
        -- Show current port
        local currentPort = state.network.getCurrentPort()
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        love.graphics.printf('Listening on port: ' .. currentPort, w*0.5 - 200, startHostButton.y + 80, 400, 'center')
    end
    
    -- Ready status section (only show if host is started)
    if state.network and state.network.isHost() then
        local readySectionY = startHostButton.y + 120
        
        -- Host ready status
        local readyText = 'Not Ready'
        local readyColor = {0.8, 0.2, 0.2, 1}
        if lobbyState.hostReady then
            readyText = 'Ready'
            readyColor = {0.2, 0.8, 0.2, 1}
        end
        
        love.graphics.setColor(readyColor)
        love.graphics.printf('Host: ' .. readyText, w*0.5 - 200, readySectionY, 400, 'center')
        
        -- Client status
        local clientText = 'No Client Connected'
        local clientColor = {0.5, 0.5, 0.5, 1}
        if state.network.isConnected() then
            clientText = lobbyState.clientReady and 'Client Ready' or 'Client Not Ready'
            clientColor = lobbyState.clientReady and {0.2, 0.8, 0.2, 1} or {0.8, 0.8, 0.2, 1}
        end
        
        love.graphics.setColor(clientColor)
        love.graphics.printf('Client: ' .. clientText, w*0.5 - 200, readySectionY + 25, 400, 'center')
        
        -- Ready button
        local readyButtonY = readySectionY + 60
        lobbyElements.readyButton.x = w*0.5 - lobbyElements.readyButton.w*0.5
        lobbyElements.readyButton.y = readyButtonY
        
        local buttonColor = lobbyState.hostReady and {0.8, 0.2, 0.2, 0.8} or {0.2, 0.8, 0.2, 0.8}
        local buttonText = lobbyState.hostReady and 'Not Ready' or 'Ready'
        
        love.graphics.setColor(buttonColor)
        love.graphics.rectangle('fill', lobbyElements.readyButton.x, lobbyElements.readyButton.y, 
                               lobbyElements.readyButton.w, lobbyElements.readyButton.h, 8, 8)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(buttonText, lobbyElements.readyButton.x, lobbyElements.readyButton.y + 12, 
                            lobbyElements.readyButton.w, 'center')
        
        -- Start game button (only visible when both ready)
        if lobbyState.bothReady then
            local startGameButtonY = readyButtonY + 50
            lobbyElements.startButton.x = w*0.5 - lobbyElements.startButton.w*0.5
            lobbyElements.startButton.y = startGameButtonY
            
            love.graphics.setColor(0.2, 0.8, 0.2, 0.8)
            love.graphics.rectangle('fill', lobbyElements.startButton.x, lobbyElements.startButton.y, 
                                   lobbyElements.startButton.w, lobbyElements.startButton.h, 8, 8)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf('Start Game', lobbyElements.startButton.x, lobbyElements.startButton.y + 12, 
                                lobbyElements.startButton.w, 'center')
        end
    end
    
    -- Back button
    lobbyElements.backButton.x = 20
    lobbyElements.backButton.y = h - 50
    
    love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
    love.graphics.rectangle('fill', lobbyElements.backButton.x, lobbyElements.backButton.y, 
                           lobbyElements.backButton.w, lobbyElements.backButton.h, 8, 8)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('Back', lobbyElements.backButton.x, lobbyElements.backButton.y + 8, 
                        lobbyElements.backButton.w, 'center')
end

-- Draw client lobby
function lobby.drawClientLobby(w, h, state)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('Join Game', w*0.5 - 200, 80, 400, 'center')
    
    -- IP input
    lobbyElements.ipInput.x = w*0.5 - lobbyElements.ipInput.w*0.5
    lobbyElements.ipInput.y = 120
    
    local ipColor = lobbyState.inputMode == 'ip' and {0.3, 0.3, 0.8, 0.5} or {0, 0, 0, 0.3}
    love.graphics.setColor(ipColor)
    love.graphics.rectangle('fill', lobbyElements.ipInput.x, lobbyElements.ipInput.y, 
                           lobbyElements.ipInput.w, lobbyElements.ipInput.h, 4, 4)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle('line', lobbyElements.ipInput.x, lobbyElements.ipInput.y, 
                          lobbyElements.ipInput.w, lobbyElements.ipInput.h, 4, 4)
    
    -- IP text with cursor
    local ipText = lobbyState.inputMode == 'ip' and lobbyState.inputText or lobbyState.hostIP
    love.graphics.printf(ipText, lobbyElements.ipInput.x + 5, lobbyElements.ipInput.y + 8, 
                        lobbyElements.ipInput.w - 10, 'left')
    
    -- Draw cursor for IP input
    if lobbyState.inputMode == 'ip' then
        lobbyState.inputBlinkTimer = lobbyState.inputBlinkTimer + love.timer.getDelta()
        if math.floor(lobbyState.inputBlinkTimer * 2) % 2 == 0 then
            local font = love.graphics.getFont()
            local textWidth = font:getWidth(ipText)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.rectangle('fill', lobbyElements.ipInput.x + 5 + textWidth, lobbyElements.ipInput.y + 8, 1, 16)
        end
    end
    
    -- Port input
    local portInput = {x = lobbyElements.ipInput.x, y = lobbyElements.ipInput.y + 40, w = 100, h = 30}
    
    local portColor = lobbyState.inputMode == 'port' and {0.3, 0.3, 0.8, 0.5} or {0, 0, 0, 0.3}
    love.graphics.setColor(portColor)
    love.graphics.rectangle('fill', portInput.x, portInput.y, portInput.w, portInput.h, 4, 4)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle('line', portInput.x, portInput.y, portInput.w, portInput.h, 4, 4)
    
    -- Port text with cursor
    local portText = lobbyState.inputMode == 'port' and lobbyState.inputText or lobbyState.hostPort
    love.graphics.printf(portText, portInput.x + 5, portInput.y + 8, portInput.w - 10, 'left')
    
    -- Draw cursor for port input
    if lobbyState.inputMode == 'port' then
        if math.floor(lobbyState.inputBlinkTimer * 2) % 2 == 0 then
            local font = love.graphics.getFont()
            local textWidth = font:getWidth(portText)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.rectangle('fill', portInput.x + 5 + textWidth, portInput.y + 8, 1, 16)
        end
    end
    
    -- Labels
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('IP Address:', lobbyElements.ipInput.x - 80, lobbyElements.ipInput.y + 8, 70, 'right')
    love.graphics.printf('Port:', portInput.x - 80, portInput.y + 8, 70, 'right')
    
    -- Connect button
    lobbyElements.connectButton.x = w*0.5 - lobbyElements.connectButton.w*0.5
    lobbyElements.connectButton.y = portInput.y + 50
    
    love.graphics.setColor(0.2, 0.2, 0.8, 0.8)
    love.graphics.rectangle('fill', lobbyElements.connectButton.x, lobbyElements.connectButton.y, 
                           lobbyElements.connectButton.w, lobbyElements.connectButton.h, 8, 8)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('Connect', lobbyElements.connectButton.x, lobbyElements.connectButton.y + 8, 
                        lobbyElements.connectButton.w, 'center')
    
    -- Back button
    lobbyElements.backButton.x = 20
    lobbyElements.backButton.y = h - 50
    
    love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
    love.graphics.rectangle('fill', lobbyElements.backButton.x, lobbyElements.backButton.y, 
                           lobbyElements.backButton.w, lobbyElements.backButton.h, 8, 8)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('Back', lobbyElements.backButton.x, lobbyElements.backButton.y + 8, 
                        lobbyElements.backButton.w, 'center')
end

-- Draw waiting lobby
function lobby.drawWaitingLobby(w, h, state)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('Connected to Host', w*0.5 - 200, 100, 400, 'center')
    
    -- Connection status
    local connectionStatus = 'Connecting...'
    local connectionColor = {0.8, 0.8, 0.2, 1}
    if state.network and state.network.isConnected() then
        connectionStatus = 'Connected!'
        connectionColor = {0.2, 0.8, 0.2, 1}
    end
    
    love.graphics.setColor(connectionColor)
    love.graphics.printf(connectionStatus, w*0.5 - 200, 130, 400, 'center')
    
    -- Host status
    local hostText = 'Host Not Ready'
    local hostColor = {0.8, 0.8, 0.2, 1}
    if lobbyState.hostReady then
        hostText = 'Host Ready'
        hostColor = {0.2, 0.8, 0.2, 1}
    end
    
    love.graphics.setColor(hostColor)
    love.graphics.printf(hostText, w*0.5 - 200, 180, 400, 'center')
    
    -- Client status
    local clientText = 'Not Ready'
    local clientColor = {0.8, 0.2, 0.2, 1}
    if lobbyState.clientReady then
        clientText = 'Ready'
        clientColor = {0.2, 0.8, 0.2, 1}
    end
    
    love.graphics.setColor(clientColor)
    love.graphics.printf('You: ' .. clientText, w*0.5 - 200, 210, 400, 'center')
    
    -- Ready button
    lobbyElements.readyButton.x = w*0.5 - lobbyElements.readyButton.w*0.5
    lobbyElements.readyButton.y = h*0.5 + 50
    
    local buttonColor = lobbyState.clientReady and {0.8, 0.2, 0.2, 0.8} or {0.2, 0.8, 0.2, 0.8}
    local buttonText = lobbyState.clientReady and 'Not Ready' or 'Ready'
    
    love.graphics.setColor(buttonColor)
    love.graphics.rectangle('fill', lobbyElements.readyButton.x, lobbyElements.readyButton.y, 
                           lobbyElements.readyButton.w, lobbyElements.readyButton.h, 8, 8)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(buttonText, lobbyElements.readyButton.x, lobbyElements.readyButton.y + 12, 
                        lobbyElements.readyButton.w, 'center')
    
    -- Back button
    lobbyElements.backButton.x = 20
    lobbyElements.backButton.y = h - 50
    
    love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
    love.graphics.rectangle('fill', lobbyElements.backButton.x, lobbyElements.backButton.y, 
                           lobbyElements.backButton.w, lobbyElements.backButton.h, 8, 8)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('Back', lobbyElements.backButton.x, lobbyElements.backButton.y + 8, 
                        lobbyElements.backButton.w, 'center')
end

-- Draw ready lobby
function lobby.drawReadyLobby(w, h, state)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('Both Players Ready!', w*0.5 - 200, 100, 400, 'center')
    love.graphics.printf('Waiting for host to start game...', w*0.5 - 200, 130, 400, 'center')
    
    -- Back button
    lobbyElements.backButton.x = 20
    lobbyElements.backButton.y = h - 50
    
    love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
    love.graphics.rectangle('fill', lobbyElements.backButton.x, lobbyElements.backButton.y, 
                           lobbyElements.backButton.w, lobbyElements.backButton.h, 8, 8)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('Back', lobbyElements.backButton.x, lobbyElements.backButton.y + 8, 
                        lobbyElements.backButton.w, 'center')
end

-- Handle mouse clicks
function lobby.handleClick(x, y, button, state)
    if lobbyState.mode == 'menu' then
        lobby.handleMainMenuClick(x, y, button, state)
    elseif lobbyState.mode == 'host' then
        lobby.handleHostLobbyClick(x, y, button, state)
    elseif lobbyState.mode == 'client' then
        lobby.handleClientLobbyClick(x, y, button, state)
    elseif lobbyState.mode == 'waiting' then
        lobby.handleWaitingLobbyClick(x, y, button, state)
    elseif lobbyState.mode == 'ready' then
        lobby.handleReadyLobbyClick(x, y, button, state)
    end
end

-- Handle main menu clicks
function lobby.handleMainMenuClick(x, y, button, state)
    -- Host button
    if x >= lobbyElements.hostButton.x and x <= lobbyElements.hostButton.x + lobbyElements.hostButton.w and
       y >= lobbyElements.hostButton.y and y <= lobbyElements.hostButton.y + lobbyElements.hostButton.h then
        lobby.startHost(state)
    end
    
    -- Client button
    if x >= lobbyElements.clientButton.x and x <= lobbyElements.clientButton.x + lobbyElements.clientButton.w and
       y >= lobbyElements.clientButton.y and y <= lobbyElements.clientButton.y + lobbyElements.clientButton.h then
        lobbyState.mode = 'client'
    end
    
    -- Back button
    if x >= lobbyElements.backButton.x and x <= lobbyElements.backButton.x + lobbyElements.backButton.w and
       y >= lobbyElements.backButton.y and y <= lobbyElements.backButton.y + lobbyElements.backButton.h then
        lobbyState.mode = 'menu'
    end
end

-- Handle host lobby clicks
function lobby.handleHostLobbyClick(x, y, button, state)
    local portInput = {x = love.graphics.getWidth()*0.5 - 100, y = 120, w = 200, h = 30}
    
    -- Port input (focus for typing)
    if x >= portInput.x and x <= portInput.x + portInput.w and
       y >= portInput.y and y <= portInput.y + portInput.h then
        lobbyState.inputMode = 'port'
        lobbyState.inputText = lobbyState.hostPort
        lobbyState.inputCursor = #lobbyState.inputText
        lobbyState.inputBlinkTimer = 0
    -- Start Host button
    elseif lobbyElements.startHostButton and x >= lobbyElements.startHostButton.x and x <= lobbyElements.startHostButton.x + lobbyElements.startHostButton.w and
           y >= lobbyElements.startHostButton.y and y <= lobbyElements.startHostButton.y + lobbyElements.startHostButton.h then
        -- Save current input
        if lobbyState.inputMode == 'port' then
            lobbyState.hostPort = lobbyState.inputText
        end
        lobbyState.inputMode = 'none'
        
        -- Start host
        lobby.startHost(state)
    else
        -- Click outside input fields, save current input
        if lobbyState.inputMode == 'port' then
            lobbyState.hostPort = lobbyState.inputText
        end
        lobbyState.inputMode = 'none'
    end
    
    -- Ready button (only if host is started)
    if state.network and state.network.isHost() and x >= lobbyElements.readyButton.x and x <= lobbyElements.readyButton.x + lobbyElements.readyButton.w and
       y >= lobbyElements.readyButton.y and y <= lobbyElements.readyButton.y + lobbyElements.readyButton.h then
        lobbyState.hostReady = not lobbyState.hostReady
        if state.network then
            state.network.sendPlayerReady(lobbyState.hostReady)
        end
        lobby.updateReadyStatus(state)
    end
    
    -- Start game button
    if lobbyState.bothReady and x >= lobbyElements.startButton.x and x <= lobbyElements.startButton.x + lobbyElements.startButton.w and
       y >= lobbyElements.startButton.y and y <= lobbyElements.startButton.y + lobbyElements.startButton.h then
        lobby.startGame(state)
    end
    
    -- Back button
    if x >= lobbyElements.backButton.x and x <= lobbyElements.backButton.x + lobbyElements.backButton.w and
       y >= lobbyElements.backButton.y and y <= lobbyElements.backButton.y + lobbyElements.backButton.h then
        lobby.disconnect(state)
        lobbyState.mode = 'menu'
    end
end

-- Handle client lobby clicks
function lobby.handleClientLobbyClick(x, y, button, state)
    local portInput = {x = lobbyElements.ipInput.x, y = lobbyElements.ipInput.y + 40, w = 100, h = 30}
    
    -- IP input (focus for typing)
    if x >= lobbyElements.ipInput.x and x <= lobbyElements.ipInput.x + lobbyElements.ipInput.w and
       y >= lobbyElements.ipInput.y and y <= lobbyElements.ipInput.y + lobbyElements.ipInput.h then
        lobbyState.inputMode = 'ip'
        lobbyState.inputText = lobbyState.hostIP
        lobbyState.inputCursor = #lobbyState.inputText
        lobbyState.inputBlinkTimer = 0
    -- Port input (focus for typing)
    elseif x >= portInput.x and x <= portInput.x + portInput.w and
           y >= portInput.y and y <= portInput.y + portInput.h then
        lobbyState.inputMode = 'port'
        lobbyState.inputText = lobbyState.hostPort
        lobbyState.inputCursor = #lobbyState.inputText
        lobbyState.inputBlinkTimer = 0
    else
        -- Click outside input fields, save current input
        if lobbyState.inputMode == 'ip' then
            lobbyState.hostIP = lobbyState.inputText
        elseif lobbyState.inputMode == 'port' then
            lobbyState.hostPort = lobbyState.inputText
        end
        lobbyState.inputMode = 'none'
    end
    
    -- Connect button
    if x >= lobbyElements.connectButton.x and x <= lobbyElements.connectButton.x + lobbyElements.connectButton.w and
       y >= lobbyElements.connectButton.y and y <= lobbyElements.connectButton.y + lobbyElements.connectButton.h then
        lobby.connectToHost(state)
    end
    
    -- Back button
    if x >= lobbyElements.backButton.x and x <= lobbyElements.backButton.x + lobbyElements.backButton.w and
       y >= lobbyElements.backButton.y and y <= lobbyElements.backButton.y + lobbyElements.backButton.h then
        lobbyState.mode = 'menu'
    end
end

-- Handle waiting lobby clicks
function lobby.handleWaitingLobbyClick(x, y, button, state)
    -- Ready button
    if x >= lobbyElements.readyButton.x and x <= lobbyElements.readyButton.x + lobbyElements.readyButton.w and
       y >= lobbyElements.readyButton.y and y <= lobbyElements.readyButton.y + lobbyElements.readyButton.h then
        lobbyState.clientReady = not lobbyState.clientReady
        if state.network then
            state.network.sendPlayerReady(lobbyState.clientReady)
        end
        lobby.updateReadyStatus(state)
    end
    
    -- Back button
    if x >= lobbyElements.backButton.x and x <= lobbyElements.backButton.x + lobbyElements.backButton.w and
       y >= lobbyElements.backButton.y and y <= lobbyElements.backButton.y + lobbyElements.backButton.h then
        lobby.disconnect(state)
        lobbyState.mode = 'menu'
    end
end

-- Handle ready lobby clicks
function lobby.handleReadyLobbyClick(x, y, button, state)
    -- Back button
    if x >= lobbyElements.backButton.x and x <= lobbyElements.backButton.x + lobbyElements.backButton.w and
       y >= lobbyElements.backButton.y and y <= lobbyElements.backButton.y + lobbyElements.backButton.h then
        lobby.disconnect(state)
        lobbyState.mode = 'menu'
    end
end

-- Start hosting
function lobby.startHost(state)
    if not state.network then
        lobbyState.errorMessage = 'Network module not available'
        return
    end
    
    -- Save current input
    if lobbyState.inputMode == 'port' then
        lobbyState.hostPort = lobbyState.inputText
    end
    lobbyState.inputMode = 'none'
    
    local port = tonumber(lobbyState.hostPort) or 12345
    local success, message = state.network.startHost(port)
    if success then
        lobbyState.mode = 'host'
        lobbyState.connectionStatus = message
        lobbyState.errorMessage = ''
    else
        lobbyState.errorMessage = message
    end
end

-- Connect to host
function lobby.connectToHost(state)
    if not state.network then
        lobbyState.errorMessage = 'Network module not available'
        return
    end
    
    -- Save current input
    if lobbyState.inputMode == 'ip' then
        lobbyState.hostIP = lobbyState.inputText
    elseif lobbyState.inputMode == 'port' then
        lobbyState.hostPort = lobbyState.inputText
    end
    lobbyState.inputMode = 'none'
    
    local port = tonumber(lobbyState.hostPort) or 12345
    local success, message = state.network.connectToHost(lobbyState.hostIP, port)
    if success then
        lobbyState.mode = 'waiting'
        lobbyState.connectionStatus = message
        lobbyState.errorMessage = ''
    else
        lobbyState.errorMessage = message
    end
end

-- Update ready status
function lobby.updateReadyStatus(state)
    if state.network and state.network.isHost() then
        lobbyState.bothReady = lobbyState.hostReady and lobbyState.clientReady
    elseif state.network and state.network.isClient() then
        lobbyState.bothReady = lobbyState.hostReady and lobbyState.clientReady
        if lobbyState.bothReady then
            lobbyState.mode = 'ready'
        end
    end
end

-- Start game
function lobby.startGame(state)
    if state.network then
        state.network.sendGameStart()
        -- Transition to deck builder phase
        state.phase = 'deckbuilder'
        state.multiplayer = true
        state.networkPlayerId = state.network.getPlayerId()
    end
end

-- Disconnect
function lobby.disconnect(state)
    if state.network then
        state.network.disconnect()
    end
    lobby.init()
end

-- Handle network messages
function lobby.handleNetworkMessage(message, state)
    print("Lobby received message:", message.type, "ready:", message.data and message.data.ready)
    
    if message.type == state.network.MESSAGE_TYPES.PLAYER_READY then
        if state.network.isHost() then
            lobbyState.clientReady = message.data.ready
            print("Host: Client ready status updated to", lobbyState.clientReady)
        else
            lobbyState.hostReady = message.data.ready
            print("Client: Host ready status updated to", lobbyState.hostReady)
        end
        lobby.updateReadyStatus(state)
    elseif message.type == state.network.MESSAGE_TYPES.GAME_START then
        -- Host started the game
        state.phase = 'deckbuilder'
        state.multiplayer = true
        state.networkPlayerId = state.network.getPlayerId()
    end
end

-- Get current mode
function lobby.getMode()
    return lobbyState.mode
end

-- Set mode
function lobby.setMode(mode)
    lobbyState.mode = mode
end

-- Get host IP
function lobby.getHostIP()
    return lobbyState.hostIP
end

-- Set host IP
function lobby.setHostIP(ip)
    lobbyState.hostIP = ip
end

-- Set error message
function lobby.setErrorMessage(message)
    lobbyState.errorMessage = message
end

-- Set connection status
function lobby.setConnectionStatus(status)
    lobbyState.connectionStatus = status
end

-- Handle keyboard input
function lobby.handleKeyInput(key, state)
    if lobbyState.inputMode == 'none' then
        return false
    end
    
    if key == 'return' or key == 'kpenter' then
        -- Save input and exit input mode
        if lobbyState.inputMode == 'ip' then
            lobbyState.hostIP = lobbyState.inputText
        elseif lobbyState.inputMode == 'port' then
            lobbyState.hostPort = lobbyState.inputText
        end
        lobbyState.inputMode = 'none'
        return true
    elseif key == 'escape' then
        -- Cancel input
        lobbyState.inputMode = 'none'
        return true
    elseif key == 'backspace' then
        -- Delete character
        if #lobbyState.inputText > 0 then
            lobbyState.inputText = lobbyState.inputText:sub(1, -2)
            lobbyState.inputCursor = #lobbyState.inputText
        end
        return true
    elseif key == 'left' then
        -- Move cursor left
        if lobbyState.inputCursor > 0 then
            lobbyState.inputCursor = lobbyState.inputCursor - 1
        end
        return true
    elseif key == 'right' then
        -- Move cursor right
        if lobbyState.inputCursor < #lobbyState.inputText then
            lobbyState.inputCursor = lobbyState.inputCursor + 1
        end
        return true
    elseif key == 'home' then
        -- Move to beginning
        lobbyState.inputCursor = 0
        return true
    elseif key == 'end' then
        -- Move to end
        lobbyState.inputCursor = #lobbyState.inputText
        return true
    end
    
    return false
end

-- Handle text input
function lobby.handleTextInput(text, state)
    if lobbyState.inputMode == 'none' then
        return false
    end
    
    -- Only allow certain characters
    if lobbyState.inputMode == 'ip' then
        -- Allow letters, numbers, dots, and hyphens for IP
        if text:match("[%w%.%-]") then
            lobbyState.inputText = lobbyState.inputText .. text
            lobbyState.inputCursor = #lobbyState.inputText
            return true
        end
    elseif lobbyState.inputMode == 'port' then
        -- Only allow numbers for port
        if text:match("[%d]") then
            lobbyState.inputText = lobbyState.inputText .. text
            lobbyState.inputCursor = #lobbyState.inputText
            return true
        end
    end
    
    return false
end

return lobby
