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

-- The Legacy and Modern Screen "chin" sizes
local VOXEL_LEGACY_CHIN = 12
local VOXEL_MODERN_CHIN = 16
local VOXEL_SIGN_BORDER = 3

--- How many voxel "points" are there per voxel
local VOXEL_SIZE = 84

--- How many voxel "points" are there in a meter
local VOXEL_POINTS_PER_METER = VOXEL_SIZE * 4

--- Converts a value from meters to voxels
---@param metricSize number
---@return number
local function metricToVoxelSize(metricSize)
  return math.floor(metricSize * VOXEL_POINTS_PER_METER)
end

--- Returns a Screen with voxel-aware sizing enabled
---@param screen Screen
function VoxelScreen(screen)
  -- Extract basic information
  local screenItem = system.getItem(screen.getItemId())
  local isSign = (screenItem.displayName:find('Sign') and true) or false
  local isModernScreen = (screenItem.displayName:find('Modern') and true) or false
  local isTransparentScreen = (screenItem.displayName:find('Transparent') and true) or false

  -- Calcualte screen size
  local size = screen.getBoundingBoxSize()
  local metricWidth = size[1]
  local metricHeight = size[3]
  local referenceWidth = math.floor(metricWidth)

  -- Calculate chin size
  local voxelChinSize = 0
  if isModernScreen then
    voxelChinSize = VOXEL_MODERN_CHIN
  elseif not isTransparentScreen then
    voxelChinSize = VOXEL_LEGACY_CHIN
  end

  -- Calculate border size
  local voxelBorderSize = 0
  if isSign then
    voxelBorderSize = VOXEL_SIGN_BORDER
  end

  -- Calcualte final voxel/point size
  local voxelReferenceWidth = metricToVoxelSize(referenceWidth) - 1 * voxelBorderSize

  -- Consider a few extra offsets that might interfer in our positioning, such as borders and chins
  local offsetX = 0.5 * voxelBorderSize
  local offsetY = 0.5 * voxelBorderSize + 0.5 * voxelChinSize

  -- Calculate screen offset from voxel grid
  local position = vec3(screen.getPosition())
  local positionX = (position * vec3(screen.getRight())):len() - 0.5 * metricWidth
  local positionY = (position * vec3(screen.getUp())):len() - 0.5 * metricHeight
  local voxelOffsetX = 0.5 * VOXEL_SIZE + (metricToVoxelSize(positionX) + offsetX) % VOXEL_SIZE
  local voxelOffsetY = 0.5 * VOXEL_SIZE + (metricToVoxelSize(positionY) + offsetY) % VOXEL_SIZE

  return {
    sign = isSign,
    modern = isModernScreen,
    transparent = isTransparentScreen,
    voxelWidth = metricToVoxelSize(metricWidth),
    voxelHeight = metricToVoxelSize(metricHeight),
    render = function(renderScript)
      -- Prepends voxel globals
      screen.setRenderScript(
        table.concat({
          'local VOXEL_SIZE = ' .. VOXEL_SIZE,
          'local PIXEL_WIDTH, PIXEL_HEIGHT = getResolution()',
          'local POINT_SIZE = PIXEL_WIDTH / ' .. voxelReferenceWidth,
          'local POINT_X = ' .. voxelOffsetX,
          'local POINT_Y = ' .. voxelOffsetY,
          'local POINT_WIDTH = ' .. voxelReferenceWidth,
          'local POINT_HEIGHT = math.floor(POINT_WIDTH * PIXEL_HEIGHT / PIXEL_WIDTH)',
          'function toPixel(points)',
          'return points * POINT_SIZE',
          'end',
          renderScript,
        }, '\n')
      )
    end
  }
end

local VOXEL_SIZE = 84
-- function getScreenVoxelSize()

-- Assigns test script
for _, screenElement in pairs(screens) do
  local screen = VoxelScreen(screenElement)
  screen.render(script)
end

unit.exit()