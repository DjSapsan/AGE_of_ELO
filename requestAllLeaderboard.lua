local https = require "https"
local ltn12 = require "ltn12" -- Ensure you have this for the sink
local utils = require "utils"

local json = require('dkjson')

local BASE_URL = "https://aoe-api.worldsedgelink.com/community/leaderboard/getLeaderBoard2?title=age2&leaderboard_id=%d&start=%d"

local RAW_JSON_DATA = {leaderboardStats = {}, statGroups = {}}
local LEADERBOARD = {}

-- leaderboard ID:
-- 3 = 1v1 RM
-- 27 = RB EW
local LB_ID = 3

-- Utility function to make HTTPS GET requests
local function httpsGet(url)
	local response_body = {}
	local result, status = https.request{
			url = url,
			sink = ltn12.sink.table(response_body)
	}

	if not result then
			error("HTTP request failed: " .. tostring(status))
			return
	end

	local responseString = table.concat(response_body)

	return json.decode(responseString)

end

local saveToFile = function(_table, filename, folder)
	local time = os.date("%Y-%m-%d")
	local data = json.encode(_table)
	local file = io.open("./"..folder.."/"..filename.."_"..time..".json","w")
	if file then
		file:write(data)
	else
		error("file doesnt exist fucker boi")		-- TODO change to assert
	end
end

local mergeToData = function(newData)
	for k, v in pairs(newData.statGroups) do
		RAW_JSON_DATA.statGroups[v.id] = v
	end
	for k, v in pairs(newData.leaderboardStats) do
		RAW_JSON_DATA.leaderboardStats[v.statgroup_id] = v
	end
end

-- ID:
-- 3 = 1v1 RM
-- 27 = RB EW
local iterateWholeLeaderBoard = function (id)--, upTo)
	local requestURL1, requestURL2
	local newData1, newData2
	local start = 1
	while true do
		requestURL1 = string.format(BASE_URL, id, start)
		requestURL2 = string.format(BASE_URL, id, start+1)
		print("Requesting: ", requestURL1)
		print("Requesting: ", requestURL2)
		newData1 = httpsGet(requestURL1)
		newData2 = httpsGet(requestURL2)
		if newData1 and #newData1.statGroups == 0 then return end
		if newData2 and #newData2.statGroups == 0 then return end

		mergeToData(newData1)
		mergeToData(newData2)

		start = start + 200
	end

end

local fName = "LB_RM"
if LB_ID == 27 then fName = "LB_RB_EW" end
iterateWholeLeaderBoard(LB_ID)
saveToFile(RAW_JSON_DATA,fName,fName)