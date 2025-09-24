local loader = {}

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
	return data
end

function loader.findImageFor(name, deck)
	-- map deck folder names to assets/cards subfolders
	local folderMap = {
		Undead = 'undead',
		Spellcaster = 'mage',
		Druids = 'druids',
		Knights = 'knight',
		Mimic = 'mimic',
		Spider = 'spider',
	}
	local sub = folderMap[deck]
	if not sub then return nil end
	local normalized = name:lower():gsub('[^%w]+','_')
	-- images provided already match CSV names; try multiple strategies
	local candidates = {
		('assets/cards/'..sub..'/'..normalized..'.png'),
		('assets/cards/'..sub..'/'..name:lower():gsub(' ','_')..'.png'),
		('assets/cards/'..sub..'/'..name:gsub(' ','_'):lower()..'.png')
	}
	for _, p in ipairs(candidates) do
		if love.filesystem.getInfo(p) then return p end
	end
	-- fallback: first png in the folder
	if love.filesystem.getInfo('assets/cards/'..sub) then
		for _, f in ipairs(love.filesystem.getDirectoryItems('assets/cards/'..sub)) do
			if f:lower():match('%.png$') then return 'assets/cards/'..sub..'/'..f end
		end
	end
	return nil
end

function loader.buildDecks(cardDefs)
	-- Build a single combined deck using copy rules
	local copiesByRarity = { C = 3, R = 3, E = 2, L = 1 }
	local deck = {}
	for _, c in ipairs(cardDefs) do
		local copies = copiesByRarity[c.rarity] or 1
		for i=1,copies do table.insert(deck, {
			archetype=c.archetype, name=c.name, element=c.element, strength=c.strength, baseStrength=c.strength,
			rarity=c.rarity, ability=c.ability, image=c.image, imagePath=c.imagePath,
		}) end
	end
	return deck
end

function loader.cloneDeck(deck)
	local d = {}
	for _, c in ipairs(deck) do
		local nc = {}
		for k,v in pairs(c) do nc[k]=v end
		nc.strength = c.baseStrength
		table.insert(d, nc)
	end
	return d
end

function loader.shuffle(t)
	for i = #t, 2, -1 do
		local j = love.math.random(i)
		t[i], t[j] = t[j], t[i]
	end
end

function loader.draw(player)
	local card = table.remove(player.deck, 1)
	if card then table.insert(player.hand, card) end
end

return loader


