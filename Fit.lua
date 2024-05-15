-- this is updated manually from data points

Fit = {}

Fit.params = {
	winProbFactor = 0.9,
	leaversFactor = 1000,
}

local E = math.exp(1)

local newPlayersFunc = function (d)
	--return 890 * d ^ 0.396
	--return 1254 * math.log(d, E) - 576
	return 1780 * math.log(d+2, E) - 2120
end

-- day = since start of the simulation (not real day)
Fit.newPlayersAt = function (day)
	return math.min(math.max(newPlayersFunc(day) - newPlayersFunc(day-1), 1), 1000)
end

-- DONT USE - WRONG
-- day = since start of the simulation (not real day)
Fit.averageGamesAt = function (day)
	--return day * 2.32 + 15.7
	return 2
end

return Fit