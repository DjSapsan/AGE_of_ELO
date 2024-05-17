-- this is updated manually from data points

Fit = {}

Fit.params = {
	winProbFactor = 0.9,
	leaversFactor = 1000,
}

local E = math.exp(1)

local newPlayersFunc = function (d)
	return 1734 * math.log(d+2, E) - 2030
end

-- new players at the specified IRL day
Fit.newPlayersAt = function (day)
	return math.min(math.max(newPlayersFunc(day) - newPlayersFunc(day-1), 1), 1000)
end

-- WRONG, but linearly close to 2 ... 2.5
Fit.averageGamesAt = function (day)
	--return day * 2.32 + 15.7
	return 2
end

return Fit