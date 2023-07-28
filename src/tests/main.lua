-- VoxelScreen class
local VoxelScreen = require('../VoxelScreen')

-- Loads our debug script
local script = library.embedFile('debug.rs.lua')

---@type table<number,Screen>
local screens = library.getLinksByClass('Screen', true)

function debug(data, prefix)
  if 'table' == type(data) then
    for k, v in pairs(data) do
      debug(v, (prefix or '') .. '.' .. k)
    end
  else
    system.print(('%s = %s'):format(prefix or '', tostring(data)))
  end
end

-- Assigns test script
for _, screenElement in pairs(screens) do
  local screen = VoxelScreen(screenElement)
  screen.render(script)
end

unit.exit()