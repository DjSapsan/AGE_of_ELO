local json = require("dkjson")
local Player = {}

-- @param argument: string, table or Player object
-- @param rank: number
-- @param rating: number
-- @param steam_id: string
-- @param icon: string
-- @param name: string
-- @param clan: string
-- @param country: string
-- @param previous_rating: number
-- @param highest_rating: number
-- @param streak: number
-- @param lowest_streak: number
-- @param highest_streak: number
-- @param games: number
-- @param wins: number
-- @param losses: number
-- @param drops: number
-- @param last_match_time: number
-- @return Player object as a table
Player.new = function (argument, rank, rating, steam_id,icon,name,clan,country,previous_rating,highest_rating,streak,lowest_streak,highest_streak,games,wins,losses,drops,last_match_time)
    local p
    if rank then
        p = {
            ["profile_id"] = argument,
            ["rank"] = rank or 0,
            ["rating"] = rating or 1000,
            ["steam_id"] = steam_id,
            ["icon"] = icon,
            ["name"] = name or ("unknown-"..argument),
            ["clan"] = clan,
            ["country"] = country,
            ["previous_rating"] = previous_rating or 1000,
            ["highest_rating"] = highest_rating or 1000,
            ["streak"] = streak or 0,
            ["lowest_streak"] = lowest_streak or 0,
            ["highest_streak"] = highest_streak or 0,
            ["games"] = games or (wins + losses),
            ["wins"] = wins or 0,
            ["losses"] = losses or 0,
            ["drops"] = drops or 0,
            ["last_match_time"] = last_match_time or 0
        }
  
    elseif type(argument) == "string" then
        p = json.decode(argument)
    elseif type(argument) == "table" then
        p = argument
    else
        print("Error: invalid arguments")
        return nil
    end
    return p
end

Player.shortInfo = function (p)
    -- form string using string formatting
    local str = string.format("Name = %-20s | rating = %5d | games = %5d | win%% = %5.2f%% | rank = %6d | skill = %4d", p.name, p.rating, p.games, p.wins/p.games*100, p.rank, p.skill)
    return str
end

--local test = Player.new(testStr)
--print(test)

return Player