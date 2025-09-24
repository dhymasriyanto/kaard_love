-- Kaard: Simple TCG prototype using LÖVE2D
-- Entry point

local game = require('src.game')

function love.load()
	love.window.setTitle('Kaard - Simple TCG')
	game.load()
end

function love.update(dt)
	game.update(dt)
end

function love.draw()
	game.draw()
end

function love.mousepressed(x, y, button)
	game.mousepressed(x, y, button)
end

function love.keypressed(key)
	game.keypressed(key)
end

function love.wheelmoved(dx, dy)
	if game.wheelmoved then game.wheelmoved(dx, dy) end
end


