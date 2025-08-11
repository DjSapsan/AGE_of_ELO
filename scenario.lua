local Scenario = {}

local parameters = require("parameters")
local PlayerDB = require("PlayerDB")
local Fit = require("Fit")
local CSV = require("ftcsv")

function Scenario.set(game)
  local scenarioStartDay = os.time({year = 2024, month = 5, day = 3})

  game.IRLdayStartAt = scenarioStartDay
  game.IRLdaysRamaining = os.difftime(os.time({year = 2024, month = 7, day = 28}), scenarioStartDay) / (60 * 60 * 24)
  game.IRLdaysPassed = os.difftime(scenarioStartDay, os.time({year = 2024, month = 5, day = 1})) / (60 * 60 * 24)
  game.simIRLDay = 0
  game.indexDay = 0
  game.lastDay = 0
  game.moreActivityLastDays = 0.9
  game.moreActivityDone = false

  Scenario.determineAverages(game)
end

function Scenario.updateStage(game)
  if game.stat.totalGames > game.gamesLeftToPlay then
    game.ended = true
    game.paused = true
    game.savePredictions()
  end

  if not game.moreActivityDone and game.stat.totalGames / game.gamesLeftToPlay > game.moreActivityLastDays then
    Scenario.changeActivity(game)
    game.moreActivityDone = true
  end

  Scenario.checkNextDay(game)
end

function Scenario.changeActivity(game)
  local csvData = CSV.parse("grinders.csv", '\t')
  local LB_ID = 27 -- game.LB_ID
  local playerOnlineX, p
  for _, row in ipairs(csvData) do
    playerOnlineX = tonumber(row.onlineX)
    p = PlayerDB.table[tonumber(row.id)]
    p.online = p.online * playerOnlineX
    p.skill = p.skill * 1.01
  end
end

function Scenario.checkNextDay(game)
  local dayPassed = false
  local tDate = os.date("*t", Scenario.updateGameDay(game))
  local bigDay = tDate.year * 10000 * tDate.month * 100 + tDate.day

  if game.lastDay == 0 then
    game.lastDay = bigDay
    return
  end

  if bigDay > game.lastDay then
    dayPassed = true
    game.lastDay = bigDay
    game.indexDay = game.indexDay + 1
  end

  if dayPassed and parameters.playerDynamics then
    PlayerDB.updateLeavers(1 / Fit.params.leaversFactor, game.LB_ID)
    Scenario.movePlayersFromOtherLB(game, 27, 3)
  end
end

function Scenario.determineAverages(game)
  local totalGames = 0
  local LB_ID = game.LB_ID
  for _, player in pairs(PlayerDB.LB[LB_ID]) do
    totalGames = totalGames + player.LB[LB_ID].wins + player.LB[LB_ID].losses
  end
  game.averagePerDayPerPlayer = Fit.averageGamesAt(game.indexDay)
  game.gamesLeftToPlay = game.averagePerDayPerPlayer * #PlayerDB.LB[LB_ID] * game.IRLdaysRamaining
end

function Scenario.movePlayersFromOtherLB(game, to_ID, from_ID)
  if #PlayerDB.LB[from_ID] == 0 then return end
  local overkill = 1.01
  local amount = Fit.newPlayersAt(os.date("*t", game.simIRLDay).day) * overkill
  local newComer
  local moved = 0
  local topPercentFrom = 0.1
  local topPercentTo = 1

  for i = 1, amount do
    local index = math.floor(math.random(#PlayerDB.LB[from_ID] * topPercentFrom, #PlayerDB.LB[from_ID] * topPercentTo))
    newComer = PlayerDB.LB[from_ID][index]
    if not newComer.LB[to_ID] then
      moved = moved + 1
      PlayerDB.resetPlayerInLB(newComer, to_ID)
      table.insert(PlayerDB.LB[to_ID], newComer)
    end
  end
  PlayerDB.sortLB(to_ID)
  Scenario.updateRemainingGames(game, moved)
end

function Scenario.updateRemainingGames(game, newPlayers)
  game.gamesLeftToPlay = game.gamesLeftToPlay + game.averagePerDayPerPlayer * newPlayers
end

function Scenario.updateGameDay(game)
  local dayPercent = game.IRLdaysRamaining * game.stat.totalGames / game.gamesLeftToPlay
  local day = game.IRLdayStartAt + (dayPercent * 60 * 60 * 24)
  game.simIRLDay = day
  return day
end

return Scenario
