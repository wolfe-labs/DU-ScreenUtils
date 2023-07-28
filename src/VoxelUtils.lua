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
local function convertMetricToVoxelSize(metricSize)
  return math.floor(metricSize * VOXEL_POINTS_PER_METER)
end

return {
  VOXEL_SIZE = VOXEL_SIZE,
  VOXEL_POINTS_PER_METER = VOXEL_POINTS_PER_METER,
  convertMetricToVoxelSize = convertMetricToVoxelSize,
}