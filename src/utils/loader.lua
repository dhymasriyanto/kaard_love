local loader = {}
local cards = require('src.data.cards')

local lfs = love.filesystem

local function trim(s)
	return (s:gsub('^%s+', ''):gsub('%s+$', ''))
end

function loader.loadCards(csvPath)
	local data = {}
	local contents = assert(love.filesystem.read(csvPath))
	local lines = {}
	for line in contents:gmatch('[^\n]+') do table.insert(lines, line) end
	for i=2,#lines do
		local line = lines[i]
		local cols = {}
		for part in line:gmatch('[^;]+') do table.insert(cols, trim(part)) end
		if #cols >= 6 then
			local deck, name, element, strength, rarity, ability = cols[1], cols[2], cols[3], tonumber(cols[4]), cols[5], cols[6]
			local imagePath = loader.findImageFor(name, deck)
			local img = imagePath and love.graphics.newImage(imagePath) or nil
			table.insert(data, {
				archetype = deck,
				name = name,
				element = element,
				strength = strength or 0,
				rarity = rarity,
				ability = ability or '',
				imagePath = imagePath,
				image = img,
			})
		end
	end
	cards.setAllCards(data)
	return data
end

function loader.findImageFor(name, deck)
	-- map deck folder names to assets/cards subfolders
	local folderMap = {
		Undead = 'undead',
		Spellcaster = 'spellcaster',
		Druids = 'druids',
		Knights = 'knights',
		Mimic = 'mimic',
		Spider = 'spider',
	}
	local sub = folderMap[deck]
	if not sub then return nil end
	local normalized = name:lower():gsub('[^%w]+','_')
	-- images provided already match CSV names; try multiple strategies
	local candidates = {
		('assets/images/cards/'..sub..'/'..normalized..'.png'),
		('assets/images/cards/'..sub..'/'..name:lower():gsub(' ','_')..'.png'),
		('assets/images/cards/'..sub..'/'..name:gsub(' ','_'):lower()..'.png')
	}
	for _, p in ipairs(candidates) do
		if love.filesystem.getInfo(p) then return p end
	end
	-- fallback: first png in the folder
	if love.filesystem.getInfo('assets/images/cards/'..sub) then
		for _, f in ipairs(love.filesystem.getDirectoryItems('assets/images/cards/'..sub)) do
			if f:lower():match('%.png$') then return 'assets/images/cards/'..sub..'/'..f end
		end
	end
	return nil
end





function loader.loadSound(soundPath)
	if love.filesystem.getInfo(soundPath) then
		return love.audio.newSource(soundPath, 'static')
	else
		print('Warning: Sound file not found: ' .. soundPath)
		return nil
	end
end

function loader.loadCardBack()
	local cardBackPath = 'assets/images/card_back.png'
	if love.filesystem.getInfo(cardBackPath) then
		return love.graphics.newImage(cardBackPath)
	else
		print('Warning: Card back image not found: ' .. cardBackPath)
		return nil
	end
end

function loader.loadBackground()
	local backgroundPath = 'assets/images/background.png'
	if love.filesystem.getInfo(backgroundPath) then
		return love.graphics.newImage(backgroundPath)
	else
		print('Warning: Background image not found: ' .. backgroundPath)
		return nil
	end
end

return loader


