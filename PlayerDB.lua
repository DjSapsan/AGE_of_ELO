local json = require("dkjson")
local utils = require("utils")

local PlayerDB = {}

-- table containing all players
-- index = player id
PlayerDB.table = {}

-- table with leaderboards, should be sorted by player's rank
--RM = 3, TG = 4, EW = 13, RB_EW = 27        TG_EW = 14, DM = 1, TG_DM = 2
PlayerDB.LB = {[3] = {}, [4] = {}, [13] = {}, [27] = {}}
PlayerDB.activeLB = 3
PlayerDB.stats = {}
PlayerDB.stats.mostGames = 0

-- data points across IRL data loading
-- ONLY FOR the active ladder
-- 0 = original
-- 1++ = changes to extrapolate
PlayerDB.dataPoints = {}

PlayerDB.addPlayer = function (player)
    PlayerDB.table[player.id] = player  -- overwrites the players each time
end

PlayerDB.resetPlayerInLB = function (player, LB_ID)
    player.LB[LB_ID] = {}
    player.LB[LB_ID].ranktotal = 0
    player.LB[LB_ID].regionranktotal = -1
    player.LB[LB_ID].drops = 0
    player.LB[LB_ID].regionrank = -1
    player.LB[LB_ID].rating = 1000
    player.LB[LB_ID].rank = -1
    player.LB[LB_ID].highestrank = -1
    player.LB[LB_ID].streak = 0
    player.LB[LB_ID].ranklevel = -1
    player.LB[LB_ID].highestranklevel = -1
    player.LB[LB_ID].highestrating = -1

    local statgroup_id = -1
    if player.LB[3] then statgroup_id = player.LB[3].statgroup_id end
    player.LB[LB_ID].statgroup_id = statgroup_id

    player.LB[LB_ID].losses = 0
    player.LB[LB_ID].wins = 0
    player.LB[LB_ID].lastmatchdate = -1
    player.LB[LB_ID].disputes = 0
    player.LB[LB_ID].leaderboard_id = LB_ID
end

-- add a player into DB from combined json leaderboard data
PlayerDB.addPlayerFromData = function (item)
    local p
    if not PlayerDB.table[item.profile.profile_id] then    -- if the player doesn't exists then import info from data
        p = {
            ["id"] = item.profile.profile_id,
            ["alias"] = item.profile.alias,    -- in game name
            ["country"] = item.profile.country,
            ["name"] = item.profile.name,      -- steam id
            ["personal_statgroup_id"] = item.profile.personal_statgroup_id,
            ["leaderboardregion_id"] = item.profile.leaderboardregion_id,
            ["LB"] = {}
        }

    else
        p = PlayerDB.table[item.profile.profile_id]    -- if the player already exists then merge
        -- TODO check changes
    end

    local id, lb = next(item.LB)
    if not p.LB[id] then
        p.LB[id] = lb
        table.insert(PlayerDB.LB[id], p)
    end

    PlayerDB.addPlayer(p)

    return p
end

PlayerDB.loadOneLeaderboardFromData = function(dataFilePath)
    local jsonText, e = love.filesystem.read(dataFilePath); if not jsonText then error(e) end
    local data = json.decode(jsonText); if not data then error("wrong json in ".. dataFilePath) end
    local LB_ID = data.leaderboardStats[next(data.leaderboardStats)].leaderboard_id

    local pointGames = 0

    for id, profile in pairs(data.statGroups) do
        local item = {}
        item.profile = profile.members[1]
        item.LB = {}
        item.LB[LB_ID] = data.leaderboardStats[id]
        PlayerDB.addPlayerFromData(item)

        pointGames = pointGames + item.LB[LB_ID].wins + item.LB[LB_ID].losses
    end

    if PlayerDB.activeLB == LB_ID then
        local pointTime = utils.extractDate(dataFilePath)
        local pointPlayers = #data.statGroups
        local dataStats = {["games"] = pointGames, ["players"] = pointPlayers, ["time"] = pointTime, ["LB_ID"] = LB_ID};
        PlayerDB.dataPoints[#PlayerDB.dataPoints] = dataStats
    end

end

local getNumberOfGames = function(p, LB_ID)
    local games = 0
    if LB_ID then
        games = p.LB[LB_ID].losses + p.LB[LB_ID].wins
    elseif p.LB[3] then
        games = p.LB[3].losses + p.LB[3].wins
    else
        games = p.LB[27].losses + p.LB[27].wins -- CAUTION! some player may not have RM or RB EW rank
    end

    return games
end
PlayerDB.getNumberOfGames = getNumberOfGames

PlayerDB.findPlayer = function (key, value)
    for k, v in pairs(PlayerDB.table) do
        if v[key] == value then
            return v
        end
    end
    return nil
end

PlayerDB.findIDinLB = function (ID, LB)
    for k, v in pairs(PlayerDB.LB[LB]) do
        if v.id == ID then
            return v
        end
    end
    return nil
end

-- uses RM LB
PlayerDB.updateStats = function ()
    PlayerDB.stats.mostGames = {[3] = 0, [27] = 0}         -- TODO dynamic instead of hardcoded
    local games = 0
    local mostGames = 0

    for id, p in pairs(PlayerDB.LB[3]) do
        games = p.LB[3].losses + p.LB[3].wins
        if games > mostGames then mostGames = games end
    end
    PlayerDB.stats.mostGames[3] = mostGames

    mostGames = 0
    for id, p in pairs(PlayerDB.LB[27]) do
        games = p.LB[27].losses + p.LB[27].wins
        if games > mostGames then mostGames = games end
    end
    PlayerDB.stats.mostGames[27] = mostGames
end

--assumes the table is sorted by rank
PlayerDB.updateRanksFromLB = function (LB_ID)
    for i,player in ipairs(PlayerDB.LB[LB_ID]) do
        player.LB[LB_ID].rank=i
    end
end

PlayerDB.inactivatePlayer = function (player)
    PlayerDB.table[player.id].online = 0
end

PlayerDB.updateLeavers = function (chance, LB_ID)
    for rank, player in pairs(PlayerDB.LB[LB_ID]) do
        if player.LB[LB_ID].rating<1000 and math.random()<chance*player.LB[LB_ID].rank then     -- losers more likely to leave
            PlayerDB.table[player.id].online = 0
        end
    end
end

PlayerDB.playerDeath = function (chance,LB_ID)
    for rank, player in pairs(PlayerDB.LB[LB_ID]) do
        if math.random()<chance then
            PlayerDB.table[player.id].online = 0
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


local ELO_FACTOR = 200
-- determines player's skill and online frequency based on player's history
--
PlayerDB.determineHiddenVariables = function ()
    PlayerDB.updateStats()

    local LB_ID_main = 3
    local LB_ID_active = 27
    local factor   -- players in RB ladder are more active

    for id, player in pairs(PlayerDB.table) do
        factor = 1

        LB_ID_main = 3
        LB_ID_active = 27
        if not player.LB[3] then LB_ID_main = 27 end     -- CAUTION! some player may not have RM or RB EW rank
        if not player.LB[27] then LB_ID_active = 3; factor = 0.1 end     -- CAUTION! some player may not have RM or RB EW rank

        local winrateMain = player.LB[LB_ID_main].wins / getNumberOfGames(player, LB_ID_main)
        player.skill  = player.LB[LB_ID_main].highestrating + ELO_FACTOR * math.log(winrateMain/(1-winrateMain),10)

        player.online = factor * (getNumberOfGames(player, LB_ID_active) / PlayerDB.stats.mostGames[LB_ID_active])
    end
end

PlayerDB.sortLB = function(LB_ID, sortBy)
    local sortBy = sortBy or "rating"
    if LB_ID then
        table.sort(PlayerDB.LB[LB_ID], function(p1,p2) return p1.LB[LB_ID][sortBy] > p2.LB[LB_ID][sortBy] end)
    else
        for id, lb in pairs(PlayerDB.LB) do
            table.sort(lb, function(p1,p2) return p1.LB[id].rating > p2.LB[id].rating end)
        end
    end
end

-- Player.shortInfo = function (p)
--     -- form string using string formatting
--     local str = string.format("Name = %-20s | rating = %5d | games = %5d | win%% = %5.2f%% | rank = %6d | skill = %4d", p.name, p.rating, p.games, p.wins/p.games*100, p.rank, p.skill)
--     return str
-- end

return PlayerDB