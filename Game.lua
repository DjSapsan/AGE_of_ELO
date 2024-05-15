--local json = require('dkjson')
local PlayerDB = require('PlayerDB')
local Fit = require("Fit")
local utils = require("utils")
local Scenario = require("scenario")

local Game = {}

function Game.initialize()

  parameters.run = parameters.run + 1

  Game.playerDB = PlayerDB

  Game.LB_ID = 27
  PlayerDB.activeLB = Game.LB_ID

  Game.readyList = {}

  Game.topString = ""


  Game.stat = {
    step = 1,
    sessions = 0,
    totalGames = 0,
    playersByELO50 = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0} -- 0..50, 51..100, (...), 2400+
  }

  Game.IRLdayStartAt = os.time()

  -- set the last day IRL before where the simulation ends and restarts
  Game.IRLdaysRamaining = os.difftime(os.time({year = 2024, month = 7, day = 28}),os.time()) / (60 * 60 * 24) --until 28th of july

  -- IRL days passed since the specific date
  Game.IRLdaysPassed = os.difftime(os.time(),os.time({year = 2024, month = 5, day = 1})) / (60 * 60 * 24)

  -- IRL day in the simulation
  Game.simIRLDay = 0

  -- days passed from the start of the simulation
  Game.indexDay = 0

  -- temp variable to detect next day
  Game.lastDay = 0

  Game.moreActivityLastDays = 5 -- activates top players to become more active before the very end
  Game.moreActivityDone = false

  Game.paused = false
  Game.ended = false
  Game.saved = false

  if parameters.getDataPoints then Game.updateDataPointsFolder("LB_RB_EW") end

  if PlayerDB.isBackup then
    PlayerDB.restore()
  else
    Game.loadLatestResultsFolder("LB_RB_EW")
    Game.loadLatestResultsFolder("LB_RM")
  end

  --Game.addTopPlayers(27, 3, 100)
  Game.determineAverages()  -- use cache

  if parameters.isScenario then
    Scenario.set(Game)
  end

  Game.evaluatePlayers()
  PlayerDB.sortLB(Game.LB_ID)
  PlayerDB.updateRanksFromLB(Game.LB_ID)
end

local round = function(num)
  return math.floor(num+0.5)
end

function Game.oneSession()
  local LB_ID = Game.LB_ID
  Game.whoIsReady()
  Game.readyPlayersPlay()
  PlayerDB.sortLB(LB_ID)
  PlayerDB.updateRanksFromLB(LB_ID)
  Game.topString = Game.printTop(100, Game.LB_ID, false, "highestrating")
  Game.updateStats()
end

function Game.updateStats()
  local LB_ID = Game.LB_ID
  local index -- splitting by ELO
  local elo = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0} -- 0..50, 51..100, (...), 2400+

  for i = 1, #PlayerDB.LB[LB_ID] do
    local p = PlayerDB.LB[LB_ID][i]
    if p.LB[LB_ID].wins + p.LB[LB_ID].losses > 10 then  -- display only 10+ games
      index = round(p.LB[LB_ID].rating / 50)
      if index > 50 then index = 50
      elseif index < 1 then index = 1 end
      elo[index] = elo[index] + 1
    end
  end

  Game.stat.playersByELO50 = elo
  Game.stat.sessions = Game.stat.sessions+1

end

-- was used for random players
-- local gaussian = function(mean, variance)                                                                 -- mean, variance
--   return math.sqrt(-2.0 * variance * math.log(math.random())) * math.cos(2.0 * math.pi * math.random()) + mean
-- end

-- coefficient for elo scale
local getCoefficient = function(p)
  if PlayerDB.getNumberOfGames(p) <= 5 then return 100 end
  return 32
end

function Game.amountOfPlayers(LB_ID)
  if LB_ID then
    return #PlayerDB.LB[LB_ID]
  else
    return #PlayerDB.LB[Game.LB_ID]
  end
end

function Game.updateStage()

  if Game.stat.totalGames > Game.gamesLeftToPlay then
    Game.ended = true
    Game.paused = true
    Game.savePredictions()
  end

  if not Game.moreActivityDone and Game.stat.totalGames / Game.gamesLeftToPlay > Game.moreActivityLastDays then
    Game.changeActivity()
    Game.moreActivityDone = true
  end

  Game.checkNextDay()

end

-- TODO change activity only of grinders
function Game.changeActivity(top)
  local LB_ID = 27 --Game.LB_ID
  for i = 1, top or 50 do
    local p = PlayerDB.LB[LB_ID][i]
    if p.LB[LB_ID].lastmatchdate >= 0 then      -- if the player is original
      p.online = 1 + math.log10((p.online+0.11)/1.11) -- gives nice curve from 0 to 1
      p.skill = p.skill*1.01
    end
  end
end

function Game.savePredictions()
  if Game.saved then return end
  Game.saved = true

  local allResults = Game.printCSV(0, Game.LB_ID, false, "highestrating")
  local time = os.date("%Y-%m-%d-%X")
  parameters.lastPrediction = Game.topString

  --if parameters.run % 2 ~= 0 then return end
  if true then return end
  local f, err = io.open("Ladder/Ladder"..time..".csv", "w")
  if not f then print(err) return end
  f:write(allResults)
  f:close()
end

-- player 1 wins
function Game.changeELO(player1, player2)
  local LB_ID = Game.LB_ID
  local expectedWin = 1 / (1 + 10 ^ ( ( player2.LB[LB_ID].rating - player1.LB[LB_ID].rating) / 400 ) )
  --local expectedSkill = 1 / (1 + 10 ^ ( ( player2.skill - player1.skill) / 400 ) )  -- to show win probablity
  local K1 = getCoefficient(player1)
  local K2 = getCoefficient(player1)
  local changeP1 = round(K1 * (1-expectedWin))
  local changeP2 = round(K2 * (1-expectedWin))
  player1.LB[LB_ID].rating = player1.LB[LB_ID].rating + changeP1
  player2.LB[LB_ID].rating = player2.LB[LB_ID].rating - changeP2

  -- update other stats:
  if player1.LB[LB_ID].rating > player1.LB[LB_ID].highestrating then
    player1.LB[LB_ID].highestrating = player1.LB[LB_ID].rating
  end
  player1.LB[LB_ID].wins = player1.LB[LB_ID].wins + 1
  player2.LB[LB_ID].losses = player2.LB[LB_ID].losses + 1

  player1.LB[LB_ID].streak = player1.LB[LB_ID].streak + 1
  player2.LB[LB_ID].streak = 0

  --[[if parameters.trackPlayerID == player1.id then
  --print(string.format("%s won vs %s ( %i %% to win ) +%i", player1.alias, player2.alias, changeP1))-- 100*expectedSkill, changeP1))
  print(string.format("%s won vs %s\t+%i", player1.alias, player2.alias, changeP1))-- 100*expectedSkill, changeP1))
elseif parameters.trackPlayerID == player2.id then
  --print(string.format("%s lost vs %s ( %i %% to win ) -%i", player2.alias, player1.alias, changeP2))--100-100*expectedSkill, changeP2))
  print(string.format("%s lost vs %s\t-%i", player2.alias, player1.alias, changeP2))--100-100*expectedSkill, changeP2))
end]]
end

-- changing the constant means scaling the probability to win.
-- the main question - should it be changed? Looks like AoE games are too unreliable so weak players can beat strong sometimes.
-- 400 - default
-- 800 - players more equal
-- 200 - players more different
function Game.playMatch(player1, player2)
  local LB_ID = Game.LB_ID
  Game.stat.totalGames = Game.stat.totalGames + 1
  local probability = 1 / (1 + 10^( ( player2.skill - player1.skill) / 400 * Fit.params.winProbFactor ) ) -- probability of player1 win

  if probability > math.random() then
    Game.changeELO(player1,player2)      -- first player won
  else
    Game.changeELO(player2,player1)      -- second player won
  end
  -- player1.skill = player1.skill + 1
  -- player2.skill = player2.skill + 2
end

function Game.whoIsReady()
  local LB_ID = Game.LB_ID
  for _, player in ipairs(PlayerDB.LB[LB_ID]) do
    if player.online >= math.random() then
      table.insert(Game.readyList, player)
    end
  end
  if #Game.readyList % 2 == 1 then          -- if odd number of players, then remove one randomly
    table.remove(Game.readyList, math.random(1,#Game.readyList))
  end
end

function Game.restart()
  Game.reset()
  Game.initialize()
end

function Game.reset()
  package.loaded["PlayerDB"] = nil
  collectgarbage()
  PlayerDB = require('PlayerDB')
end

function Game.gameStep()

  Game.updateStage()

  if Game.ended then
    Game.paused = true
    Game.restart()
  end
  if Game.paused then return end

  Game.oneSession()

  if parameters.draw then
    graph:updateELOHistogramCanvas(EloGraph, PlayerDB.LB[Game.LB_ID], Game.LB_ID)
    graph:updatePlayersHistogramCanvas(PlayersGraph, PlayerDB.LB[Game.LB_ID])
  end

  Game.stat.step = Game.stat.step + 1
end

function Game.checkNextDay()
  local dayPassed = false

  local tDate = os.date("*t",Game.updateGameDay())
  local bigDay = tDate.year * 10000 * tDate.month * 100 + tDate.day -- trick to always count up

  if Game.lastDay == 0 then
    Game.lastDay = bigDay -- skip first iteration
    return
  end

  if bigDay > Game.lastDay then
    dayPassed = true
    Game.lastDay = bigDay
    Game.indexDay = Game.indexDay + 1
  end

  if dayPassed and parameters.playerDynamics then
    PlayerDB.updateLeavers(1 / Fit.params.leaversFactor, Game.LB_ID)
    Game.movePlayersFromOtherLB(27, 3)  -- issue - all players move suddenly in 1 day
  end

end

function Game.readyPlayersPlay()
  local LB_ID = Game.LB_ID
  local MAX_RATING_DIFFERENCE = 500
  local n = #Game.readyList
  local alreadyMatched = {}

  for i = 1, n-1 do
    if not alreadyMatched[i] then
      local player1 = Game.readyList[i]
      local potentialMatches = {}

      -- Gather potential opponents until the difference of 500 is reached
      local j = i + 1
      while j <= math.min(n, i + 50) do
        if not alreadyMatched[j] then
          local player2 = Game.readyList[j]
          local difference = math.abs(player1.LB[LB_ID].rating - player2.LB[LB_ID].rating)

          if difference <= MAX_RATING_DIFFERENCE then
            table.insert(potentialMatches, {index = j, player = player2, diff = difference})
          else
            break -- Stop adding if difference exceeds 500
          end
        end
        j = j + 1
      end

      -- Choose a match from potential matches with probability decreasing with difference
      for _, match in ipairs(potentialMatches) do
        -- Decrease the probability as the index increases
        local probability = ((MAX_RATING_DIFFERENCE - match.diff) / MAX_RATING_DIFFERENCE)^math.exp(1)
        --local probability = 1 - (match.diff / MAX_RATING_DIFFERENCE)
        if math.random() < probability*0.1 then
          Game.playMatch(player1, match.player)
          alreadyMatched[i] = true
          alreadyMatched[match.index] = true
          if Game.stat.totalGames > Game.gamesLeftToPlay then return end
          break -- Match found, exit the loop
        end
      end
    end
  end

end

function Game.determineAverages()
  local totalGames = 0
  local LB_ID = Game.LB_ID
  for rank, player in pairs(PlayerDB.LB[LB_ID]) do
    totalGames = totalGames + player.LB[LB_ID].wins + player.LB[LB_ID].losses
  end
  --local averagePerDayPerPlayer = totalGames / (Game.IRLdaysPassed * #PlayerDB.LB[LB_ID])
  Game.averagePerDayPerPlayer = Fit.averageGamesAt(Game.indexDay) --averagePerDayPerPlayer
  Game.gamesLeftToPlay = Game.averagePerDayPerPlayer * #PlayerDB.LB[LB_ID] * Game.IRLdaysRamaining
end

function Game.loadLatestResultsFolder(folder)
  local items = love.filesystem.getDirectoryItems(folder)
  if #items == 0 then print("no files in ",folder); return end

  table.sort(items, function(a, b)
      return utils.extractDate(a) > utils.extractDate(b)
  end)

  local latestFilePath = folder .. '/' .. items[1]

  if love.filesystem.getInfo(latestFilePath)["type"] == "file" then
      PlayerDB.loadOneLeaderboardFromData(latestFilePath)
  end
end

function Game.updateDataPointsFolder(folder)
  local items = love.filesystem.getDirectoryItems(folder)
  for i, fileName in ipairs(items) do
      local filePath = folder .. '/' .. fileName
      if love.filesystem.getInfo(filePath)["type"] == "file"  then
        PlayerDB.updateDataPoints(filePath)
      end
  end
end

function Game.evaluatePlayers()
  PlayerDB.determineHiddenVariables()
  PlayerDB.sortLB(Game.LB_ID)
end

function Game.movePlayersFromOtherLB(to_ID, from_ID)
  if #PlayerDB.LB[from_ID] == 0 then return end
  local overkill = 1.01 -- overestimate new players to account for some "newcomers" that are already in the target lobby
  local amount = Fit.newPlayersAt(os.date("*t",Game.simIRLDay).day) * overkill
  local newComer
  local moved = 0
  local topPercentFrom = 0.1  -- move part of the ladder
  local topPercentTo = 1

  for i = 1, amount do
    local index = math.floor(math.random(#PlayerDB.LB[from_ID] * topPercentFrom, #PlayerDB.LB[from_ID] * topPercentTo))

    newComer = PlayerDB.LB[from_ID][index]
    if not newComer.LB[to_ID] then         -- skip existing
      moved = moved + 1
      PlayerDB.resetPlayerInLB(newComer, to_ID)
      table.insert(PlayerDB.LB[to_ID],newComer)
    end
  end
  PlayerDB.sortLB(to_ID)
  Game.updateRemainingGames(moved)
end

function Game.addTopPlayers(to_ID, from_ID, topN)
  local newComer
  for i = 1, topN or 100 do
    newComer = PlayerDB.LB[from_ID][i]
    if not newComer.LB[to_ID] then         -- skip existing
      if newComer.online > math.random() then
        PlayerDB.resetPlayerInLB(newComer, to_ID)
        table.insert(PlayerDB.LB[to_ID],newComer)
      end
    end
  end
  PlayerDB.sortLB(to_ID)
end

function Game.printTop(topN, LB_ID, doSort, sortBy)
  if topN == 0 then topN = #PlayerDB.LB[LB_ID] end
  local LB_ID = LB_ID or Game.LB_ID
  if doSort then
    PlayerDB.sortLB(LB_ID, sortBy)
  end
  local topList = {}
  local line = {}
  local games = 0
  for i = 1, topN or 10 do
    local p = PlayerDB.LB[LB_ID][i]
    games = p.LB[LB_ID].wins + p.LB[LB_ID].losses
    line[1] = i
    line[2] = p.alias
    line[3] = "("..p.LB[LB_ID].highestrating..")"
    line[4] = "Played: ".. games
    line[5] = string.format("(%i%%)",100 * p.LB[LB_ID].wins / games)

    topList[i] = table.concat(line, "\t")
  end
  local result = table.concat(topList,"\n",1, (topN or 10) )
  return result
end

function Game.printCSV(topN, LB_ID, doSort, sortBy)
  local LB_ID = LB_ID or Game.LB_ID
  if (not topN or topN == 0) then topN = #PlayerDB.LB[LB_ID]-1 end
  if doSort then
    PlayerDB.sortLB(LB_ID, sortBy)
  end
  local topList = {[1]="rank, name, highest_elo, games, winrate"}
  local line = {}
  local games = 0
  for i = 2, topN+1 or 11 do
    local p = PlayerDB.LB[LB_ID][i]
    games = p.LB[LB_ID].wins + p.LB[LB_ID].losses
    line[1] = i
    line[2] = p.alias
    line[3] = p.LB[LB_ID].highestrating
    line[4] = games
    line[5] = p.LB[LB_ID].wins / games

    topList[i] = table.concat(line, ",")
  end
  local result = table.concat(topList,"\n",1, (topN or 10) )
  return result
end

function Game.updateRemainingGames(newPlayers)
  Game.gamesLeftToPlay = Game.gamesLeftToPlay + Game.averagePerDayPerPlayer * newPlayers
end

function Game.updateGameDay()
  local dayPercent = Game.IRLdaysRamaining * Game.stat.totalGames / Game.gamesLeftToPlay
  local day = Game.IRLdayStartAt + (dayPercent * 60 * 60 * 24)
  Game.simIRLDay = day
  return day
end

return Game
