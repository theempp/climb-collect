-- Expedition traversal tuning. Stamina is the sole survival resource.
return {
	version = 1,
	launchRoutes = { Shepherd = true, Waterfall = true, Practice = true, Tutorial = true },
	stepSeconds = 0.46, assistedSeconds = 0.28, moveSeconds = 0.28,
	stepCost = 2.5, mistakeCost = 1, stableRegen = 1.2, groundRegen = 13,
	iceCost = 0.75, ropeCost = 0.45, hangingRegen = 13, recoverAt = 24,
	entryRange = 7, topRange = 9, holdTolerance = 5, hangDrop = 5,
	ropeSeconds = 180, ropeLimit = 2, ropeCooldown = 15,
	jumpWindow = 1.4, flightSpeed = 15, flightSink = 11, flightMaxSeconds = 360,
	fallDrop = 24, flightLaunchRadius = 32, flightLandingRadius = 65,
}
