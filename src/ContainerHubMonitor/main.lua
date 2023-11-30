-- Automatic Container Hub Monitor v1.1.0
-- by Wolfram / Wolfe Labs
-- https://github.com/wolfe-labs/DU-ScreenUtils

-- Customization stuff
Background = 'assets.prod.novaquark.com/113304/36ab3926-d7d6-4e62-8714-a4c613195004.png' --export: The URL for the background image
Background_Intensity = 1.0 --export: HDR brightness of the background (0.0 to 5.0)
Font = 'Oxanium' --export: The font used on the UI

Title = '' --export: A title for your screen
Title_X = 0.50 --export: The horizontal position of your title
Title_Y = 0.25 --export: The vertical position of your title
Title_Size = 48 --export: The title size, in pixels

Label_Color = '31,63,255' --export: The color used for the labels under container hubs
Label_Color_Intensity = 2.5 --export: HDR color intensity for the labels
Label_Percentage = false --export: Show used percentage on labels
Border_Color = '31,63,255' --export: The color used for the borders around container hubs
Border_Color_Intensity = 2.5 --export: HDR color intensity for the borders

Progress_Enabled = true --export: Enables or disables the progress bar
Progress_Background = '5, 10, 38' --export: The background color of the progress bars
Progress_Background_Intensity = 0.2 --export: HDR color intensity for the background color of the progress bars
Progress_Foreground = '31,63,255' --export: The foreground color of the progress bars
Progress_Foreground_Intensity = 2.5 --export: HDR color intensity for the foreground color of the progress bars
Progress_Border = '31,63,255' --export: The border color of the progress bars
Progress_Border_Intensity = 2.5 --export: HDR color intensity for the border color of the progress bars

-- Script starts here!

unit.hideWidget()

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
    BACKGROUND_INTENSITY = Background_Intensity,

    -- Title
    TITLE = Title,
    TITLE_POSITION = { Title_X, Title_Y },
    TITLE_SIZE = Title_Size,

    -- Borders
    HUB_BORDER_OFFSET = 8,
    HUB_BORDER_THICKNESS = 2,
    HUB_BORDER_COLOR = colorStringToRgba(Border_Color),
    HUB_BORDER_COLOR_INTENSITY = Border_Color_Intensity,

    -- Labels
    HUB_LABEL_FONT = Font,
    HUB_LABEL_SIZE = 16,
    HUB_LABEL_COLOR = colorStringToRgba(Label_Color),
    HUB_LABEL_COLOR_INTENSITY = Label_Color_Intensity,
    HUB_LABEL_PERCENTAGE_ENABLED = Label_Percentage,

    -- Progress bars
    HUB_PROGRESS_ENABLED = Progress_Enabled,
    HUB_PROGRESS_FONT_NAME = Font,
    HUB_PROGRESS_FONT_SIZE = 8,
    HUB_PROGRESS_BACKGROUND = colorStringToRgba(Progress_Background),
    HUB_PROGRESS_BACKGROUND_INTENSITY = Progress_Background_Intensity,
    HUB_PROGRESS_FOREGROUND = colorStringToRgba(Progress_Foreground),
    HUB_PROGRESS_FOREGROUND_INTENSITY = Progress_Foreground_Intensity,
    HUB_PROGRESS_BORDER = colorStringToRgba(Progress_Border),
    HUB_PROGRESS_BORDER_INTENSITY = Progress_Border_Intensity,
    HUB_PROGRESS_BORDER_THICKNESS = 2,
  })
end

-- Updates screen one last time when leaving
unit:onEvent('onStop', updateScreen)

-- Update screen automatically when nearby
unit:onEvent('onTimer', updateScreen)
unit.setTimer('update', 1)

-- Runs first update
updateScreen()