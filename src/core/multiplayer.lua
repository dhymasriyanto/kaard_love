local multiplayer = {}

-- Import dependencies
local networking = require('src.core.networking')
local state = require('src.core.state')
local helpers = require('src.utils.helpers')

-- Multiplayer state
local multiplayerState = {
    mode = 'local', -- 'local', 'host', 'client'
    isMyTurn = true,
    waitingForOpponent = false,
    connectionStatus = 'disconnected', -- 'disconnected', 'connecting', 'connected', 'error'
    lastError = nil,
    lobbyCode = nil,
    playerNames = {'Player A', 'Player B'},
    lobbyPhase = 'none', -- 'none', 'waiting', 'ready'
    opponentReady = false,
    myReady = false,
    -- Deck builder multiplayer state
    deckBuilderPhase = 'none', -- 'none', 'selecting', 'waiting', 'ready'
    myDeckReady = false,
    opponentDeckReady = false,
    myDeckData = nil,
    opponentDeckData = nil
}

-- Initialize multiplayer
function multiplayer.init()
    multiplayerState.mode = 'local'
    multiplayerState.isMyTurn = true
    multiplayerState.waitingForOpponent = false
    multiplayerState.connectionStatus = 'disconnected'
    multiplayerState.lastError = nil
    multiplayerState.lobbyCode = nil
    multiplayerState.playerNames = {'Player A', 'Player B'}
    multiplayerState.lobbyPhase = 'none'
    multiplayerState.opponentReady = false
    multiplayerState.myReady = false
    -- Reset deck builder state
    multiplayerState.deckBuilderPhase = 'none'
    multiplayerState.myDeckReady = false
    multiplayerState.opponentDeckReady = false
    multiplayerState.myDeckData = nil
    multiplayerState.opponentDeckData = nil
    
    networking.init()
end

-- Start hosting a game
function multiplayer.startHost(port)
    port = port or 12345
    
    local success, err = networking.createServer(port)
    if not success then
        multiplayerState.connectionStatus = 'error'
        multiplayerState.lastError = err
        return false, err
    end
    
    multiplayerState.mode = 'host'
    multiplayerState.connectionStatus = 'connecting'
    multiplayerState.lobbyCode = tostring(port)
    multiplayerState.lobbyPhase = 'waiting'
    
    -- Update player names
    multiplayerState.playerNames[1] = 'Host'
    multiplayerState.playerNames[2] = 'Waiting for player...'
    
    return true, "Hosting game on port " .. port
end

-- Join a game
function multiplayer.joinGame(host, port)
    host = host or "localhost"
    port = port or 12345
    
    local success, err = networking.connectToServer(host, port)
    if not success then
        multiplayerState.connectionStatus = 'error'
        multiplayerState.lastError = err
        return false, err
    end
    
    multiplayerState.mode = 'client'
    multiplayerState.connectionStatus = 'connected'
    multiplayerState.lobbyPhase = 'ready'
    multiplayerState.playerNames[1] = 'Host'
    multiplayerState.playerNames[2] = 'Client'
    
    return true, "Connected to " .. host .. ":" .. port
end

-- Update multiplayer (call in game update)
function multiplayer.update(dt)
    if multiplayerState.mode == 'local' then
        return
    end
    
    -- Update networking
    networking.update(dt)
    
    -- Process incoming messages
    local messages = networking.getMessages()
    for _, message in ipairs(messages) do
        multiplayer.handleMessage(message)
    end
    
    -- Update connection status
    if networking.isConnected() then
        multiplayerState.connectionStatus = 'connected'
        multiplayerState.lastError = nil
    else
        if multiplayerState.connectionStatus == 'connecting' then
            multiplayerState.connectionStatus = 'error'
            multiplayerState.lastError = "Connection timeout"
        elseif multiplayerState.connectionStatus == 'connected' then
            multiplayerState.connectionStatus = 'disconnected'
            multiplayerState.lastError = "Connection lost"
        end
    end
end

-- Handle incoming network messages
function multiplayer.handleMessage(message)
    local gameState = state.get()
    
    if message.type == networking.MESSAGE_TYPES.HANDSHAKE then
        -- Client joined
        multiplayerState.playerNames[2] = message.data.playerName or 'Player 2'
        multiplayerState.lobbyPhase = 'ready' -- Host masuk ke fase ready
        helpers.log('Player joined: ' .. multiplayerState.playerNames[2], gameState)
        
        -- Send welcome message back
        networking.sendMessage(networking.MESSAGE_TYPES.PLAYER_JOINED, {
            message = "Player joined the game!"
        })
        
        -- Send current lobby state to client
        multiplayer.sendLobbyStateToClient()
        
    elseif message.type == networking.MESSAGE_TYPES.PLAYER_JOINED then
        -- Player joined notification
        helpers.log(message.data.message or 'Player joined', gameState)
        multiplayerState.lobbyPhase = 'ready'
        multiplayerState.playerNames[2] = 'Player 2'
        
    elseif message.type == networking.MESSAGE_TYPES.PLAYER_ACTION then
        -- Handle opponent's action
        if message.data.actionType == 'lobby_ready' then
            multiplayerState.opponentReady = message.data.data.ready
            helpers.log('Opponent is ' .. (message.data.data.ready and 'ready' or 'not ready'), gameState)
        elseif message.data.actionType == 'lobby_sync' then
            -- Sync lobby state from host
            if message.data.data.lobbyPhase then
                multiplayerState.lobbyPhase = message.data.data.lobbyPhase
            end
            if message.data.data.myReady ~= nil then
                multiplayerState.opponentReady = message.data.data.myReady
            end
            if message.data.data.playerNames then
                multiplayerState.playerNames = message.data.data.playerNames
            end
            helpers.log('Synced lobby state from host', gameState)
        elseif message.data.actionType == 'deck_ready' then
            -- Opponent deck is ready
            multiplayerState.opponentDeckReady = true
            -- Note: We don't sync actual deck data, each player keeps their own
            helpers.log('Opponent deck is ready', gameState)
            
            -- Check if both decks are ready
            if multiplayerState.myDeckReady and multiplayerState.opponentDeckReady then
                multiplayerState.deckBuilderPhase = 'ready'
                helpers.log('Both decks are ready!', gameState)
            end
        elseif message.data.actionType == 'start_game' then
            -- Host started the game, enter deck builder
            multiplayer.startDeckBuilder()
            helpers.log('Host started game, entering deck builder', gameState)
        else
            multiplayer.handleOpponentAction(message.data.actionType, message.data.data)
        end
        
    elseif message.type == networking.MESSAGE_TYPES.GAME_STATE_SYNC then
        -- Sync game state
        if message.data and message.data.gameState then
            multiplayer.syncGameState(message.data.gameState)
        else
            helpers.log('Received GAME_STATE_SYNC with invalid data', gameState)
        end
        
    elseif message.type == networking.MESSAGE_TYPES.ERROR then
        -- Handle error
        multiplayerState.lastError = message.data.message or 'Unknown error'
        helpers.log('Network error: ' .. multiplayerState.lastError, gameState)
    end
end

-- Handle opponent's action
function multiplayer.handleOpponentAction(actionType, data)
    local gameState = state.get()
    
    if actionType == 'card_placement' then
        -- Opponent placed a card
        local playerIndex = data.playerIndex
        local handIndex = data.handIndex
        local slot = data.slot
        
        -- In multiplayer, adjust player index for POV
        local myPlayerId = networking.getPlayerId()
        local targetPlayerIndex = playerIndex
        
        -- If I'm client (Player 2), swap the player index
        if myPlayerId == 2 then
            if playerIndex == 1 then
                targetPlayerIndex = 2  -- Remote Player 1 becomes my Player 2 (opponent)
            elseif playerIndex == 2 then
                targetPlayerIndex = 1  -- Remote Player 2 becomes my Player 1 (myself)
            end
        end
        
        if gameState.players[targetPlayerIndex] and gameState.players[targetPlayerIndex].hand[handIndex] then
            local card = table.remove(gameState.players[targetPlayerIndex].hand, handIndex)
            gameState.players[targetPlayerIndex].field[slot] = card
            helpers.log(gameState.players[targetPlayerIndex].name .. ' placed a card face-down at slot ' .. slot, gameState)
            -- Sync game state after opponent card placement
            multiplayer.sendGameState()
        end
        
    elseif actionType == 'pass_setup' then
        -- Opponent passed setup
        local playerIndex = data.playerIndex
        
        -- In multiplayer, adjust player index for POV
        local myPlayerId = networking.getPlayerId()
        local targetPlayerIndex = playerIndex
        
        -- If I'm client (Player 2), swap the player index
        if myPlayerId == 2 then
            if playerIndex == 1 then
                targetPlayerIndex = 2  -- Remote Player 1 becomes my Player 2 (opponent)
            elseif playerIndex == 2 then
                targetPlayerIndex = 1  -- Remote Player 2 becomes my Player 1 (myself)
            end
        end
        
        gameState.setupPassed[targetPlayerIndex] = true
        helpers.log(gameState.players[targetPlayerIndex].name .. ' passes.', gameState)
        -- Sync game state after opponent pass
        multiplayer.sendGameState()
        
    elseif actionType == 'reveal_card' then
        -- Opponent revealed a card
        local playerIndex = data.playerIndex
        local slot = data.slot
        
        if gameState.players[playerIndex] and gameState.players[playerIndex].field[slot] then
            gameState.players[playerIndex].revealed[slot] = true
            gameState.flipSound:stop(); gameState.flipSound:play()
            helpers.log(gameState.players[playerIndex].name .. ' reveals ' .. gameState.players[playerIndex].field[slot].name, gameState)
        end
        
    elseif actionType == 'combat_action' then
        -- Opponent's combat action
        local attackerSlot = data.attackerSlot
        local defenderSlot = data.defenderSlot
        
        -- This will be handled by the combat system
        gameState.pendingAttackSlot = attackerSlot
        gameState.pendingDefenderSlot = defenderSlot
    end
end

-- Sync game state from remote
function multiplayer.syncGameState(remoteGameState)
    local gameState = state.get()
    
    -- Safety check: ensure remoteGameState is valid
    if not remoteGameState or type(remoteGameState) ~= "table" then
        helpers.log('Invalid remoteGameState received', gameState)
        return
    end
    
    -- Sync critical game state
    if remoteGameState.turn then gameState.turn = remoteGameState.turn end
    if remoteGameState.phase then gameState.phase = remoteGameState.phase end
    if remoteGameState.setupPassed then gameState.setupPassed = remoteGameState.setupPassed end
    if remoteGameState.pendingAttackSlot then gameState.pendingAttackSlot = remoteGameState.pendingAttackSlot end
    if remoteGameState.currentRound then gameState.currentRound = remoteGameState.currentRound end
    if remoteGameState.roundWins then gameState.roundWins = remoteGameState.roundWins end
    if remoteGameState.gameOver ~= nil then gameState.gameOver = remoteGameState.gameOver end
    
    -- Sync player data with POV adjustment for multiplayer
    if remoteGameState.players and type(remoteGameState.players) == "table" then
        local myPlayerId = networking.getPlayerId()
        
        for i = 1, 2 do
            if remoteGameState.players[i] and gameState.players[i] then
                -- In multiplayer, swap player data so both players see themselves as Player 1
                local sourceIndex = i
                local targetIndex = i
                
                -- If I'm client (Player 2), swap the data so I see myself as Player 1
                if myPlayerId == 2 then
                    if i == 1 then
                        targetIndex = 2  -- Remote Player 1 becomes my Player 2 (opponent)
                    elseif i == 2 then
                        targetIndex = 1  -- Remote Player 2 becomes my Player 1 (myself)
                    end
                end
                
                if remoteGameState.players[sourceIndex].hand then gameState.players[targetIndex].hand = remoteGameState.players[sourceIndex].hand end
                if remoteGameState.players[sourceIndex].field then gameState.players[targetIndex].field = remoteGameState.players[sourceIndex].field end
                if remoteGameState.players[sourceIndex].revealed then gameState.players[targetIndex].revealed = remoteGameState.players[sourceIndex].revealed end
                if remoteGameState.players[sourceIndex].deck then gameState.players[targetIndex].deck = remoteGameState.players[sourceIndex].deck end
                if remoteGameState.players[sourceIndex].grave then gameState.players[targetIndex].grave = remoteGameState.players[sourceIndex].grave end
            end
        end
    end
    
    -- Update turn indicator
    multiplayerState.isMyTurn = (gameState.turn == networking.getPlayerId())
end

-- Send action to opponent
function multiplayer.sendAction(actionType, data)
    if multiplayerState.mode == 'local' then
        return true
    end
    
    return networking.sendGameAction(actionType, data)
end

-- Send game state to opponent
function multiplayer.sendGameState()
    if multiplayerState.mode == 'local' then
        return true
    end
    
    local gameState = state.get()
    if not gameState or type(gameState) ~= "table" then
        helpers.log('Invalid gameState for sync', gameState)
        return false
    end
    
    return networking.sendGameStateSync(gameState)
end

-- Check if it's my turn
function multiplayer.isMyTurn()
    if multiplayerState.mode == 'local' then
        return true
    end
    
    local gameState = state.get()
    -- In setup phase, both players can act simultaneously
    if gameState.phase == 'setup' then
        return true
    end
    
    return gameState.turn == networking.getPlayerId()
end

-- Check if waiting for opponent
function multiplayer.isWaitingForOpponent()
    return multiplayerState.waitingForOpponent
end

-- Set waiting for opponent
function multiplayer.setWaitingForOpponent(waiting)
    multiplayerState.waitingForOpponent = waiting
end

-- Get connection status
function multiplayer.getConnectionStatus()
    return multiplayerState.connectionStatus
end

-- Get last error
function multiplayer.getLastError()
    return multiplayerState.lastError
end

-- Get lobby code
function multiplayer.getLobbyCode()
    return multiplayerState.lobbyCode
end

-- Get player names
function multiplayer.getPlayerNames()
    return multiplayerState.playerNames
end

-- Get multiplayer mode
function multiplayer.getMode()
    return multiplayerState.mode
end

-- Disconnect
function multiplayer.disconnect()
    networking.disconnect()
    multiplayer.init()
end

-- Check if multiplayer is active
function multiplayer.isMultiplayer()
    return multiplayerState.mode == 'host' or multiplayerState.mode == 'client'
end

-- Get my player ID
function multiplayer.getMyPlayerId()
    if multiplayerState.mode == 'local' then
        return 1 -- Local player is always player 1
    end
    
    return networking.getPlayerId()
end

-- Get opponent player ID
function multiplayer.getOpponentPlayerId()
    if multiplayerState.mode == 'local' then
        return 2 -- Local opponent is always player 2
    end
    
    return networking.getRemotePlayerId()
end

-- Lobby functions
function multiplayer.getLobbyPhase()
    return multiplayerState.lobbyPhase
end

function multiplayer.isInLobby()
    return multiplayerState.lobbyPhase ~= 'none'
end

function multiplayer.isOpponentReady()
    return multiplayerState.opponentReady
end

function multiplayer.isMyReady()
    return multiplayerState.myReady
end

function multiplayer.setMyReady(ready)
    multiplayerState.myReady = ready
    if multiplayer.isMultiplayer() then
        networking.sendMessage(networking.MESSAGE_TYPES.PLAYER_ACTION, {
            actionType = 'lobby_ready',
            data = {ready = ready}
        })
    end
    
    -- Debug logging
    local gameState = state.get()
    helpers.log('My ready status: ' .. (ready and 'ready' or 'not ready'), gameState)
    helpers.log('Opponent ready: ' .. (multiplayerState.opponentReady and 'ready' or 'not ready'), gameState)
    helpers.log('Can start game: ' .. (multiplayer.canStartGame() and 'yes' or 'no'), gameState)
end

function multiplayer.canStartGame()
    return multiplayerState.lobbyPhase == 'ready' and 
           multiplayerState.opponentReady and 
           multiplayerState.myReady
end

function multiplayer.startGame()
    if multiplayer.canStartGame() then
        multiplayerState.lobbyPhase = 'none'
        
        -- Send start game signal to client
        if multiplayer.isMultiplayer() then
            networking.sendMessage(networking.MESSAGE_TYPES.PLAYER_ACTION, {
                actionType = 'start_game',
                data = {}
            })
        end
        
        return true
    end
    return false
end

-- Send current lobby state to newly connected client
function multiplayer.sendLobbyStateToClient()
    local gameState = state.get()
    
    -- Send current ready status
    if multiplayerState.myReady then
        networking.sendMessage(networking.MESSAGE_TYPES.PLAYER_ACTION, {
            actionType = 'lobby_ready',
            data = {ready = true}
        })
        helpers.log('Sent current ready status to new client', gameState)
    end
    
    -- Send lobby phase info
    networking.sendMessage(networking.MESSAGE_TYPES.PLAYER_ACTION, {
        actionType = 'lobby_sync',
        data = {
            lobbyPhase = multiplayerState.lobbyPhase,
            myReady = multiplayerState.myReady,
            playerNames = multiplayerState.playerNames
        }
    })
    helpers.log('Sent lobby state sync to new client', gameState)
end

-- Deck Builder Multiplayer Functions

-- Start deck builder phase
function multiplayer.startDeckBuilder()
    multiplayerState.deckBuilderPhase = 'selecting'
    multiplayerState.myDeckReady = false
    multiplayerState.opponentDeckReady = false
    multiplayerState.myDeckData = nil
    multiplayerState.opponentDeckData = nil
    
    local gameState = state.get()
    helpers.log('Started multiplayer deck builder', gameState)
end

-- Check if in deck builder phase
function multiplayer.isInDeckBuilder()
    return multiplayerState.deckBuilderPhase ~= 'none'
end

-- Get deck builder phase
function multiplayer.getDeckBuilderPhase()
    return multiplayerState.deckBuilderPhase
end

-- Check if my deck is ready
function multiplayer.isMyDeckReady()
    return multiplayerState.myDeckReady
end

-- Check if opponent deck is ready
function multiplayer.isOpponentDeckReady()
    return multiplayerState.opponentDeckReady
end

-- Set my deck as ready
function multiplayer.setMyDeckReady(deckData)
    multiplayerState.myDeckReady = true
    
    if multiplayer.isMultiplayer() then
        networking.sendMessage(networking.MESSAGE_TYPES.PLAYER_ACTION, {
            actionType = 'deck_ready',
            data = {deckData = true} -- Just send true to indicate ready
        })
    end
    
    local gameState = state.get()
    helpers.log('My deck is ready', gameState)
    
    -- Check if both decks are ready
    if multiplayerState.myDeckReady and multiplayerState.opponentDeckReady then
        multiplayerState.deckBuilderPhase = 'ready'
        helpers.log('Both decks are ready!', gameState)
    end
end

-- Check if both decks are ready
function multiplayer.canStartGameFromDeckBuilder()
    return multiplayerState.deckBuilderPhase == 'ready' and
           multiplayerState.myDeckReady and
           multiplayerState.opponentDeckReady
end

-- Get deck data for both players
function multiplayer.getDeckData()
    local gameState = state.get()
    return {
        myDeck = gameState.playerDecks[multiplayer.getMyPlayerId()],
        opponentDeck = gameState.playerDecks[multiplayer.getMyPlayerId() == 1 and 2 or 1]
    }
end

-- Get current player ID for deck building (1 for host, 2 for client)
function multiplayer.getMyPlayerId()
    if multiplayerState.mode == 'host' then
        return 1
    elseif multiplayerState.mode == 'client' then
        return 2
    else
        return 1 -- Default for local mode
    end
end

-- Check if current player can edit the specified deck
function multiplayer.canEditDeck(deckPlayerId)
    if not multiplayer.isMultiplayer() then
        return true -- Single player can edit any deck
    end
    
    local myPlayerId = multiplayer.getMyPlayerId()
    return deckPlayerId == myPlayerId
end

return multiplayer
