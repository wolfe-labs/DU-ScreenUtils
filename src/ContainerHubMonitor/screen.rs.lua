-- The background image
local BACKGROUND = 'assets.prod.novaquark.com/113304/f91e8dcb-94c5-4ee0-ac38-c1fa39ddd62f.png'

-- The Container Hub dimensions
local HUB_WIDTH, HUB_HEIGHT = 232, 100

-- The hub border parameters
local HUB_BORDER_OFFSET, HUB_BORDER_THICKNESS = 8, 2
local HUB_BORDER_COLOR = { 255, 127, 0 }

-- The hub text properties
local HUB_LABEL_FONT, HUB_LABEL_SIZE = 'Oxanium', 16
local HUB_LABEL_COLOR = { 255, 127, 0 }

-- The hub progress bar properties
local HUB_PROGRESS_ENABLED = true
local HUB_PROGRESS_WIDTH, HUB_PROGRESS_HEIGHT = 1.5 * VOXEL_SIZE, 8
local HUB_PROGRESS_FONT_NAME, HUB_PROGRESS_FONT_SIZE = 'Oxanium', HUB_PROGRESS_HEIGHT
local HUB_PROGRESS_BACKGROUND = { 191, 191, 191 }
local HUB_PROGRESS_FOREGROUND = { 255, 127, 0 }
local HUB_PROGRESS_TEXT_COLOR = { 0, 0, 0 }

-- Set-up our background layer
local layerBackground = createLayer()
local loadedBackground = loadImage(BACKGROUND)
addImage(layerBackground, loadedBackground, 0, 0, PIXEL_WIDTH, PIXEL_HEIGHT)

-- Set-up our contours layer
local layerContour = createLayer()

-- Set-up our data layer
local layerData = createLayer()
local fontLabel = loadFont(HUB_LABEL_FONT, toPixel(HUB_LABEL_SIZE))
local fontProgress = loadFont(HUB_PROGRESS_FONT_NAME, toPixel(HUB_PROGRESS_FONT_SIZE))
setDefaultTextAlign(layerData, AlignH_Center, AlignV_Top)

-- Returns an HDR color from RGBA
function color(rgba)
  return {
    rgba[1] / 255,
    rgba[2] / 255,
    rgba[3] / 255,
    rgba[4] or 1,
  }
end

-- Rounds a number to N decimals
function round(number, decimals)
  local multiplier = math.pow(10, decimals)
  return math.floor(number * multiplier) / multiplier
end

-- Draws a box
function drawBox(layer, x, y, width, height, colorRgba)
  if colorRgba then
    setNextFillColor(layer, table.unpack(color(colorRgba)))
  end
  addBox(layer, toPixel(x), toPixel(y), toPixel(width), toPixel(height))
end

-- Draws text
function drawText(layer, font, text, x, y, colorRgba)
  if colorRgba then
    setNextFillColor(layer, table.unpack(color(colorRgba)))
  end
  addText(layer, font, text, toPixel(x), toPixel(y))
end

-- Draws a shape made out of lines
function drawLineShape(layer, points, thickness, colorRgba)
  for _, point in pairs(points) do
    local nextPoint = points[_ + 1] or points[1]
    
    if colorRgba then
      setNextStrokeColor(layer, table.unpack(color(colorRgba)))
    end
    setNextStrokeWidth(layer, thickness)
    addLine(layer, toPixel(point[1]), toPixel(point[2]), toPixel(nextPoint[1]), toPixel(nextPoint[2]))
  end
end

-- Draws a progress bar
function drawProgressBar(layer, x, y, width, height, progress)
  -- Draws the progress bar
  drawBox(layer, x, y, width, height, HUB_PROGRESS_BACKGROUND)
  drawBox(layer, x, y, width * progress, height, HUB_PROGRESS_FOREGROUND)

  -- Draws the label
  setNextTextAlign(layer, AlignH_Center, AlignV_Middle)
  drawText(layer, fontProgress, ('%.2f%%'):format(100 * progress), x + 0.5 * width, y + 0.5 * height, HUB_PROGRESS_TEXT_COLOR)
end

-- Helper function to draw a Container Hub
function drawHub(hub)
  local centerX = hub.pos[1]
  local centerY = hub.pos[2]

  -- Calculates hub positions
  local offset = HUB_BORDER_OFFSET
  local left, right = centerX - 0.5 * HUB_WIDTH, centerX + 0.5 * HUB_WIDTH
  local top, bottom = centerY - 0.5 * HUB_HEIGHT, centerY + 0.5 * HUB_HEIGHT

  -- Draws the hub contour
  drawLineShape(layerContour, {
    { left, top - offset },
    { right, top - offset },
    { right + offset, top },
    { right + offset, bottom },
    { right, bottom + offset },
    { left, bottom + offset },
    { left - offset, bottom },
    { left - offset, top },
  }, HUB_BORDER_THICKNESS, HUB_BORDER_COLOR)

  -- Draws hub name
  drawText(layerData, fontLabel, hub.name, centerX, bottom + 2 * offset + 0.5 * HUB_PROGRESS_HEIGHT, HUB_LABEL_COLOR)

  -- Draws hub fill progress
  if HUB_PROGRESS_ENABLED then
    drawProgressBar(
      layerData,
      centerX - 0.5 * HUB_PROGRESS_WIDTH,
      bottom + offset - 0.5 * HUB_PROGRESS_HEIGHT,
      HUB_PROGRESS_WIDTH,
      HUB_PROGRESS_HEIGHT,
      (hub.total > 0 and hub.used / hub.total) or 0
    )
    -- drawProgressBar(
    --   layerData,
    --   centerX - 0.5 * HUB_PROGRESS_WIDTH,
    --   bottom + 3 * offset + HUB_LABEL_SIZE,
    --   HUB_PROGRESS_WIDTH,
    --   HUB_PROGRESS_HEIGHT,
    --   (hub.total > 0 and hub.used / hub.total) or 0
    -- )
  end
end

-- Draws the background

-- Draws the hubs
for _, hub in pairs(hubs) do
  drawHub(hub)
end