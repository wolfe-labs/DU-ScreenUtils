local json = require('json')
local VoxelUtils = require('VoxelUtils')
local VOXEL_SIZE, convertMetricToVoxelSize = VoxelUtils.VOXEL_SIZE, VoxelUtils.convertMetricToVoxelSize

-- The Legacy and Modern Screen "chin" sizes
local VOXEL_LEGACY_CHIN = 12
local VOXEL_MODERN_CHIN = 16
local VOXEL_SIGN_BORDER = 3

--- Returns a vector's length with positive/negative values
---@param vector vec3
local function getSignedVectorLength(vector)
  local operator = vector:normalize()
  local orientation = operator.x + operator.y + operator.z

  if orientation < 0 then
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
  local screenOrientationHorizontal = vec3(screen.getRight())
  local screenOrientationVertical = vec3(screen.getUp())
  local screenPosition = vec3(screen.getPosition())
  local screenSignedValueX = getSignedVectorLength(screenOrientationHorizontal)
  local screenSignedValueY = getSignedVectorLength(screenOrientationVertical)
  local screenPositionLeft = screenOrientationHorizontal:len() * (screenPosition * screenOrientationHorizontal):len() - (0.5 * metricWidth) * screenSignedValueX
  local screenPositionTop = screenOrientationVertical:len() * (screenPosition * screenOrientationVertical):len() - (0.5 * metricHeight) * screenSignedValueY

  -- Calculate screen offset from voxel grid
  local voxelOffsetX = 0.5 * VOXEL_SIZE + (convertMetricToVoxelSize(screenPositionLeft) + baseVoxelOffsetX) % VOXEL_SIZE
  local voxelOffsetY = 0.5 * VOXEL_SIZE + (convertMetricToVoxelSize(screenPositionTop) + baseVoxelOffsetY) % VOXEL_SIZE

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
    local pointX = (point * screenOrientationHorizontal):len()
    local pointY = (point * screenOrientationVertical):len()

    -- Calcualtes offset from left and top positions
    local offsetX = (pointX - screenPositionLeft) * screenSignedValueX
    local offsetY = (pointY - screenPositionTop) * screenSignedValueY

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