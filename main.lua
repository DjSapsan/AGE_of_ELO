if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then require("lldebugger").start() end

local Game = require "Game"
local Graphics = require "Graphics"

-- TODO make all local
function love.load()

  --selectedName = "DjSapsan"

  love.window.setMode(1920, 768, {resizable=true, vsync=false, minwidth=400, minheight=300})
  --love.filesystem.setIdentity("AgeOfElo") -- folder to save files
  math.randomseed(os.time())

  -- 199325 = Hera
  parameters = {savePredictions = true, isScenario = false, getDataPoints = false,lastPrediction = "", run = 0,playersFromRM = true, playerDynamics = true, pause = false, draw = true, trackPlayerID = 199325}

  graph = Graphics:new()
  EloGraph = graph:newHistogram(600, 600)
  PlayersGraph = graph:newHistogram(600, 600)

  Game.initialize()
  --if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then require("lldebugger").start() end
end

function love.quit()
end

function love.mousepressed(x,y,button)
  if button == 2 then
    Game.gameStep()
  end
end

function love.keypressed(key, scancode, isrepeat)

  if key == "right" then
    Game.gameStep()
  end

  if key == "g" then
    parameters.draw = not parameters.draw
  end

  if key == "up" then
  end

  if key == "down" then
  end

  if key == "tab" then
    --parameters.playerDynamics = not parameters.playerDynamics
  end

  if key == "space" then
    parameters.pause = not parameters.pause
  end

  if key == "1" then
    --Game.addRandomPlayers(10)
    --table.sort(Game.playerDB.table, function(p1,p2) return p1.rating>p2.rating end)
  end

  if key == "2" then
    -- Game.addRandomPlayers(1000)
    -- table.sort(Game.playerDB.table, function(p1,p2) return p1.rating>p2.rating end)
  end

  if key == "3" then
  end
end

function love.update(dt)
  if not parameters.pause then
      Game.gameStep()
  end
end

local info = [[
  Simulation of the Red Bull Empire Wars ladder
-------------------------------------------------------
Initiated by up-to-date real ladder (combined RB and RM)
After loading initial data
   all players are evaluated for skill and activity values.
Then, in the simulation, players are matched and play.
Who wins or loses is based on the skills of the matched players.
After each match, Elo and other stats are updated.
Players are more likely to match if their rank is similar
   and they "joined" the queue at the same time.
Each day I'm loading new data
   so it will become more and more accurate toward the end.
]]

function love.draw()

  local numberOfGamesPrint = string.format("Number of games played: %i / %i [%i%%]", Game.stat.totalGames, Game.gamesLeftToPlay, 100 * Game.stat.totalGames/Game.gamesLeftToPlay)
  love.graphics.setColor(1,1,1,1)
  graph:drawCanvas(EloGraph,10,50,1,1)
  graph:drawCanvas(PlayersGraph,10,660,1,1)
  love.graphics.setColor(1,1,1,1)

  --local topPlayer = Game.playerDB.table[1]
  --love.graphics.print("#1:"..topPlayer.name.." | ELO: "..topPlayer.rating.."| Games: "..topPlayer.games.."| Winrate: "..math.floor((topPlayer.wins / topPlayer.games) * 100).."%",0,0)
  --love.graphics.print("Number of players: "..#Game.playerDB.table,0,20)
  love.graphics.print(numberOfGamesPrint,0,10)
  love.graphics.print(info,600,20,0,2,2)
  love.graphics.print("Previous run: ",660,380)
  love.graphics.print(parameters.lastPrediction,660,400)
  --love.graphics.print("Steps: "..Game.stat.step,0,10)
  --if parameters.selected then love.graphics.print(Player.shortInfo(parameters.selected),0,80) end
  --love.graphics.print("Space - pause | Right Button Mouse - one step | 1 - add 10 new players | 2 - add 1000 | Tab - enable new players",600,10,0,1.5,1.5)
  --love.graphics.print("Sim speed: "..parameters.simSpeed,600,20)
  love.graphics.print("Leaderboard RB EW - sorted by highest Elo:", 1600,0)
  love.graphics.print(Game.topString, 1600,20)
  love.graphics.print(os.date("%d %B",Game.simIRLDay),1400,26,0,4,4)

end
