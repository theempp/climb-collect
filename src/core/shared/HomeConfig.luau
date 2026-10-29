-- Expedition home tuning. Timer durations remain in CoreConfig for migration only.
local H = {
	lampCost = 1500,
	stoneProgress = { Common = 4, Rare = 9, Legendary = 18 },
	nestCount = 2,
	baseSpaces = 3,
	maxUpgrade = 3,
	upgradeCosts = { 60, 180, 420 },
	progressEfficiency = { 1, 1.25, 1.5, 2 },
	offlineCap = 8 * 60 * 60,
	stationRange = 20,
	roomSpacing = 140,
	roomY = 5000,
	petCooldown = 3,
}
return H
