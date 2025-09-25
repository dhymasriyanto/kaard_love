local network = {}

-- Import luasocket
local socket = require("socket")

-- Network configuration
local NETWORK_CONFIG = {
    PORT = 12345,
    TIMEOUT = 2.0, -- Reduced timeout
    BUFFER_SIZE = 1024,
    HEARTBEAT_INTERVAL = 2.0, -- Reduced heartbeat frequency
    CONNECTION_TIMEOUT = 10.0 -- Connection timeout
}

-- Network state
local networkState = {
    isHost = false,
    isClient = false,
    isConnected = false,
    server = nil,
    client = nil,
    lastHeartbeat = 0,
    messageQueue = {},
    connectionTimeout = 0,
    playerId = 1, -- 1 for host, 2 for client
    opponentReady = false,
    lobbyReady = false
}

-- Message types
local MESSAGE_TYPES = {
    PLAYER_READY = "PLAYER_READY",
    PLAYER_DECK_SELECTED = "PLAYER_DECK_SELECTED",
    GAME_START = "GAME_START",
    CARD_PLACED = "CARD_PLACED",
    CARD_REVEALED = "CARD_REVEALED",
    SETUP_PASSED = "SETUP_PASSED",
    TURN_CHANGED = "TURN_CHANGED",
    GAME_STATE_SYNC = "GAME_STATE_SYNC",
    COIN_TOSS_RESULT = "COIN_TOSS_RESULT",
    HEARTBEAT = "HEARTBEAT",
    DISCONNECT = "DISCONNECT"
}

-- Initialize network module
function network.init()
    networkState.isHost = false
    networkState.isClient = false
    networkState.isConnected = false
    networkState.server = nil
    networkState.client = nil
    networkState.messageQueue = {}
    networkState.connectionTimeout = 0
    networkState.playerId = 1
    networkState.opponentReady = false
    networkState.lobbyReady = false
end

-- Start hosting a game
function network.startHost(port)
    network.init()
    networkState.isHost = true
    networkState.playerId = 1
    
    local targetPort = port or NETWORK_CONFIG.PORT
    
    -- Try to bind to the specified port
    local success, err = pcall(function()
        networkState.server = socket.bind("*", targetPort)
    end)
    
    if success and networkState.server then
        -- Set non-blocking with small timeout to prevent lag
        networkState.server:settimeout(0.001) -- Very small timeout
        networkState.isConnected = true
        networkState.lobbyReady = true
        
        print("Host started on port", targetPort)
        return true, "Host started on port " .. targetPort
    else
        print("Port " .. targetPort .. " failed: " .. (err or "Unknown error"))
        return false, "Failed to bind to port " .. targetPort .. " - " .. (err or "Port already in use")
    end
end

-- Connect to a host
function network.connectToHost(hostIP, port)
    network.init()
    networkState.isClient = true
    networkState.playerId = 2
    
    local targetPort = port or NETWORK_CONFIG.PORT
    
    -- Create client socket with better error handling
    local success, err = pcall(function()
        networkState.client = socket.connect(hostIP, targetPort)
    end)
    
    if not success or not networkState.client then
        return false, "Failed to connect to " .. hostIP .. ":" .. targetPort .. " - " .. (err or "Unknown error")
    end
    
    -- Set non-blocking with small timeout to prevent lag
    networkState.client:settimeout(0.001) -- Very small timeout
    networkState.isConnected = true
    networkState.connectionTimeout = love.timer.getTime() + NETWORK_CONFIG.CONNECTION_TIMEOUT
    
    return true, "Connecting to " .. hostIP .. ":" .. targetPort
end

-- Send a message
function network.sendMessage(messageType, data)
    if not networkState.isConnected then
        print("Cannot send message - not connected")
        return false
    end
    
    local message = {
        type = messageType,
        data = data or {},
        timestamp = love.timer.getTime(),
        playerId = networkState.playerId
    }
    
    local serialized = network.serializeMessage(message)
    print("Sending message:", serialized)
    
    if networkState.isHost and networkState.client then
        -- Host sending to client
        local success, err = networkState.client:send(serialized .. "\n")
        if not success then
            print("Host send error:", err)
            return false
        else
            print("Host message sent successfully")
        end
    elseif networkState.isClient and networkState.client then
        -- Client sending to host
        local success, err = networkState.client:send(serialized .. "\n")
        if not success then
            print("Client send error:", err)
            return false
        else
            print("Client message sent successfully")
        end
    else
        print("No client connection available for sending")
        return false
    end
    
    return true
end

-- Receive messages
function network.receiveMessages()
    if not networkState.isConnected then
        return {}
    end
    
    local messages = {}
    
    if networkState.isHost and networkState.server then
        -- Host receiving from client
        local client = networkState.server:accept()
        if client then
            client:settimeout(0.001) -- Very small timeout
            networkState.client = client
        end
        
        if networkState.client then
            -- Try to receive with small timeout
            local line, err = networkState.client:receive("*l")
            if line then
                print("Host received:", line)
                local message = network.deserializeMessage(line)
                if message then
                    table.insert(messages, message)
                    print("Host parsed message:", message.type)
                end
            elseif err and err ~= "timeout" and err ~= "wantread" then
                print("Host receive error:", err)
                networkState.isConnected = false
            end
        end
    elseif networkState.isClient and networkState.client then
        -- Client receiving from host
        local line, err = networkState.client:receive("*l")
        if line then
            print("Client received:", line)
            local message = network.deserializeMessage(line)
            if message then
                table.insert(messages, message)
                print("Client parsed message:", message.type)
            end
        elseif err and err ~= "timeout" and err ~= "wantread" then
            print("Client receive error:", err)
            networkState.isConnected = false
        end
    end
    
    return messages
end

-- Update network (call this in game update loop)
function network.update(dt)
    if not networkState.isConnected then
        return
    end
    
    -- Handle connection timeout for client
    if networkState.isClient and networkState.connectionTimeout > 0 then
        if love.timer.getTime() > networkState.connectionTimeout then
            networkState.isConnected = false
            networkState.connectionTimeout = 0
            print("Connection timeout")
            return
        end
    end
    
    -- Send heartbeat less frequently to reduce lag
    local currentTime = love.timer.getTime()
    if currentTime - networkState.lastHeartbeat > NETWORK_CONFIG.HEARTBEAT_INTERVAL then
        -- Only send heartbeat if we haven't sent any messages recently
        local success = network.sendMessage(MESSAGE_TYPES.HEARTBEAT, {})
        if success then
            networkState.lastHeartbeat = currentTime
        end
    end
    
    -- Process incoming messages with rate limiting
    local messages = network.receiveMessages()
    local processedCount = 0
    for _, message in ipairs(messages) do
        if processedCount < 5 then -- Limit messages per frame
            network.processMessage(message)
            processedCount = processedCount + 1
        else
            -- Queue remaining messages for next frame
            table.insert(networkState.messageQueue, message)
        end
    end
end

-- Process received message
function network.processMessage(message)
    if message.type == MESSAGE_TYPES.HEARTBEAT then
        -- Heartbeat received, connection is alive
        return
    elseif message.type == MESSAGE_TYPES.PLAYER_READY then
        networkState.opponentReady = message.data.ready or false
    elseif message.type == MESSAGE_TYPES.PLAYER_DECK_SELECTED then
        -- Handle deck selection from opponent
        networkState.messageQueue[#networkState.messageQueue + 1] = message
    elseif message.type == MESSAGE_TYPES.GAME_START then
        -- Handle game start
        networkState.messageQueue[#networkState.messageQueue + 1] = message
    elseif message.type == MESSAGE_TYPES.CARD_PLACED then
        -- Handle card placement
        networkState.messageQueue[#networkState.messageQueue + 1] = message
    elseif message.type == MESSAGE_TYPES.CARD_REVEALED then
        -- Handle card reveal
        networkState.messageQueue[#networkState.messageQueue + 1] = message
    elseif message.type == MESSAGE_TYPES.SETUP_PASSED then
        -- Handle setup phase pass
        networkState.messageQueue[#networkState.messageQueue + 1] = message
    elseif message.type == MESSAGE_TYPES.TURN_CHANGED then
        -- Handle turn change
        networkState.messageQueue[#networkState.messageQueue + 1] = message
    elseif message.type == MESSAGE_TYPES.GAME_STATE_SYNC then
        -- Handle game state synchronization
        networkState.messageQueue[#networkState.messageQueue + 1] = message
    elseif message.type == MESSAGE_TYPES.COIN_TOSS_RESULT then
        -- Handle coin toss result
        networkState.messageQueue[#networkState.messageQueue + 1] = message
    elseif message.type == MESSAGE_TYPES.DISCONNECT then
        networkState.isConnected = false
    end
end

-- Get queued messages
function network.getQueuedMessages()
    local messages = networkState.messageQueue
    networkState.messageQueue = {}
    return messages
end

-- Serialize message to string (simple format)
function network.serializeMessage(message)
    -- Convert table to simple string format
    local parts = {}
    table.insert(parts, "type:" .. (message.type or ""))
    table.insert(parts, "playerId:" .. (message.playerId or 1))
    table.insert(parts, "timestamp:" .. (message.timestamp or 0))
    
    if message.data then
        for key, value in pairs(message.data) do
            if type(value) == "table" then
                -- For complex data like deck, convert to simple format
                if key == "deck" then
                    local deckStr = "deck:"
                    for i, cardData in ipairs(value) do
                        if i > 1 then deckStr = deckStr .. "," end
                        deckStr = deckStr .. cardData.card.name .. "x" .. cardData.count
                    end
                    table.insert(parts, deckStr)
                else
                    table.insert(parts, key .. ":" .. tostring(value))
                end
            else
                table.insert(parts, key .. ":" .. tostring(value))
            end
        end
    end
    
    return table.concat(parts, "|")
end

-- Deserialize message from string
function network.deserializeMessage(data)
    local message = {}
    local parts = {}
    
    -- Split by |
    for part in data:gmatch("[^|]+") do
        table.insert(parts, part)
    end
    
    -- Parse each part
    for _, part in ipairs(parts) do
        local key, value = part:match("([^:]+):(.+)")
        if key and value then
            if key == "type" then
                message.type = value
            elseif key == "playerId" then
                message.playerId = tonumber(value)
            elseif key == "timestamp" then
                message.timestamp = tonumber(value)
            elseif key == "deck" then
                -- Parse deck data
                message.data = message.data or {}
                message.data.deck = {}
                for cardStr in value:gmatch("[^,]+") do
                    local cardName, count = cardStr:match("([^x]+)x(%d+)")
                    if cardName and count then
                        table.insert(message.data.deck, {
                            card = {name = cardName},
                            count = tonumber(count)
                        })
                    end
                end
            else
                message.data = message.data or {}
                -- Try to convert to number if possible
                local numValue = tonumber(value)
                message.data[key] = numValue or value
            end
        end
    end
    
    return message
end

-- Check if we're connected
function network.isConnected()
    return networkState.isConnected
end

-- Check if we're host
function network.isHost()
    return networkState.isHost
end

-- Check if we're client
function network.isClient()
    return networkState.isClient
end

-- Get player ID
function network.getPlayerId()
    return networkState.playerId
end

-- Check if opponent is ready
function network.isOpponentReady()
    return networkState.opponentReady
end

-- Check if lobby is ready
function network.isLobbyReady()
    return networkState.lobbyReady
end

-- Get current port (for host)
function network.getCurrentPort()
    if networkState.server then
        return networkState.server:getsockname()
    end
    return NETWORK_CONFIG.PORT
end

-- Disconnect
function network.disconnect()
    if networkState.server then
        networkState.server:close()
        networkState.server = nil
    end
    if networkState.client then
        networkState.client:close()
        networkState.client = nil
    end
    networkState.isConnected = false
    networkState.isHost = false
    networkState.isClient = false
end

-- Send player ready status
function network.sendPlayerReady(ready)
    print("Sending PLAYER_READY:", ready, "from player", networkState.playerId)
    return network.sendMessage(MESSAGE_TYPES.PLAYER_READY, {ready = ready})
end

-- Send deck selection
function network.sendDeckSelected(deckData)
    return network.sendMessage(MESSAGE_TYPES.PLAYER_DECK_SELECTED, {deck = deckData})
end

-- Send game start
function network.sendGameStart()
    return network.sendMessage(MESSAGE_TYPES.GAME_START, {})
end

-- Send card placement
function network.sendCardPlaced(playerId, slotIndex, cardData)
    return network.sendMessage(MESSAGE_TYPES.CARD_PLACED, {
        playerId = playerId,
        slotIndex = slotIndex,
        card = cardData
    })
end

-- Send card reveal
function network.sendCardRevealed(playerId, slotIndex)
    return network.sendMessage(MESSAGE_TYPES.CARD_REVEALED, {
        playerId = playerId,
        slotIndex = slotIndex
    })
end

-- Send setup passed
function network.sendSetupPassed(playerId)
    return network.sendMessage(MESSAGE_TYPES.SETUP_PASSED, {playerId = playerId})
end

-- Send turn change
function network.sendTurnChanged(newTurn)
    return network.sendMessage(MESSAGE_TYPES.TURN_CHANGED, {turn = newTurn})
end

-- Send game state sync
function network.sendGameStateSync(gameState)
    return network.sendMessage(MESSAGE_TYPES.GAME_STATE_SYNC, {state = gameState})
end

-- Send coin toss result
function network.sendCoinTossResult(result)
    return network.sendMessage(MESSAGE_TYPES.COIN_TOSS_RESULT, {result = result})
end

-- Export message types for other modules
network.MESSAGE_TYPES = MESSAGE_TYPES

return network
