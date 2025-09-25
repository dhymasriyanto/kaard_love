-- Dependencies for multiplayer functionality
-- This file should be loaded before main.lua

-- Simple JSON implementation for Lua
local json = {}

function json.encode(obj)
    if type(obj) == "table" then
        local result = "{"
        local first = true
        for k, v in pairs(obj) do
            if not first then
                result = result .. ","
            end
            first = false
            
            if type(k) == "string" then
                result = result .. '"' .. k .. '":'
            else
                result = result .. k .. ":"
            end
            
            result = result .. json.encode(v)
        end
        result = result .. "}"
        return result
    elseif type(obj) == "string" then
        return '"' .. obj .. '"'
    elseif type(obj) == "number" then
        return tostring(obj)
    elseif type(obj) == "boolean" then
        return obj and "true" or "false"
    elseif obj == nil then
        return "null"
    else
        return '"' .. tostring(obj) .. '"'
    end
end

function json.decode(str)
    -- Simple JSON decoder (basic implementation)
    local function parse_value(s, pos)
        pos = pos or 1
        while pos <= #s and string.match(s:sub(pos, pos), "%s") do
            pos = pos + 1
        end
        
        if pos > #s then return nil, pos end
        
        local char = s:sub(pos, pos)
        
        if char == "{" then
            return parse_object(s, pos)
        elseif char == "[" then
            return parse_array(s, pos)
        elseif char == '"' then
            return parse_string(s, pos)
        elseif char == "t" then
            if s:sub(pos, pos + 3) == "true" then
                return true, pos + 4
            end
        elseif char == "f" then
            if s:sub(pos, pos + 4) == "false" then
                return false, pos + 5
            end
        elseif char == "n" then
            if s:sub(pos, pos + 3) == "null" then
                return nil, pos + 4
            end
        elseif string.match(char, "[%-%d]") then
            return parse_number(s, pos)
        end
        
        return nil, pos
    end
    
    local function parse_object(s, pos)
        local obj = {}
        pos = pos + 1 -- skip {
        
        while pos <= #s do
            while pos <= #s and string.match(s:sub(pos, pos), "%s") do
                pos = pos + 1
            end
            
            if s:sub(pos, pos) == "}" then
                return obj, pos + 1
            end
            
            local key, new_pos = parse_string(s, pos)
            if not key then return nil, pos end
            pos = new_pos
            
            while pos <= #s and string.match(s:sub(pos, pos), "%s") do
                pos = pos + 1
            end
            
            if s:sub(pos, pos) ~= ":" then return nil, pos end
            pos = pos + 1
            
            local value, new_pos = parse_value(s, pos)
            if not value then return nil, pos end
            pos = new_pos
            
            obj[key] = value
            
            while pos <= #s and string.match(s:sub(pos, pos), "%s") do
                pos = pos + 1
            end
            
            if s:sub(pos, pos) == "}" then
                return obj, pos + 1
            elseif s:sub(pos, pos) == "," then
                pos = pos + 1
            else
                return nil, pos
            end
        end
        
        return obj, pos
    end
    
    local function parse_array(s, pos)
        local arr = {}
        pos = pos + 1 -- skip [
        
        while pos <= #s do
            while pos <= #s and string.match(s:sub(pos, pos), "%s") do
                pos = pos + 1
            end
            
            if s:sub(pos, pos) == "]" then
                return arr, pos + 1
            end
            
            local value, new_pos = parse_value(s, pos)
            if not value then return nil, pos end
            pos = new_pos
            
            table.insert(arr, value)
            
            while pos <= #s and string.match(s:sub(pos, pos), "%s") do
                pos = pos + 1
            end
            
            if s:sub(pos, pos) == "]" then
                return arr, pos + 1
            elseif s:sub(pos, pos) == "," then
                pos = pos + 1
            else
                return nil, pos
            end
        end
        
        return arr, pos
    end
    
    local function parse_string(s, pos)
        if s:sub(pos, pos) ~= '"' then return nil, pos end
        pos = pos + 1
        
        local result = ""
        while pos <= #s do
            local char = s:sub(pos, pos)
            if char == '"' then
                return result, pos + 1
            elseif char == "\\" then
                pos = pos + 1
                if pos > #s then return nil, pos end
                char = s:sub(pos, pos)
                if char == "n" then
                    result = result .. "\n"
                elseif char == "t" then
                    result = result .. "\t"
                elseif char == "r" then
                    result = result .. "\r"
                elseif char == "\\" then
                    result = result .. "\\"
                elseif char == '"' then
                    result = result .. '"'
                else
                    result = result .. char
                end
            else
                result = result .. char
            end
            pos = pos + 1
        end
        
        return result, pos
    end
    
    local function parse_number(s, pos)
        local start = pos
        if s:sub(pos, pos) == "-" then
            pos = pos + 1
        end
        
        while pos <= #s and string.match(s:sub(pos, pos), "%d") do
            pos = pos + 1
        end
        
        if pos <= #s and s:sub(pos, pos) == "." then
            pos = pos + 1
            while pos <= #s and string.match(s:sub(pos, pos), "%d") do
                pos = pos + 1
            end
        end
        
        local num_str = s:sub(start, pos - 1)
        return tonumber(num_str), pos
    end
    
    local result, pos = parse_value(str)
    return result, pos
end

-- Simple socket implementation using LÖVE2D's built-in networking
local socket = {}

-- Global state for communication
local commState = {
    hostData = "",
    clientData = "",
    connected = false,
    isHost = false,
    lastMessageTime = 0
}

function socket.tcp()
    local tcp = {}
    local connected = false
    local isHost = false
    local messageQueue = {}
    
    function tcp:bind(host, port)
        -- Simulate binding
        isHost = true
        commState.isHost = true
        commState.connected = true
        connected = true
        return true
    end
    
    function tcp:listen(backlog)
        -- Simulate listening
        return true
    end
    
    function tcp:accept()
        -- Check if client has sent a handshake
        if commState.clientData and commState.clientData ~= "" then
            local client = {
                connected = true,
                send = function(self, data)
                    commState.hostData = data
                    return true
                end,
                receive = function(self, pattern)
                    if commState.clientData and commState.clientData ~= "" then
                        local data = commState.clientData
                        commState.clientData = "" -- Clear after reading
                        return data
                    end
                    return nil, "timeout"
                end,
                settimeout = function(self, timeout) end,
                close = function(self)
                    self.connected = false
                end
            }
            return client
        end
        return nil
    end
    
    function tcp:connect(host, port)
        -- Simulate connection
        isHost = false
        commState.isHost = false
        commState.connected = true
        connected = true
        
        -- Send handshake
        commState.clientData = "handshake"
        return true
    end
    
    function tcp:send(data)
        if isHost then
            -- Host sends to client
            commState.hostData = data
            return true
        else
            -- Client sends to host
            commState.clientData = data
            return true
        end
    end
    
    function tcp:receive(pattern)
        if isHost then
            -- Host receives from client
            if commState.clientData and commState.clientData ~= "" then
                local data = commState.clientData
                commState.clientData = "" -- Clear after reading
                return data
            end
        else
            -- Client receives from host
            if commState.hostData and commState.hostData ~= "" then
                local data = commState.hostData
                commState.hostData = "" -- Clear after reading
                return data
            end
        end
        return nil, "timeout"
    end
    
    function tcp:settimeout(timeout)
        -- Simulate timeout setting
    end
    
    function tcp:close()
        connected = false
        commState.connected = false
        commState.hostData = ""
        commState.clientData = ""
    end
    
    return tcp
end

-- Make json and socket globally available
_G.json = json
_G.socket = socket
