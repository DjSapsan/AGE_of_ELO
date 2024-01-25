local Player = require("Player")

local csv = require("lua-csv/lua/csv")

local PlayerDB = {}

-- main table indexed by player's rank
PlayerDB.table = {}

PlayerDB.stats = {}
PlayerDB.stats.mostGames = 0

-- players 
PlayerDB.addPlayer = function (player)
    PlayerDB.table[#PlayerDB.table+1] = player
end

PlayerDB.findPlayer = function (key, value)
    for k, v in pairs(PlayerDB.table) do
        if v[key] == value then
            return v
        end
    end
    return nil
end

PlayerDB.updateStats = function ()
    PlayerDB.stats.mostGames = 0
    for id, p in pairs(PlayerDB.table) do
        if p.games > PlayerDB.stats.mostGames then
            PlayerDB.stats.mostGames = p.games
        end
    end
end

--assumes the table is sorted by rank
PlayerDB.updatePlaces = function ()
    for i,player in ipairs(PlayerDB.table) do
      player.rank=i
    end
  end

PlayerDB.inactivatePlayer = function (player)
    for id, p in pairs(PlayerDB.table) do
        if p == player then
            player.online = 0
            return
        end
    end
end

PlayerDB.updateLeavers = function (chance)
    for id, player in pairs(PlayerDB.table) do
        if player.rating<500 and math.random()<chance then
            PlayerDB.inactivatePlayer(player)
        end
    end
end

PlayerDB.playerDeath = function (chance)
    for id, player in pairs(PlayerDB.table) do
        if math.random()<chance then
            PlayerDB.inactivatePlayer(player)
        end
    end
end

PlayerDB.overridePlayerValues = function ()
    local f = csv.open("manualAdjust.csv")
    if not f then print("Error: file not found"); return; end

    local skill, games, online
    for fields in f:lines() do
        local player = PlayerDB.findPlayer("name", fields[1])
        if player then
            skill = tonumber(fields[2])
            games = tonumber(fields[3])
            online = tonumber(fields[4])
            if skill and skill > 0 then player.skill = skill end
            if games and games > 0 then player.games = games end
            if online and online > 0 then player.online = player.online*online end
            print("Overriding " .. player.name .. " skill to " .. player.skill .. " games to " .. player.games .. " online to " .. player.online)
        end
    end
    f:close()
end

-- determines player's skill and online frequency based on player's history 
PlayerDB.determineHiddenVariables = function ()
    PlayerDB.updateStats()
    for id, player in pairs(PlayerDB.table) do
        local games = player.games
        local wins = player.wins
        local winrate = wins / games
        player.skill  = (player.rating + (0.5 - winrate)*10 + player.games/1000)/2
        player.online = player.games / PlayerDB.stats.mostGames
    end
end

return PlayerDB