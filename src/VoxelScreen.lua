-- Wrapper around a ScreenUnit element, adding support to precise (up to 1 voxel coordinate) sizing and positioning of elements
-- by Wolfe Labs
-- https://github.com/wolfe-labs/DU-ScreenUtils

local json = require('json')
local VoxelUtils = require('VoxelUtils')
local VOXEL_SIZE, convertMetricToVoxelSize = VoxelUtils.VOXEL_SIZE, VoxelUtils.convertMetricToVoxelSize

-- The Legacy and Modern Screen "chin" sizes
local VOXEL_LEGACY_CHIN = 12
local VOXEL_MODERN_CHIN = 16
local VOXEL_SIGN_BORDER = 3

--- Returns a number in positive or negative values
---@param number number
---@return number
local function getSign(number)
  if number > 0 then
    return 1
  elseif number < 0 then
    return -1
  end
  return 0
end

--- Returns a vector's sign in positive or negative values
---@param vector vec3
---@return number
local function getVectorLengthSign(vector)
  local operator = vector:normalize()
  return getSign(operator.x + operator.y + operator.z)
end

--- Returns a vector's length with positive/negative values
---@param vector vec3
---@return number
local function getVectorSignedLength(vector)
  if getVectorLengthSign(vector) < 0 then
    return -vector:len()
  end
  return vector:len()
end

--- Returns a Screen with voxel-aware sizing enabled
---@param screen Screen
local function VoxelScreen(screen)
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
  local voxelReferenceWidth = convertMetricToVoxelSize(referenceWidth) - 1 * voxelBorderSize

  -- Consider a few extra offsets that might interfer in our positioning, such as borders and chins
  local baseVoxelOffsetX = 0.5 * voxelBorderSize
  local baseVoxelOffsetY = 0.5 * voxelBorderSize + 0.5 * voxelChinSize

  -- Generates some basic information for screen positioning

  -- Get screen orientation (to calculate horizontal and vertical positions), plus the sign (we'll use it to adjust positioning later)
  local screenOrientationHorizontal = vec3(screen.getRight())
  local screenOrientationVertical = vec3(screen.getUp())
  local screenOrientationSignX = getVectorLengthSign(screenOrientationHorizontal)
  local screenOrientationSignY = getVectorLengthSign(screenOrientationVertical)

  -- Get screen positioning (horizontal and vertical)
  local screenPosition = vec3(screen.getPosition())
  local screenPositionX = getVectorSignedLength(screenPosition * screenOrientationHorizontal * screenOrientationSignX)
  local screenPositionY = getVectorSignedLength(screenPosition * screenOrientationVertical * screenOrientationSignY)

  -- Finally, let's get the screen's top left coordinate, this is used both to calculate the voxel grid and to calculate positions via getPointOnScreen()
  local screenPositionLeft = screenPositionX + (0.5 * metricWidth) * screenOrientationSignX
  local screenPositionTop = screenPositionY + (0.5 * metricHeight) * screenOrientationSignY

  -- Calculate screen offset from voxel grid
  local voxelOffsetX = (0.5 * VOXEL_SIZE - (convertMetricToVoxelSize(screenPositionLeft) - baseVoxelOffsetX * screenOrientationSignX) * screenOrientationSignX) % VOXEL_SIZE
  local voxelOffsetY = (0.5 * VOXEL_SIZE - (convertMetricToVoxelSize(screenPositionTop) - baseVoxelOffsetY * screenOrientationSignY) * screenOrientationSignY) % VOXEL_SIZE

  --- Renders a Render Script with extra voxel/point metadata
  ---@param renderScript string
  local function fnRender(renderScript, data)
    -- Those are the lines prepending the script
    local scriptPreload = {
      'local json = require(\'json\')',
      'local VOXEL_SIZE = ' .. VOXEL_SIZE,
      'local PIXEL_WIDTH, PIXEL_HEIGHT = getResolution()',
      'local POINT_SIZE = PIXEL_WIDTH / ' .. voxelReferenceWidth,
      'local POINT_X = ' .. voxelOffsetX,
      'local POINT_Y = ' .. voxelOffsetY,
      'local POINT_WIDTH = ' .. voxelReferenceWidth,
      'local POINT_HEIGHT = math.floor(POINT_WIDTH * PIXEL_HEIGHT / PIXEL_WIDTH)',
      'function toPixel(points) return points * POINT_SIZE end',
    }

    -- Generate data rows
    for k, v in pairs(data or {}) do
      table.insert(scriptPreload, ('local %s = json.decode([[ %s ]])'):format(k, json.encode(v)))
    end

    -- Finally adds the render script
    table.insert(scriptPreload, renderScript)

    -- Prepends voxel globals
    screen.setRenderScript(
      table.concat(scriptPreload, '\n')
    )
  end

  --- Gets the voxel screen coordinate of a 3D location in space, in local coordinates
  ---@param point vec3 The 3D point being projected, in local coordinate space
  ---@return table<number,number> The X and Y voxel coordinates
  local function fnGetPointOnScreen(point)
    -- Converts position to screen-space
    local pointX = getVectorSignedLength(point * screenOrientationHorizontal * screenOrientationSignX)
    local pointY = getVectorSignedLength(point * screenOrientationVertical * screenOrientationSignY)

    -- Calculates offset from top left position
    local offsetX = ((screenOrientationSignX > 0) and (screenPositionLeft - pointX)) or (pointX - screenPositionLeft)
    local offsetY = ((screenOrientationSignY > 0) and (screenPositionTop - pointY)) or (pointY - screenPositionTop)

    -- Calculates final voxel position
    return {
      convertMetricToVoxelSize(offsetX) - baseVoxelOffsetX,
      convertMetricToVoxelSize(offsetY) - baseVoxelOffsetY
    }
  end

  return {
    sign = isSign,
    modern = isModernScreen,
    transparent = isTransparentScreen,
    voxelWidth = convertMetricToVoxelSize(metricWidth),
    voxelHeight = convertMetricToVoxelSize(metricHeight),
    render = fnRender,
    getPointOnScreen = fnGetPointOnScreen,
  }
end

return VoxelScreen