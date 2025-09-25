local setup = {}
local helpers = require('src.utils.helpers')
local config = require('src.data.config')

local function startCoinTossAnimation(state)
	state.coinTossAnimation.show = true
	state.coinTossAnimation.timer = config.ANIMATION.COIN_TOSS_DURATION
	state.coinTossAnimation.result = love.math.random(2)
	helpers.log('Coin toss animation starting...', state)
	
	-- In multiplayer, only host determines coin toss result
	if state.multiplayer and state.network and state.network.isHost() then
		state.network.sendCoinTossResult(state.coinTossAnimation.result)
	end
end

function setup.startCoinTossAnimation(state)
	startCoinTossAnimation(state)
end

return setup
