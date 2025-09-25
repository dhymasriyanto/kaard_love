-- Real networking implementation using LÖVE2D's built-in luasocket
-- Based on https://love2d.org/wiki/socket

local luasocket_networking = {}

-- Import luasocket
local socket = require("socket")

-- Message types
local MESSAGE_TYPES = {
    HANDSHAKE = "handshake",
    PLAYER_JOINED = "player_joined",
    PLAYER_LEFT = "player_left",
    GAME_STATE_SYNC = "game_state_sync",
    PLAYER_ACTION = "player_action",
    CHAT_MESSAGE = "chat_message",
    HEARTBEAT = "heartbeat",
    ERROR = "error"
}

-- Network state
local networkState = {
    server = nil,
    client = nil,
    connectedClient = nil,  -- For host: the connected client socket
    isHost = false,
    isClient = false,
    isConnected = false,
    lastHeartbeat = 0,
    messageQueue = {},
    playerId = nil,
    remotePlayerId = nil,
    lastMessageId = 0,
    host = "localhost",
    port = 12345
}

-- Initialize networking
function luasocket_networking.init()
    networkState.server = nil
    networkState.client = nil
    networkState.connectedClient = nil
    networkState.isHost = false
    networkState.isClient = false
    networkState.isConnected = false
    networkState.lastHeartbeat = 0
    networkState.messageQueue = {}
    networkState.playerId = nil
    networkState.remotePlayerId = nil
    networkState.lastMessageId = 0
    networkState.host = "localhost"
    networkState.port = 12345
    print("Luasocket networking initialized")
end

-- Create server (host)
function luasocket_networking.createServer(port)
    port = port or 12345
    networkState.port = port
    
    print("Creating TCP server on port", port)
    
    -- Create TCP server
    networkState.server = socket.bind("*", port)
    if not networkState.server then
        print("Failed to create server on port", port)
        return false, "Failed to create server on port " .. port
    end
    
    -- Set server to non-blocking mode
    networkState.server:settimeout(0)
    
    networkState.isHost = true
    networkState.playerId = 1
    networkState.isConnected = true
    
    print("Server created successfully on port", port)
    return true, "Server created on port " .. port
end

-- Connect to server (client)
function luasocket_networking.connectToServer(host, port)
    host = host or "localhost"
    port = port or 12345
    networkState.host = host
    networkState.port = port
    
    print("Connecting to", host .. ":" .. port)
    
    -- Create TCP client
    networkState.client = socket.connect(host, port)
    if not networkState.client then
        print("Failed to connect to", host .. ":" .. port)
        return false, "Failed to connect to " .. host .. ":" .. port
    end
    
    -- Set client to non-blocking mode
    networkState.client:settimeout(0)
    
    networkState.isClient = true
    networkState.playerId = 2
    networkState.isConnected = true
    
    print("Connected successfully to", host .. ":" .. port)
    
    -- Send handshake immediately
    luasocket_networking.sendMessage(MESSAGE_TYPES.HANDSHAKE, {
        playerId = networkState.playerId,
        playerName = "Player " .. networkState.playerId
    })
    
    return true, "Connected to " .. host .. ":" .. port
end

-- Send message
function luasocket_networking.sendMessage(messageType, data)
    if not networkState.isConnected then
        print("Cannot send message: not connected")
        return false, "Not connected"
    end
    
    local message = {
        type = messageType,
        data = data or {},
        timestamp = love.timer.getTime(),
        playerId = networkState.playerId,
        id = networkState.lastMessageId + 1
    }
    
    networkState.lastMessageId = networkState.lastMessageId + 1
    
    -- Enhanced serialization to handle complex data structures
    local serialized = messageType .. "|" .. networkState.playerId
    
    if data then
        -- Handle different data structures
        if data.actionType then
            -- PLAYER_ACTION message
            serialized = serialized .. "|" .. (data.actionType or "")
            if data.data and data.data.ready ~= nil then
                serialized = serialized .. "|" .. (data.data.ready and "true" or "false")
            elseif data.data and data.data.lobbyPhase then
                -- lobby_sync message with complex data
                serialized = serialized .. "|" .. (data.data.lobbyPhase or "")
                serialized = serialized .. "|" .. (data.data.myReady and "true" or "false")
            elseif data.data and data.data.deckData then
                -- deck_ready message with deck data
                serialized = serialized .. "|deck_ready"
                -- For now, just send true to indicate deck is ready
                -- TODO: Implement proper deck data serialization
                serialized = serialized .. "|true"
            elseif data.data and data.data.playerIndex then
                -- card_placement or pass_setup message
                serialized = serialized .. "|" .. (data.actionType or "")
                serialized = serialized .. "|" .. (data.data.playerIndex or "")
                if data.actionType == "card_placement" then
                    serialized = serialized .. "|" .. (data.data.handIndex or "")
                    serialized = serialized .. "|" .. (data.data.slot or "")
                end
            else
                serialized = serialized .. "|false"
            end
        else
            -- Other message types
            serialized = serialized .. "|" .. (data.playerName or "")
            serialized = serialized .. "|" .. (data.actionType or "")
            serialized = serialized .. "|" .. (data.slot or "")
            serialized = serialized .. "|" .. (data.ready and "true" or "false")
        end
    else
        serialized = serialized .. "||||false"
    end
    
    serialized = serialized .. "\n"
    
    print("Sending message:", serialized)
    
    if networkState.isHost and networkState.connectedClient then
        -- Host sending to connected client
        local success, err = networkState.connectedClient:send(serialized)
        if success then
            print("Host sent message:", messageType)
        else
            print("Host failed to send message:", err)
        end
    elseif networkState.isClient and networkState.client then
        -- Client sending to server
        local success, err = networkState.client:send(serialized)
        if success then
            print("Client sent message:", messageType)
        else
            print("Client failed to send message:", err)
        end
    else
        print("Cannot send message: no valid socket")
        if networkState.isHost then
            print("Host has connectedClient:", networkState.connectedClient ~= nil)
        elseif networkState.isClient then
            print("Client has client:", networkState.client ~= nil)
        end
    end
    
    return true, "Message sent"
end

-- Receive messages
function luasocket_networking.receiveMessages()
    local messages = {}
    
    if networkState.isHost and networkState.server then
        -- Host: check for new connections and messages
        local client = networkState.server:accept()
        if client then
            print("New client connected")
            client:settimeout(0)
            networkState.connectedClient = client
        end
        
        -- Read from connected client
        if networkState.connectedClient then
            local data, err = networkState.connectedClient:receive("*l")
            if data then
                print("Host received:", data)
                local message = luasocket_networking.parseMessage(data)
                if message then
                    table.insert(messages, message)
                end
            elseif err ~= "timeout" then
                print("Host receive error:", err)
                networkState.connectedClient = nil
                networkState.isConnected = false
            end
        end
    elseif networkState.isClient and networkState.client then
        -- Client: read from server
        local data, err = networkState.client:receive("*l")
        if data then
            print("Client received:", data)
            local message = luasocket_networking.parseMessage(data)
            if message then
                table.insert(messages, message)
            end
        elseif err ~= "timeout" then
            print("Client receive error:", err)
            networkState.isConnected = false
        end
    end
    
    return messages
end

-- Parse received message
function luasocket_networking.parseMessage(data)
    local parts = {}
    for part in string.gmatch(data, "[^|]+") do
        table.insert(parts, part)
    end
    
    print("Parsing message parts:", table.concat(parts, ", "))
    
    if #parts >= 2 then
        local messageType = parts[1]
        local playerId = tonumber(parts[2])
        
        -- Handle different message types
        if messageType == "player_action" then
            -- PLAYER_ACTION message structure
            local actionType = parts[3] or ""
            
            if actionType == "lobby_sync" then
                -- lobby_sync message with complex data
                local lobbyPhase = parts[4] or ""
                local myReady = (parts[5] == "true")
                
                return {
                    type = messageType,
                    playerId = playerId,
                    data = {
                        actionType = actionType,
                        data = {
                            lobbyPhase = lobbyPhase,
                            myReady = myReady
                        }
                    }
                }
            elseif actionType == "deck_ready" then
                -- deck_ready message
                local hasDeckData = (parts[4] == "true")
                
                return {
                    type = messageType,
                    playerId = playerId,
                    data = {
                        actionType = actionType,
                        data = {
                            deckData = hasDeckData -- Simplified for now
                        }
                    }
                }
            elseif actionType == "start_game" then
                -- start_game message
                return {
                    type = messageType,
                    playerId = playerId,
                    data = {
                        actionType = actionType,
                        data = {}
                    }
                }
            elseif actionType == "card_placement" then
                -- card_placement message
                local playerIndex = tonumber(parts[4]) or 1
                local handIndex = tonumber(parts[5]) or 1
                local slot = tonumber(parts[6]) or 1
                
                return {
                    type = messageType,
                    playerId = playerId,
                    data = {
                        actionType = actionType,
                        data = {
                            playerIndex = playerIndex,
                            handIndex = handIndex,
                            slot = slot
                        }
                    }
                }
            elseif actionType == "pass_setup" then
                -- pass_setup message
                local playerIndex = tonumber(parts[4]) or 1
                
                return {
                    type = messageType,
                    playerId = playerId,
                    data = {
                        actionType = actionType,
                        data = {
                            playerIndex = playerIndex
                        }
                    }
                }
            else
                -- Regular lobby_ready message
                local ready = (parts[4] == "true")
                
                return {
                    type = messageType,
                    playerId = playerId,
                    data = {
                        actionType = actionType,
                        data = {
                            ready = ready
                        }
                    }
                }
            end
        else
            -- Other message types (handshake, etc.)
            return {
                type = messageType,
                playerId = playerId,
                data = {
                    playerName = parts[3] or "",
                    actionType = parts[4] or "",
                    slot = tonumber(parts[5]) or nil,
                    ready = (parts[6] == "true")
                }
            }
        end
    end
    
    print("Failed to parse message:", data)
    return nil
end

-- Update networking (call in game update)
function luasocket_networking.update(dt)
    if not networkState.isConnected then
        return
    end
    
    -- Receive messages
    local messages = luasocket_networking.receiveMessages()
    for _, message in ipairs(messages) do
        table.insert(networkState.messageQueue, message)
    end
    
    -- Send heartbeat
    networkState.lastHeartbeat = networkState.lastHeartbeat + dt
    if networkState.lastHeartbeat >= 1.0 then
        luasocket_networking.sendMessage(MESSAGE_TYPES.HEARTBEAT, {})
        networkState.lastHeartbeat = 0
    end
end

-- Get queued messages
function luasocket_networking.getMessages()
    local messages = networkState.messageQueue
    networkState.messageQueue = {}
    return messages
end

-- Check if connected
function luasocket_networking.isConnected()
    return networkState.isConnected
end

-- Check if host
function luasocket_networking.isHost()
    return networkState.isHost
end

-- Check if client
function luasocket_networking.isClient()
    return networkState.isClient
end

-- Get player ID
function luasocket_networking.getPlayerId()
    return networkState.playerId
end

-- Get remote player ID
function luasocket_networking.getRemotePlayerId()
    return networkState.remotePlayerId or (networkState.playerId == 1 and 2 or 1)
end

-- Disconnect
function luasocket_networking.disconnect()
    if networkState.server then
        networkState.server:close()
        networkState.server = nil
    end
    if networkState.client then
        networkState.client:close()
        networkState.client = nil
    end
    if networkState.connectedClient then
        networkState.connectedClient:close()
        networkState.connectedClient = nil
    end
    
    luasocket_networking.init()
    print("Disconnected from network")
end

-- Send game action
function luasocket_networking.sendGameAction(actionType, data)
    return luasocket_networking.sendMessage(MESSAGE_TYPES.PLAYER_ACTION, {
        actionType = actionType,
        data = data
    })
end

-- Send game state sync
function luasocket_networking.sendGameStateSync(gameState)
    return luasocket_networking.sendMessage(MESSAGE_TYPES.GAME_STATE_SYNC, {
        gameState = gameState
    })
end

-- Export message types for other modules
luasocket_networking.MESSAGE_TYPES = MESSAGE_TYPES

return luasocket_networking
