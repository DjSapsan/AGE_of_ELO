local json = require('dkjson')
local Player = require('Player')
local PlayerDB = require('PlayerDB')
local Game = {}

local ELO_STEP_DIFFERENCE = 64

function Game.initialize()
  Game.readyList = {}

  Game.playerDB = PlayerDB

  Game.stat = {
    sessions = 0,
    totalGames = 0,
    lessTenGames = 0,
    playersByELO50 = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0} -- 0..50, 51..100, (...), 2400+
  }
end

local round = function(num)
  return math.floor(num+0.5)
end

local gaussian = function(mean, variance)                                                                 -- mean, variance
  return math.sqrt(-2.0 * variance * math.log(math.random())) * math.cos(2.0 * math.pi * math.random()) + mean
end

local getCoefficient = function(p)
  if p.games <= 20 then return 100 end
  --if p.rank <= 100 then return 16 end -- CHECK THIS
  --if player.place <= 200 then return 16 end -- CHECK THIS
  return 32
end

function Game.changeELO(player1,player2)
  local expected = 1 / (1 + 10 ^ ( ( player2.rating - player1.rating) / 400 ) )
  local K1 = getCoefficient(player1)
  local K2 = getCoefficient(player1)
  player1.rating = player1.rating + round(K1 * (expected))
  player2.rating = player2.rating - round(K2 * (expected))
end

function Game.firstSession()
  for _,player in ipairs(PlayerDB.table) do
      table.insert(Game.readyList, player)
  end
  if #Game.readyList % 2 == 1 then          -- if odd number of players, then remove last one
    table.remove(Game.readyList, #Game.readyList)
  end
  Game.readyPlayersPlay()
  PlayerDB.updatePlaces()
end

function Game.oneSession()
  Game.whoIsReady()
  Game.readyPlayersPlay()
  table.sort(PlayerDB.table, function(p1,p2) return p1.rating>p2.rating end)

  local index -- splitting by ELO
  Game.stat.playersByELO50 = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0} -- 0..50, 51..100, (...), 2400+
  for i = 1, #PlayerDB.table do
    index = round(PlayerDB.table[i].rating/50)
    if index > 50 then index = 50 end
    if index < 1 then index = 1 end
    Game.stat.playersByELO50[index] = Game.stat.playersByELO50[index] + 1
  end
  Game.stat.sessions = Game.stat.sessions+1
  PlayerDB.updatePlaces()
end

function Game.whoIsReady()
  for _,player in ipairs(PlayerDB.table) do
    if player.online > math.random() or player.games<2 then
      table.insert(Game.readyList, player)
    end
  end
  if #Game.readyList % 2 == 1 then          -- if odd number of players, then remove one randomly
    table.remove(Game.readyList, math.random(1,#Game.readyList))
  end
end

function Game.readyPlayersPlay()

  for i = 1, #Game.readyList, 2 do
    local player1 = Game.readyList[i]
    local player2 = Game.readyList[i+1]

    if math.abs(player1.rating - player2.rating) < ELO_STEP_DIFFERENCE then -- probability of playing based on ELO difference
      Game.playMatch(player1, player2)
    elseif math.abs(player1.rating - player2.rating) < 2*ELO_STEP_DIFFERENCE then
      if 0.250 > math.random() then
        Game.playMatch(player1, player2)
      end
    elseif math.abs(player1.rating - player2.rating) < 4*ELO_STEP_DIFFERENCE then
      if 0.125 > math.random() then
        Game.playMatch(player1, player2)
      end
    elseif math.abs(player1.rating - player2.rating) < 8*ELO_STEP_DIFFERENCE then
      if 0.0275 > math.random() then
        Game.playMatch(player1, player2)
      end
    end
  end

  Game.readyList = {}

end

function Game.playMatch(player1, player2)
  Game.stat.totalGames = Game.stat.totalGames + 1
  local probability = 1 / (1 + 10^( ( player2.skill - player1.skill) / 400 ) ) -- probability of player1 win

  if probability > math.random() then
    Game.changeELO(player1,player2)      -- first player won
    player1.wins = player1.wins + 1
    player2.losses = player2.losses + 1
    if parameters.selected and (parameters.selected==player1 or parameters.selected==player2) then
      print(Game.printResults(player1,player2,probability))
    end
  else
    Game.changeELO(player2,player1)      -- second player won
    player2.wins = player2.wins + 1
    player1.losses = player1.losses + 1
    if parameters.selected and (parameters.selected==player1 or parameters.selected==player2) then
      print(Game.printResults(player2,player1,1-probability))
    end
  end
  player1.games = player1.games + 1
  player2.games = player2.games + 1
  player1.skill = player1.skill + 100/((player1.games+50)/10+player1.skill/10)
  player2.skill = player2.skill + 200/((player2.games+50)/10+player2.skill/10)
end

function Game.printResults(won,lost,probability)
  return string.format("%-17s (%4d) won against %-17s (%4d) with probability %.2f", won.name, won.rating, lost.name, lost.rating, probability)
end

function Game.addRealPlayers()
  --local f = io.open("AoEDBshort.json", "r");  if not f then error("no file error") end
  local f = io.open("AoEDB_14_06_23.json", "r");  if not f then error("no file error") end
  local jsonText = f:read("*all")
  f:close()
  local board = json.decode(jsonText)
  for id, p in pairs(board) do
    PlayerDB.addPlayer(p)
  end
  table.sort(PlayerDB.table, function(p1,p2) return p1.rating>p2.rating end)
  Game.playerDB.determineHiddenVariables()
  PlayerDB.overridePlayerValues()
  PlayerDB.updatePlaces()
end


function Game.addRandomPlayers(n)
  local p
  for i = 1, n do
    p = Player.new(math.random(1000000,999999999),(#PlayerDB.table+1), 1000, nil, nil, "rnd_Player"..(#PlayerDB.table+1)," ","no",0,0,0,0,0,0,0,0,0,0)
    p.skill =  gaussian(1100, 40000)
    p.online = math.random()/2+0.01
    PlayerDB.addPlayer(p)
  end
  table.sort(PlayerDB.table, function(p1,p2) return p1.rating>p2.rating end)
  PlayerDB.updatePlaces()
  Game.playerDB.determineHiddenVariables()
end

return Game
