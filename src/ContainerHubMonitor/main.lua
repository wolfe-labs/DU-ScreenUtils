local VoxelScreen = require('../VoxelScreen')

local renderScript = library.embedFile('screen.rs.lua')

---@type Screen
local screenElement = library.getLinkByClass('Screen')

---@type table<number, Container>
local containerHubs = library.getLinksByClass('ItemContainer', true)

-- Sanity check
if not screenElement then
  system.print('No linked screen detected!')
  return unit.exit()
end

-- Initializes our screen as a voxel-aware one
local screen = VoxelScreen(screenElement)

-- This is the function that updates screen contents
local function updateScreen()
  -- Processes each of the Container Hubs
  local hubData = {}
  for _, containerHub in pairs(containerHubs) do
    --- That hub's position on the screen
    ---@type vec3
    local screenPosition = screen.getPointOnScreen(vec3(containerHub.getPosition()))

    -- Gets the hub name
    local containerHubName = containerHub.getName()

    -- Calculates how much of the hub was used
    local containerHubCapacityUsed = containerHub.getItemsVolume()
    local containerHubCapacityTotal = containerHub.getMaxVolume()

    -- Saves data to hub list
    table.insert(hubData, {
      name = containerHubName,
      used = containerHubCapacityUsed,
      total = containerHubCapacityTotal,
      pos = screenPosition,
    })
  end

  -- Renders data
  screen.render(renderScript, {
    hubs = hubData,
  })
end

updateScreen()

-- Done, stop doing work
unit.exit()