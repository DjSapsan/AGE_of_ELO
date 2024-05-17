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

  -- Histogram parameters
  local maxELO = 3100
  local lineHeight = (height-20) / maxELO
  local totalPlayers = #t

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
  local lineWidth = (width-40)/50 -- 50 bars
  local thickness = lineWidth - 2

  local max = 0
  for i=1,50 do
    if max < Game.stat.playersByELO50[i] then
      max = Game.stat.playersByELO50[i]
    end
  end

  local lineHeight = (height-80)/max
  local amount = 0
  love.graphics.setColor(0.5,0.5,1) -- rectangle histogram
  for i=1,50 do
    amount = Game.stat.playersByELO50[i]
    love.graphics.rectangle("fill", i*lineWidth + 2 + 40, height-40, thickness, -amount*lineHeight)
  end

  love.graphics.setColor(1,1,1) -- rating
  for i=0,49 do
    love.graphics.print((i*50).."-", i*lineWidth+41, height-2, -1.57079633)
  end

  -- TODO rework need correct numbers
  -- local percentH = math.floor(#t/(max))
  -- for i=1,50 do
  --   love.graphics.print(i*percentH,0,height- i*(height-40)/50 - 45)
  -- end

  for i=1,50 do
    if Game.stat.playersByELO50[i] > 0 then
      love.graphics.print(Game.stat.playersByELO50[i], i*lineWidth+41, height-50, -1.57079633)
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
