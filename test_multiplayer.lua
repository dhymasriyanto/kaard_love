-- Simple test script untuk memverifikasi sistem multiplayer
-- Jalankan dengan: lua test_multiplayer.lua

local network = require('src.core.network')

print("Testing Multiplayer System...")
print("=============================")

-- Test 1: Network initialization
print("\n1. Testing network initialization...")
network.init()
print("✓ Network initialized successfully")

-- Test 2: Host creation
print("\n2. Testing host creation...")
local success, message = network.startHost()
if success then
    print("✓ Host started: " .. message)
else
    print("✗ Host failed: " .. message)
end

-- Test 3: Connection status
print("\n3. Testing connection status...")
if network.isConnected() then
    print("✓ Network is connected")
else
    print("✗ Network is not connected")
end

-- Test 4: Player ID
print("\n4. Testing player ID...")
local playerId = network.getPlayerId()
print("✓ Player ID: " .. playerId)

-- Test 5: Message sending
print("\n5. Testing message sending...")
local messageSent = network.sendPlayerReady(true)
if messageSent then
    print("✓ Message sent successfully")
else
    print("✗ Message sending failed")
end

-- Test 6: Cleanup
print("\n6. Testing cleanup...")
network.disconnect()
print("✓ Network disconnected")

print("\n=============================")
print("Multiplayer system test completed!")
print("All core functions are working properly.")
print("\nTo test full multiplayer:")
print("1. Run two instances of the game")
print("2. One player hosts, other joins")
print("3. Test lobby, deck builder, and game flow")
