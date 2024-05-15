local Scenario = {}

Scenario.set = function (game)

	local scenarioStartDay = os.time({year = 2024, month = 5, day = 3})

	game.IRLdayStartAt = scenarioStartDay

	-- set the last day IRL before where the simulation ends and restarts
	game.IRLdaysRamaining = os.difftime(os.time({year = 2024, month = 7, day = 28}), scenarioStartDay) / (60 * 60 * 24) --until 28th of july

	-- IRL days passed since the specific date
	game.IRLdaysPassed = os.difftime(scenarioStartDay, os.time({year = 2024, month = 5, day = 1})) / (60 * 60 * 24)

	game.determineAverages()
end

return Scenario
