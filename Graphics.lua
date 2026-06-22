local parameters = require("parameters")

local Game
local function initialize (game)
  Game = game
end

local function newHistogram(horizont, vertical)
  local canvas = love.graphics.newCanvas(horizont, vertical)
  return canvas
end

local function updateELOHistogramCanvas(canvas, t, LB_ID)
  love.graphics.setCanvas(canvas)
  love.graphics.clear()
  love.graphics.setBlendMode("alpha")

  -- Colors and dimensions
  love.graphics.setColor(0.5, 0.5, 1)
  local width, height = canvas:getDimensions()

  -- Histogram parameters: default scale covers up to ~3000 ELO,
  -- but expand if a higher-rated player is present.
  local totalPlayers = #t
  local maxELO = 3100
  for i = 1, totalPlayers do
    local r = t[i].LB[LB_ID].rating
    if r + 100 > maxELO then maxELO = r + 100 end
  end
  local lineHeight = (height-20) / maxELO

  -- Determine maximum number of bars based on canvas width (subtracted by margins)
  local maxBars = width - 40
  local playersPerBar = math.ceil(totalPlayers / maxBars)

  -- Drawing the histogram bars
  for i = 0, maxBars - 1 do
    local startPlayer = i * playersPerBar + 1
    local endPlayer = math.min(startPlayer + playersPerBar - 1, totalPlayers)
    local sumRating = 0
    local count = 0

    -- Sum up ratings for players represented by this bar
    for j = startPlayer, endPlayer do
      sumRating = sumRating + t[j].LB[LB_ID].rating
      count = count + 1
    end

    -- Calculate average rating if there are players to consider
    local avgRating = count > 0 and sumRating / count or 0
    local xPosition = width - 40 - i
    local yPosition = height - avgRating * lineHeight - 20
    love.graphics.line(xPosition, height-20, xPosition, yPosition)
  end

  -- Labels and decorations
  love.graphics.setColor(1, 1, 1)
  local labelCount = 10  -- Fixed number of labels
  local labelSpacing = (maxBars - 1) / (labelCount)

  -- Vertical lines at calculated intervals
  for i = 0, labelCount do
    local xPosition = width - 40 - (i * labelSpacing)
    love.graphics.print("|" .. math.floor(i * labelSpacing * playersPerBar + 1), xPosition, height - 20)
  end

  -- Horizontal labels at percentage intervals
  local percentH = 100--math.floor(maxELO / 50)
  for i = 5*percentH, maxELO, percentH do
    love.graphics.print(i.."_", 0, height - i * lineHeight-40)
  end

  -- ELO description
  love.graphics.print("ELO OF EACH PLAYER \n Total players: " .. totalPlayers, 100, 0, 0, 2, 2)

  -- Drawing rectangle around the histogram
  love.graphics.setColor(0.5, 0.5, 0.5)
  love.graphics.rectangle("line", 0, 0, width, height)

  -- Reset canvas
  love.graphics.setCanvas()
end

local function updatePlayersHistogramCanvas(canvas, t)
  love.graphics.setCanvas(canvas)
  love.graphics.clear()
  love.graphics.setBlendMode("alpha")

  local width, height = canvas:getDimensions()
  local buckets = Game.stat.playersByELO50
  local numBuckets = #buckets
  local lineWidth = (width-40)/numBuckets -- one bar per ELO bucket (auto-expands past 3000)
  local thickness = math.max(1, lineWidth - 2)

  local max = 0
  for i=1,numBuckets do
    if max < buckets[i] then
      max = buckets[i]
    end
  end
  if max == 0 then max = 1 end

  local lineHeight = (height-80)/max
  local amount = 0
  love.graphics.setColor(0.5,0.5,1) -- rectangle histogram
  for i=1,numBuckets do
    amount = buckets[i]
    love.graphics.rectangle("fill", i*lineWidth + 2 + 40, height-40, thickness, -amount*lineHeight)
  end

  love.graphics.setColor(1,1,1) -- rating
  for i=0,numBuckets-1 do
    love.graphics.print((i*50).."-", i*lineWidth+41, height-2, -1.57079633)
  end

  for i=1,numBuckets do
    if buckets[i] > 0 then
      love.graphics.print(buckets[i], i*lineWidth+41, height-50, -1.57079633)
    end
  end

  love.graphics.setColor(1,1,1)
  love.graphics.print("AMOUNT OF PLAYERS WITH ELO", 100, 0, 0, 1.5, 1.5)

  love.graphics.setColor(0.5,0.5,0.5)
  love.graphics.rectangle("line", 0, 0, width, height)

  love.graphics.setCanvas()
end

local function drawCanvas(canvas, x, y, scaleX, scaleY)
  love.graphics.draw(canvas, x or 0, y or 0, 0, scaleX or 1, scaleY or 1)
end

return {
  newHistogram = newHistogram,
  updateELOHistogramCanvas = updateELOHistogramCanvas,
  updatePlayersHistogramCanvas = updatePlayersHistogramCanvas,
  drawCanvas = drawCanvas,
  initialize = initialize
}
