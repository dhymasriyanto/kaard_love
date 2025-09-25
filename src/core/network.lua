-- Simple network module for multiplayer
local socket = require('socket')

local network = {}

-- Network state
local state = {
    server = nil,
    client = nil,
    mode = 'none', -- 'host', 'client', 'none'
    connected = false,
    port = 25565,
    messages = {},
    onClientConnected = nil, -- Callback when client connects
    -- Rate limiting
    lastMessageTime = 0,
    messageRateLimit = 0.1 -- 100ms between messages
}

-- Initialize network
function network.init()
    state.server = nil
    state.client = nil
    state.mode = 'none'
    state.connected = false
    state.messages = {}
    print("Network: Initialized")
end

-- Start hosting
function network.startHost(port)
    port = port or 25565
    state.port = port
    
    print("Network: Starting host on port", port)
    
    local server, err = socket.bind("*", port)
    if not server then
        print("Network: Failed to bind to port", port, "error:", err)
        return false, "Failed to bind to port " .. port .. ": " .. (err or "unknown error")
    end
    
    server:settimeout(0) -- Non-blocking
    state.server = server
    state.mode = 'host'
    state.connected = false
    
    print("Network: Host started successfully on port", port)
    return true, "Host started on port " .. port
end

-- Connect to host
function network.connectToHost(ip, port)
    ip = ip or "127.0.0.1"
    port = port or 25565
    
    print("Network: Connecting to", ip, "port", port)
    
    local client = socket.tcp()
    if not client then
        return false, "Failed to create client socket"
    end
    
    client:settimeout(0) -- Non-blocking
    local success, err = client:connect(ip, port)
    
    
    if success == 1 then
        -- Immediate success
        state.client = client
        state.mode = 'client'
        state.connected = true
        print("Network: Connected immediately")
        return true, "Connected to " .. ip .. ":" .. port
    elseif err == "timeout" then
        -- Connection in progress (normal for non-blocking)
        state.client = client
        state.mode = 'client'
        state.connected = false
        print("Network: Connection in progress...")
        return true, "Connecting to " .. ip .. ":" .. port
    else
        -- Real error
        print("Network: Connection failed:", err)
        client:close()
        return false, "Connection failed: " .. (err or "unknown error")
    end
end

-- Update network (call in love.update)
function network.update(dt)
    if state.mode == 'host' and state.server then
        -- Accept new connections
        if not state.connected then
            local client = state.server:accept()
            if client then
                client:settimeout(0)
                state.client = client
                state.connected = true
                print("Network: Client connected!")
                
                -- Notify callback that client connected
                if state.onClientConnected then
                    state.onClientConnected()
                end
            end
        end
        
        -- Receive messages from client
        if state.connected and state.client then
            local data, err = state.client:receive()
            if data then
                print("Network: Received:", data)
                table.insert(state.messages, data)
            elseif err == "closed" then
                print("Network: Client disconnected")
                state.client:close()
                state.client = nil
                state.connected = false
            end
        end
        
    elseif state.mode == 'client' and state.client then
        -- Check if connection completed
        if not state.connected then
            local _, err = state.client:send("")
            if not err then
                state.connected = true
                print("Network: Connected to host!")
            elseif err ~= "timeout" then
                print("Network: Connection failed:", err)
                state.client:close()
                state.client = nil
                state.mode = 'none'
            else
                -- Still connecting, this is normal
            end
        end
        
        -- Receive messages from host
        if state.connected then
            local data, err = state.client:receive()
            if data then
                print("Network: Received:", data)
                table.insert(state.messages, data)
            elseif err == "closed" then
                print("Network: Host disconnected")
                state.client:close()
                state.client = nil
                state.connected = false
                state.mode = 'none'
            end
        end
    end
end

-- Send message
function network.sendMessage(message)
    if not state.connected then
        print("Network: Not connected, cannot send message")
        return false
    end
    
    -- Rate limiting
    local currentTime = love.timer.getTime()
    if currentTime - state.lastMessageTime < state.messageRateLimit then
        print("Network: Message rate limited, skipping")
        return false
    end
    state.lastMessageTime = currentTime
    
    local target = (state.mode == 'host') and state.client or state.client
    if not target then
        print("Network: No target to send message to")
        return false
    end
    
    local success, err = target:send(message .. "\n")
    if not success then
        print("Network: Send failed:", err)
        return false
    end
    
    return true
end

-- Get received messages
function network.getMessages()
    local msgs = state.messages
    state.messages = {}
    return msgs
end

-- Status functions
function network.isHost()
    return state.mode == 'host'
end

function network.isClient()
    return state.mode == 'client'
end

function network.isConnected()
    return state.connected
end

function network.getCurrentPort()
    return state.port
end

function network.getMode()
    return state.mode
end

-- Set callback for when client connects (host only)
function network.setOnClientConnected(callback)
    state.onClientConnected = callback
end

-- Disconnect
function network.disconnect()
    if state.server then
        state.server:close()
        state.server = nil
    end
    if state.client then
        state.client:close()
        state.client = nil
    end
    
    state.mode = 'none'
    state.connected = false
    state.messages = {}
    state.onClientConnected = nil
    print("Network: Disconnected")
end

return network
