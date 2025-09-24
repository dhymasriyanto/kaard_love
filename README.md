Kaard - Simple TCG (LÖVE2D)

Run with LÖVE 11.x

How to run (Windows):
- Install LÖVE: https://love2d.org
- Drag the folder onto love.exe or run from terminal: love .

Controls:
- Setup: Click a hand card, then click an empty field slot (3 slots). Turns alternate.
- Combat: Click your face-down card to reveal; then click an opponent slot to reveal and fight.
- Resolution: Click to score the round, move cards to grave, and draw 2 each.
- Press R to restart.

Notes:
- Card images are auto-mapped from assets/images/cards/* using CSV names.
- Implemented example abilities: Stitched Hag, Decayed Gas, Oak Guardian, Shieldbearer, Battle Sage, Arcane Bolt, Essential Cocoon, Gluttony Tarantula, Warden of the Grove.
- Elements: Sword > Orb > Shield > Sword. Ties compare strength.

Key files:
- main.lua, conf.lua
- src/loader.lua (CSV parser, deck builder)
- src/game.lua (phase flow)
- src/ui.lua (render + hit)
- src/rules.lua (combat + abilities)

