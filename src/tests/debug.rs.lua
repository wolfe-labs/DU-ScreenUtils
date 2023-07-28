-- Gets screen resolution
local w, h = getResolution()

local colorGrid = { 0.3, 0.6, 1.0, 1 }
local colorText = { 1.0, 0.6, 0.3, 1 }

-- Let's add the grid
local layerGrid = createLayer()
setDefaultFillColor(layerGrid, Shape_Box, 0, 0, 0, 1)
setDefaultStrokeColor(layerGrid, Shape_Box, table.unpack(colorGrid))
setDefaultStrokeWidth(layerGrid, Shape_Box, toPixel(2))
for x = 0 - POINT_X, POINT_WIDTH, VOXEL_SIZE do
  for y = 0 - POINT_Y, POINT_HEIGHT, VOXEL_SIZE do
    addBox(layerGrid, toPixel(x), toPixel(y), toPixel(VOXEL_SIZE), toPixel(VOXEL_SIZE))
  end
end

-- Let's render some text
local layerText = createLayer()
local font = loadFont('Play', toPixel(24))
setNextFillColor(layerText, table.unpack(colorText))
setNextTextAlign(layerText, AlignH_Center, AlignV_Middle)
addText(layerText, font, 'Hello, World!', w / 2, h / 2)