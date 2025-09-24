local setup = {}
local helpers = require('src.utils.helpers')

local function startCoinTossAnimation(state)
	state.coinTossAnimation.show = true
	state.coinTossAnimation.timer = 3.0 -- 3 seconds animation
	state.coinTossAnimation.result = love.math.random(2)
	helpers.log('Coin toss animation starting...', state)
end

function setup.startCoinTossAnimation(state)
	startCoinTossAnimation(state)
end

return setup
