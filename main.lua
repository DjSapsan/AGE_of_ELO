---@diagnostic disable: lowercase-global
if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then require("lldebugger").start() end

CLASS = require "middleclass"
Game = require "Game"
Player = require "Player"
Graphics = require "Graphics"
DBmanager = require "PlayerDB"
--namegen = require "randomnamegen.namegen"

function love.load()
  love.window.setMode(1920, 768, {resizable=true, vsync=false, minwidth=400, minheight=300})

  selectedName = "[aM]MbL40C"

  math.randomseed(os.time())
  Game.initialize()

  graph = Graphics:new()
  EloGraph = graph:newHistogram(800, 600)
  PlayersGraph = graph:newHistogram(800, 600)

  Game.addRealPlayers()
  --Game.addRandomPlayers(2000)

  parameters = {selected = Game.playerDB.findPlayer("name",selectedName), pause = false, newPlayers = true, steps = 0, simSpeed = 10, draw = true}

  Game.firstSession()

end

function love.quit()
end

function love.mousepressed(x,y,button)
  if button == 2 then
    gameStep()
  end
end

function love.keypressed(key, scancode, isrepeat)

  if key == "right" then

  end

  if key == "g" then
    parameters.draw = not parameters.draw
  end

  if key == "up" then
    -- increase sim speed
    parameters.simSpeed = parameters.simSpeed + 10
  end

  if key == "down" then
    -- decrease sim speed
    parameters.simSpeed = parameters.simSpeed - 10
    if parameters.simSpeed < 1 then parameters.simSpeed = 1 end
  end

  if key == "tab" then
    playerDynamics = not playerDynamics
  end

  if key == "space" then
    pause = not pause
  end

  if key == "1" then
    Game.addRandomPlayers(10)
    table.sort(Game.playerDB.table, function(p1,p2) return p1.rating>p2.rating end)
  end

  if key == "2" then
    Game.addRandomPlayers(1000)
    table.sort(Game.playerDB.table, function(p1,p2) return p1.rating>p2.rating end)
  end

  if key == "3" then
  end
end

function gameStep()
  Game.oneSession()
  if playerDynamics and Game.stat.sessions%math.floor(Game.stat.sessions/16)==0 then    -- every s session add n new players
    Game.addRandomPlayers(8)
    Game.playerDB.updateLeavers(0.01)
    Game.playerDB.playerDeath(0.001)
    table.sort(Game.playerDB.table, function(p1,p2) return p1.rating>p2.rating end)
    Game.playerDB.updatePlaces()
  end
  if parameters.draw then
    graph:updateELOHistogramCanvas(EloGraph, Game.playerDB.table, parameters.selected)
    graph:updatePlayersHistogramCanvas(PlayersGraph, Game.playerDB.table, parameters.selected)
  end
end

function love.update(dt)
  if not pause then
    for i=1,parameters.simSpeed do
      gameStep()
    end
  end
end

function love.draw()
  love.graphics.setColor(1,1,1,1)
  graph:drawCanvas(EloGraph,10,100,1,1)
  graph:drawCanvas(PlayersGraph,1000,100,1,1)
  local topPlayer = Game.playerDB.table[1]
  love.graphics.print("#1:"..topPlayer.name.." | ELO: "..topPlayer.rating.."| Games: "..topPlayer.games.."| Winrate: "..math.floor((topPlayer.wins / topPlayer.games) * 100).."%",0,0)
  love.graphics.print("Number of players: "..#Game.playerDB.table,0,20)
  love.graphics.print("Number of games played: "..Game.stat.totalGames,0,40)
  if parameters.selected then love.graphics.print(Player.shortInfo(parameters.selected),0,80) end
  love.graphics.print("Space - pause | Right Button Mouse - one step | 1 - add 10 new players | 2 - add 1000 | Tab - enable new players",600,10,0,1.5,1.5)
  love.graphics.print("Sim speed: "..parameters.simSpeed,600,40,0,1.5,1.5)
end
