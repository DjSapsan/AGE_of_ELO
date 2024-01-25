local Graphics = CLASS("Graphics")

function Graphics:initialize()
end

function Graphics:newHistogram(horizont, vertical)
  local canvas = love.graphics.newCanvas(horizont, vertical)
  return canvas
end

function Graphics:updateELOHistogramCanvas(canvas, t, selected)
  love.graphics.setCanvas(canvas)
  love.graphics.clear()
  love.graphics.setBlendMode("alpha")

  love.graphics.setColor(0.5,0.5,1)

  local width, height = canvas:getDimensions()
  local lineWidth = (width-40)/#t

  local maxELO = 3100
  --for _,p in ipairs(t) do
  --  if p.rating>maxELO then maxELO = p.rating end
  --end
  local lineHeight = (height-20)/maxELO
  local percentW = math.floor(#t/10)
  local percentH = math.floor(maxELO/50)

  for i=1,#t do
    if i == selected.rank then
      love.graphics.setColor(1,0,0)
      love.graphics.setLineWidth(5)
      love.graphics.line(width - i*lineWidth, height-20, width - i*lineWidth, height-t[i].rating*lineHeight-20)
      love.graphics.setLineWidth(1)
      love.graphics.setColor(0.5,0.5,1)
    else
      love.graphics.line(width - i*lineWidth, height-20, width - i*lineWidth, height-t[i].rating*lineHeight-20)
    end
  end

  love.graphics.setColor(1,1,1)
  for i=1,#t, percentW do
    love.graphics.print("|"..i.." ",width - i*lineWidth,height-20)
  end

  for i=1,maxELO, percentH do
    love.graphics.print(i,0,height - i*lineHeight-22)
  end

  love.graphics.setColor(1,1,1)
  love.graphics.print("ELO OF EACH PLAYER",100,0,0,1.5,1.5)

  love.graphics.setColor(0.5,0.5,0.5)
  love.graphics.rectangle("line",0,0,width, height)

  love.graphics.setCanvas()
end

function Graphics:updatePlayersHistogramCanvas(canvas, t, selected)

  love.graphics.setCanvas(canvas)
  love.graphics.clear()
  love.graphics.setBlendMode("alpha")

  local width, height = canvas:getDimensions()

  local lineWidth = (width-40)/50 -- 50 bars
  local thinkess = lineWidth - 2

  local lineHeight = (height-40)*10/#t -- amount of players
  --local percentW = math.floor(#t/10)
  --local percentH = math.floor(#t/50)
  --if arg[#arg] == "-debug" then require("mobdebug").start() end
  local amount = 0
  local max = 0

  love.graphics.setColor(0.1,0.1,0.1)
  for i=1,50 do
    amount = Game.stat.playersByELO50[i]
    love.graphics.line(0, height-40-amount*lineHeight, width, height-40-amount*lineHeight)
  end

  love.graphics.setColor(0.5,0.5,1)                                                                             -- rectangle histogram
  for i=1,50 do
    amount = Game.stat.playersByELO50[i]
    love.graphics.rectangle("fill", i*lineWidth + 2 + 40, height-40, thinkess, -amount*lineHeight)
    if max < Game.stat.playersByELO50[i] then max = Game.stat.playersByELO50[i] end
  end

  love.graphics.setColor(1,1,1)                                               -- rating
  for i=0,49 do
    love.graphics.print((i*50).."-",i*lineWidth+41,height-2,-1.57079633)
  end

  local percentH = math.floor(#t/50)
  for i=1,50 do
    love.graphics.print(math.floor(i*percentH/3),0,height- i*(height-40)/50 - 45)
  end

  for i=1,50 do
    if Game.stat.playersByELO50[i] > 0 then
      love.graphics.print(Game.stat.playersByELO50[i],i*lineWidth+41,height-50,-1.57079633)
    end
  end

  love.graphics.setColor(1,1,1)
  love.graphics.print("AMOUNT OF PLAYERS WITH ELO",100,0,0,1.5,1.5)

  love.graphics.setColor(0.5,0.5,0.5)
  love.graphics.rectangle("line",0,0,width, height)

  love.graphics.setCanvas()
end

function Graphics:drawCanvas(canvas,x,y,scaleX,scaleY)
  love.graphics.draw(canvas,x or 0,y or 0,0,scaleX or 1,scaleY or 1)
end

return Graphics
