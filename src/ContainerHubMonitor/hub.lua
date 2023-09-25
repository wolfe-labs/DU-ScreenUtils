-- Automatic Container Hub² v1.0.0
-- This is a lesse version of the Container Hub Monitor, without the progress rendering stuff, for large amounts of hubs
-- Make sure it is linked to the Core Unit
-- by Wolfram / Wolfe Labs
-- https://github.com/wolfe-labs/DU-ScreenUtils

-- Customization stuff
Background = 'assets.prod.novaquark.com/113304/36ab3926-d7d6-4e62-8714-a4c613195004.png' --export: The URL for the background image
Font = 'Oxanium' --export: The font used on the UI

Label_Color = '31,63,255' --export: The color used for the labels under container hubs
Label_Color_Intensity = 2.5 --export: HDR color intensity for the labels
Label_Percentage = false --export: Show used percentage on labels
Border_Color = '31,63,255' --export: The color used for the borders around container hubs
Border_Color_Intensity = 2.5 --export: HDR color intensity for the borders

-- Script starts here!

unit.hideWidget()

local VoxelScreen = require('../VoxelScreen')
local VoxelUtils = require('../VoxelUtils')

local renderScript = library.embedFile('screen.rs.lua')

local core = library.getCoreUnit()

-- Sanity check
if not core then
  system.print('No linked Core Unit detected!')
  return unit.exit()
end

---@type table<number, Screen>
local screenElements = library.getLinksByClass('Screen', true)

-- Let's calculate the screen sizes (for container hub detection), also initialize the voxel screens and hub container
local screens = {}
local screenHubs = {}
local screenSizeAndPosition = {}
for idx, screen in pairs(screenElements) do
  screens[idx] = VoxelScreen(screen)
  screenHubs[idx] = {}
  table.insert(screenSizeAndPosition, {
    center = vec3(screen.getPosition()),
    size = vec3(screen.getBoundingBoxSize()):len(),
  })
end

-- Let's find a list of Container Hubs that are close to the screens
for _, id in pairs(core.getElementIdList()) do
  if 'ItemContainer' == core.getElementClassById(id) then
    local pos = vec3(core.getElementPositionById(id))
    for idx, screenInfo in pairs(screenSizeAndPosition) do
      system.print(('%.3f / %.3f'):format((pos - screenInfo.center):len(), screenInfo.size))
      if (pos - screenInfo.center):len() <= screenInfo.size then
        table.insert(screenHubs[idx], id)
      end
    end
  end
end

-- This helper functions converts a color string into RGBA
local function colorStringToRgba(str)
  local components = {}
  for component in str:gmatch('([^,]+)') do
    table.insert(components, component)
  end
  return components
end

-- This is the function that updates screen contents
local function updateScreens()
  for idx, screen in pairs(screens) do
    -- Processes each of the Container Hubs
    local hubData = {}
    for _, containerHubId in pairs(screenHubs[idx]) do
      --- That hub's position on the screen
      ---@type vec3
      local screenPosition = screen.getPointOnScreen(vec3(core.getElementPositionById(containerHubId)))

      -- Only renders hubs within 1 voxel of the screen
      if math.abs(screenPosition[3]) <= VoxelUtils.VOXEL_SIZE then
        -- Gets the hub name
        local containerHubName = core.getElementNameById(containerHubId)

        -- Saves data to hub list
        table.insert(hubData, {
          name = containerHubName,
          used = 0,
          total = 0,
          pos = screenPosition,
        })
      end
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
      HUB_BORDER_COLOR_INTENSITY = Border_Color_Intensity,
  
      -- Labels
      HUB_LABEL_FONT = Font,
      HUB_LABEL_SIZE = 16,
      HUB_LABEL_COLOR = colorStringToRgba(Label_Color),
      HUB_LABEL_COLOR_INTENSITY = Label_Color_Intensity,
      HUB_LABEL_PERCENTAGE_ENABLED = Label_Percentage,

      -- Progress bars (those are only here because I want to reuse the screen.rs.lua file, they are just stubs)
      HUB_PROGRESS_ENABLED = false,
      HUB_PROGRESS_FONT_NAME = 'Oxanium',
      HUB_PROGRESS_FONT_SIZE = 0,
      HUB_PROGRESS_BACKGROUND = colorStringToRgba('0,0,0'),
      HUB_PROGRESS_BACKGROUND_INTENSITY = 0.0,
      HUB_PROGRESS_FOREGROUND = colorStringToRgba('0,0,0'),
      HUB_PROGRESS_FOREGROUND_INTENSITY = 0.0,
      HUB_PROGRESS_BORDER = colorStringToRgba('0,0,0'),
      HUB_PROGRESS_BORDER_INTENSITY = 0.0,
      HUB_PROGRESS_BORDER_THICKNESS = 0,
    })
  end
end

-- Updates screen one last time when leaving
unit:onEvent('onStop', updateScreens)

-- Update screen automatically when nearby
unit:onEvent('onTimer', updateScreens)
unit.setTimer('update', 1)

-- Runs first update
updateScreens()