-- Debug script untuk network issues
-- Jalankan dengan: lua debug_network.lua

local socket = require("socket")

print("Network Debug Tool")
print("==================")

-- Test 1: Check if luasocket is available
print("\n1. Testing luasocket availability...")
if socket then
    print("✓ luasocket is available")
else
    print("✗ luasocket is not available")
    return
end

-- Test 2: Test port binding
print("\n2. Testing port binding...")
local testPorts = {12345, 12346, 12347, 12348, 12349}
local availablePort = nil

for _, port in ipairs(testPorts) do
    local server = socket.bind("*", port)
    if server then
        print("✓ Port " .. port .. " is available")
        availablePort = port
        server:close()
        break
    else
        print("✗ Port " .. port .. " is busy")
    end
end

if not availablePort then
    print("✗ No available ports found!")
    return
end

-- Test 3: Test server creation
print("\n3. Testing server creation...")
local server = socket.bind("*", availablePort)
if server then
    print("✓ Server created successfully on port " .. availablePort)
    server:settimeout(0.001)
    print("✓ Server timeout set to non-blocking")
else
    print("✗ Failed to create server")
    return
end

-- Test 4: Test client connection
print("\n4. Testing client connection...")
local client = socket.connect("localhost", availablePort)
if client then
    print("✓ Client connected successfully")
    client:settimeout(0.001)
    print("✓ Client timeout set to non-blocking")
else
    print("✗ Failed to connect client")
    server:close()
    return
end

-- Test 5: Test message sending
print("\n5. Testing message sending...")
local testMessage = "Hello from client!"
local success, err = client:send(testMessage .. "\n")
if success then
    print("✓ Message sent successfully")
else
    print("✗ Failed to send message: " .. (err or "Unknown error"))
end

-- Test 6: Test message receiving
print("\n6. Testing message receiving...")
local line, err = client:receive("*l")
if line then
    print("✓ Message received: " .. line)
else
    print("✗ Failed to receive message: " .. (err or "Unknown error"))
end

-- Cleanup
print("\n7. Cleaning up...")
client:close()
server:close()
print("✓ Connections closed")

print("\n==================")
print("Network debug completed!")
print("If all tests passed, the network system should work.")
print("If tests failed, check firewall settings or port availability.")
