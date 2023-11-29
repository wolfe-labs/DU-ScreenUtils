-- The Container Hub dimensions
local HUB_WIDTH, HUB_HEIGHT = 232, 100

-- The hub progress bar properties
local HUB_PROGRESS_WIDTH, HUB_PROGRESS_HEIGHT = 1.5 * VOXEL_SIZE, 8

-- Set-up our background layer
local layerBackground = createLayer()
local loadedBackground = loadImage(BACKGROUND)

-- Set-up our contours layer
local layerContour = createLayer()

-- Set-up our data layer
local layerData = createLayer()
local fontLabel = loadFont(HUB_LABEL_FONT, toPixel(HUB_LABEL_SIZE))
local fontProgress = loadFont(HUB_PROGRESS_FONT_NAME, toPixel(HUB_PROGRESS_FONT_SIZE))
setDefaultTextAlign(layerData, AlignH_Center, AlignV_Top)

-- Returns an HDR color from RGBA
function color(intensity, rgba)
  return {
    tonumber(rgba[1]) / 255 * intensity,
    tonumber(rgba[2]) / 255 * intensity,
    tonumber(rgba[3]) / 255 * intensity,
    tonumber(rgba[4]) or 1,
  }
end

-- Returns an HDR color from RGBA, but as function parameters
function colorParam(intensity, rgba)
  return table.unpack(color(intensity, rgba))
end

-- Rounds a number to N decimals
function round(number, decimals)
  local multiplier = math.pow(10, decimals)
  return math.floor(number * multiplier) / multiplier
end

-- Draws a box
function drawBox(layer, x, y, width, height, colorRgba, colorIntensity)
  if colorRgba then
    setNextFillColor(layer, colorParam(colorIntensity, colorRgba))
  end
  addBox(layer, toPixel(x), toPixel(y), toPixel(width), toPixel(height))
end

-- Draws a box (outline)
function strokeBox(layer, x, y, width, height, thickness, colorRgba, colorIntensity)
  drawLineShape(layer, {
    { x, y },
    { x + width, y },
    { x + width, y + height },
    { x, y + height },
  }, thickness, colorRgba, colorIntensity)
end

-- Draws text
function drawText(layer, font, text, x, y, colorRgba, colorIntensity)
  if colorRgba then
    setNextFillColor(layer, colorParam(colorIntensity, colorRgba))
  end
  addText(layer, font, text, toPixel(x), toPixel(y))
end

-- Draws a shape made out of lines
function drawLineShape(layer, points, thickness, colorRgba, colorIntensity)
  for _, point in pairs(points) do
    local nextPoint = points[_ + 1] or points[1]
    
    if colorRgba then
      setNextStrokeColor(layer, colorParam(colorIntensity, colorRgba))
    end
    setNextStrokeWidth(layer, thickness)
    addLine(layer, toPixel(point[1]), toPixel(point[2]), toPixel(nextPoint[1]), toPixel(nextPoint[2]))
  end
end

-- Draws a progress bar
function drawProgressBar(layer, x, y, width, height, progress, label)
  -- Draws the progress bar
  drawBox(layer, x, y, width, height, HUB_PROGRESS_BACKGROUND, HUB_PROGRESS_BACKGROUND_INTENSITY)
  drawBox(layer, x, y, width * progress, height, HUB_PROGRESS_FOREGROUND, HUB_PROGRESS_FOREGROUND_INTENSITY)
  strokeBox(layer, x, y, width, height, HUB_BORDER_THICKNESS, HUB_PROGRESS_BORDER, HUB_PROGRESS_BORDER_INTENSITY)

  -- Draws the label
  if label then
    setNextTextAlign(layer, AlignH_Center, AlignV_Middle)
    setNextShadow(layer, toPixel(1), colorParam(HUB_PROGRESS_BACKGROUND_INTENSITY, HUB_PROGRESS_BACKGROUND))
    drawText(layer, fontProgress, label, x + 0.5 * width, y + 0.5 * height, HUB_PROGRESS_TEXT_COLOR, HUB_PROGRESS_TEXT_COLOR_INTENSITY)
  end
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
    { left + offset, top - offset },
    { right - offset, top - offset },
    { right + offset, top + offset },
    { right + offset, bottom - offset },
    { right - offset, bottom + offset },
    { left + offset, bottom + offset },
    { left - offset, bottom - offset },
    { left - offset, top + offset },
  }, HUB_BORDER_THICKNESS, HUB_BORDER_COLOR, HUB_BORDER_COLOR_INTENSITY)

  -- Draws hub name
  local usedPercentage = (hub.total > 0 and hub.used / hub.total) or 0
  local label = hub.name
  if HUB_LABEL_PERCENTAGE_ENABLED then
    label = ('%s (%.2f%%)'):format(hub.name, 100 * usedPercentage)
  end
  drawText(layerData, fontLabel, label, centerX, bottom + 2 * offset + 0.5 * HUB_PROGRESS_HEIGHT, HUB_LABEL_COLOR, HUB_LABEL_COLOR_INTENSITY)

  -- Draws hub fill progress
  if HUB_PROGRESS_ENABLED then
    drawProgressBar(
      layerData,
      centerX - 0.5 * HUB_PROGRESS_WIDTH,
      bottom + offset - 0.5 * HUB_PROGRESS_HEIGHT,
      HUB_PROGRESS_WIDTH,
      HUB_PROGRESS_HEIGHT,
      usedPercentage
    )
  end
end

-- Draws the background
setNextFillColor(layerBackground, BACKGROUND_INTENSITY, BACKGROUND_INTENSITY, BACKGROUND_INTENSITY, 1.0);
addImage(layerBackground, loadedBackground, 0, 0, PIXEL_WIDTH, PIXEL_HEIGHT)

-- Draws the hubs
for _, hub in pairs(hubs) do
  drawHub(hub)
end