-- Automatic Container Hub Monitor v1.0
-- by Wolfram / Wolfe Labs
-- https://github.com/wolfe-labs/DU-ScreenUtils

-- Customization stuff
Background = 'assets.prod.novaquark.com/113304/36ab3926-d7d6-4e62-8714-a4c613195004.png' --export: The URL for the background image
Font = 'Oxanium' --export: The font used on the UI

Label_Color = '87,157,237' --export: The color used for the labels under container hubs
Border_Color = '87,157,237' --export: The color used for the borders around container hubs

Progress_Enabled = true --export: Enables or disables the progress bar
Progress_Background = '191,191,191' --export: The background color of the progress bar
Progress_Foreground = '87,157,237' --export: The foreground color of the progress bar
Progress_Label = '0,0,0' --export: The label color of the progress bar

-- Script starts here!

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

-- This helper functions converts a color string into RGBA
local function colorStringToRgba(str)
  local components = {}
  for component in str:gmatch('([^,]+)') do
    table.insert(components, component)
  end
  return components
end

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

    -- Background image
    BACKGROUND = Background,

    -- Borders
    HUB_BORDER_OFFSET = 8,
    HUB_BORDER_THICKNESS = 2,
    HUB_BORDER_COLOR = colorStringToRgba(Border_Color),

    -- Labels
    HUB_LABEL_FONT = Font,
    HUB_LABEL_SIZE = 16,
    HUB_LABEL_COLOR = colorStringToRgba(Label_Color),

    -- Progress bars
    HUB_PROGRESS_ENABLED = Progress_Enabled,
    HUB_PROGRESS_FONT_NAME = Font,
    HUB_PROGRESS_FONT_SIZE = 8,
    HUB_PROGRESS_BACKGROUND = colorStringToRgba(Progress_Background),
    HUB_PROGRESS_FOREGROUND = colorStringToRgba(Progress_Foreground),
    HUB_PROGRESS_TEXT_COLOR = colorStringToRgba(Progress_Label),
  })
end

updateScreen()

-- Done, stop doing work
unit.exit()