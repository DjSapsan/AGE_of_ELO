--[[
  Short statistics over a leaderboard snapshot.

  Run standalone:
    luajit stats.lua            -- latest LB_RM snapshot (leaderboard_id = 3, the default)
    luajit stats.lua 27         -- latest LB_RB_EW snapshot (leaderboard_id = 27)
    luajit stats.lua LB_RM      -- latest snapshot in the given folder
    luajit stats.lua LB_RM/LB_RM_2025-08-21.json   -- a specific snapshot file

  Prints a report to the terminal AND saves it as a .txt into the stats/ folder.
]]

local utils = require("utils")
local PlayerDB = require("PlayerDB")

-- leaderboard id -> data folder (see requestAllLeaderboard.lua / PlayerDB.lua)
-- RM = 3, RB_EW = 27
local LB_FOLDER = {[3] = "LB_RM", [27] = "LB_RB_EW"}

-- list .json files in a folder
local function listSnapshots(folder)
  local files = {}
  local p = io.popen('ls -1 "' .. folder .. '" 2>/dev/null')
  if p then
    for name in p:lines() do
      if name:match("%.json$") then files[#files + 1] = name end
    end
    p:close()
  end
  return files
end

-- newest snapshot in a folder, sorted by date in the filename
local function findLatestSnapshot(folder)
  local items = listSnapshots(folder)
  if #items == 0 then error("no snapshots in folder: " .. folder) end
  table.sort(items, function(a, b)
    return utils.extractDate(a) > utils.extractDate(b)
  end)
  return folder .. "/" .. items[1]
end

-- the leaderboard id that actually got filled after loading
local function activeLB_ID()
  for id, lb in pairs(PlayerDB.LB) do
    if #lb > 0 then return id end
  end
end

-- which metrics to report. Add a new line here to add a stat (room for future additions).
-- get(p, LB_ID) returns the metric value for one player.
local metrics = {
  {label = "Games",   unit = "",  decimals = 0, get = function(p, id) return PlayerDB.getNumberOfGames(p, id) end},
  {label = "Winrate", unit = "%", decimals = 2, get = function(p, id)
    local g = PlayerDB.getNumberOfGames(p, id)
    return g > 0 and 100 * p.LB[id].wins / g or 0
  end},
  {label = "Elo",     unit = "",  decimals = 0, get = function(p, id) return p.LB[id].rating end},
  {label = "Drops",   unit = "",  decimals = 0, get = function(p, id) return p.LB[id].drops end},
  {label = "Streak",  unit = "",  decimals = 0, get = function(p, id) return p.LB[id].streak end},
}

-- min, max, arithmetic mean and (population) standard deviation of a list
local function computeStats(values)
  local n = #values
  local min, max, sum = math.huge, -math.huge, 0
  for _, v in ipairs(values) do
    if v < min then min = v end
    if v > max then max = v end
    sum = sum + v
  end
  local mean = sum / n
  local sq = 0
  for _, v in ipairs(values) do
    local d = v - mean
    sq = sq + d * d
  end
  return {n = n, min = min, max = max, sum = sum, mean = mean, std = math.sqrt(sq / n)}
end

local function fmtMinMax(v, decimals) return string.format("%." .. decimals .. "f", v) end
local function fmtMeanStd(v)          return string.format("%.2f", v) end

-- ----------------------------------------------------------------------------
-- pick the snapshot
-- ----------------------------------------------------------------------------

local input = arg and arg[1]
local path, LB_ID

if not input then
  LB_ID = 3
  path = findLatestSnapshot(LB_FOLDER[LB_ID])
elseif tonumber(input) then
  LB_ID = math.floor(tonumber(input))
  local folder = LB_FOLDER[LB_ID]
  if not folder then error("unknown leaderboard id " .. LB_ID .. " (known: 3 = LB_RM, 27 = LB_RB_EW)") end
  path = findLatestSnapshot(folder)
elseif input:match("%.json$") then
  path = input
else
  path = findLatestSnapshot(input)
end

PlayerDB.loadOneLeaderboardFromData(path)
LB_ID = LB_ID or activeLB_ID()
if not LB_ID then error("no players loaded from " .. path) end

local players = PlayerDB.LB[LB_ID]

-- collect values and crunch the numbers
for _, m in ipairs(metrics) do
  m.values = {}
  for _, p in pairs(players) do
    m.values[#m.values + 1] = m.get(p, LB_ID)
  end
  m.stats = computeStats(m.values)
  m.title = m.label .. (m.unit ~= "" and " (" .. m.unit .. ")" or "")
end

-- build the report
local out = {}
local function line(s) out[#out + 1] = s or "" end

line("AGE of ELO - leaderboard snapshot statistics")
line("Snapshot : " .. path .. "  (leaderboard_id = " .. LB_ID .. ")")
line("Generated: " .. os.date("%Y-%m-%d %H:%M:%S"))
line()

-- 1) number of players and the total Elo across all of them
local eloSum = 0
for _, m in ipairs(metrics) do
  if m.label == "Elo" then eloSum = m.stats.sum end
end
line("Players  : " .. #players .. "    Total Elo: " .. string.format("%.0f", eloSum))
line()

-- 2) min / max / mean
line("Min / Max / Average")
line(string.format("%-14s| %12s | %12s | %12s", "Metric", "min", "max", "average"))
line(string.rep("-", 14) .. "+" .. string.rep("-", 14) .. "+" .. string.rep("-", 14) .. "+" .. string.rep("-", 13))
for _, m in ipairs(metrics) do
  local s = m.stats
  line(string.format("%-14s| %12s | %12s | %12s",
    m.title, fmtMinMax(s.min, m.decimals), fmtMinMax(s.max, m.decimals), fmtMeanStd(s.mean)))
end
line()

-- 3) standard distribution (mean +/- std), readable + Desmos-ready normaldist(mean, std)
line("Standard distribution  (readable, then Desmos formula)")
for _, m in ipairs(metrics) do
  local s = m.stats
  line(string.format("  %-12s: average = %s, std = %s", m.title, fmtMeanStd(s.mean), fmtMeanStd(s.std)))
  line(string.format("  %-12s  Desmos : normaldist(%s,%s)", "", fmtMeanStd(s.mean), fmtMeanStd(s.std)))
end
line()

local report = table.concat(out, "\n")

-- print + save
print(report)

os.execute('mkdir -p stats')
local base = path:match("([^/\\]+)%.json$") or ("LB_" .. LB_ID)
local outPath = "stats/stats_" .. base .. ".txt"
local file = io.open(outPath, "w")
if file then
  file:write(report)
  file:close()
  print("Saved report to " .. outPath)
else
  print("Error: could not write " .. outPath)
end
