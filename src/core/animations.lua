local animations = {}

-- Import modules
local config = require('src.data.config')

-- Get game state
local function getState()
	return require('src.core.state').get()
end

-- Logging function
local function log(message)
	local gameState = getState()
	require('src.utils.helpers').log(message, gameState)
end

-- Phase transition functions
function animations.showPhaseTransition(text, duration)
	local gameState = getState()
	duration = duration or config.ANIMATION.PHASE_TRANSITION_DURATION
	gameState.phaseTransition.text = text
	gameState.phaseTransition.timer = duration
	gameState.phaseTransition.show = true
end

function animations.showResolutionPopup(data, duration)
	local gameState = getState()
	duration = duration or config.ANIMATION.RESOLUTION_POPUP_DURATION
	gameState.resolutionPopup.data = data
	gameState.resolutionPopup.timer = duration
	gameState.resolutionPopup.show = true
end

function animations.update(dt)
	local gameState = getState()
	
	-- Update notification timer
	if gameState.notification.timer > 0 then
		gameState.notification.timer = gameState.notification.timer - dt
		if gameState.notification.timer <= 0 then
			gameState.notification.text = ''
		end
	end
	
	-- Update phase transition timer
	if gameState.phaseTransition.timer > 0 then
		gameState.phaseTransition.timer = gameState.phaseTransition.timer - dt
		if gameState.phaseTransition.timer <= 0 then
			gameState.phaseTransition.show = false
		end
	end
	
	-- Update resolution popup timer
	if gameState.resolutionPopup.timer > 0 then
		gameState.resolutionPopup.timer = gameState.resolutionPopup.timer - dt
		if gameState.resolutionPopup.timer <= 0 then
			gameState.resolutionPopup.show = false
		end
	end
	
	-- Update coin toss animation timer
	if gameState.coinTossAnimation.timer > 0 then
		gameState.coinTossAnimation.timer = gameState.coinTossAnimation.timer - dt
		if gameState.coinTossAnimation.timer <= 0 then
			-- Animation finished, set first player and start combat
			gameState.turn = gameState.coinTossAnimation.result
			gameState.coinFirst = gameState.turn
			gameState.coinTossAnimation.show = false
			gameState.phase = 'combat'
			log(gameState.players[gameState.turn].name..' goes first!')
			
			-- Check if combat is even possible
			local combat = require('src.game.combat')
			if not combat.canContinue(gameState) then
				-- No combat possible, auto-reveal all cards and go to resolution
				log('No combat possible. Auto-revealing all cards.')
				combat.autoRevealRemaining(gameState)
				gameState.phase = 'resolution'
				local resolution = require('src.game.resolution')
				resolution.showResolutionPopupImmediately(gameState)
			else
				animations.showPhaseTransition('COMBAT PHASE', 2.0)
			end
		end
	end
end

return animations
