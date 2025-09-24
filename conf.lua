function love.conf(t)
	t.window.title = 'Kaard - Simple TCG'
	t.window.width = 1280
	t.window.height = 720
	t.identity = 'kaard_love'
	-- Allow reading real files from project dir
	t.appendidentity = false
end
