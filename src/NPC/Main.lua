-- dogo8me2

local main = {}

--// SERVICES
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DebrisService = game:GetService("Debris")

--// CONSTANTS
local character = script.Parent.Parent
local config = require(script.Parent.Configuration)
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local nodesFolder = workspace.Nodes

--// TYPES
type BehaviorState = "SEARCHING" | "PATROLLING" | "CHASING"

--// VARIABLES
local patrolAlgorithm
local searchAlgorithm
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.FilterDescendantsInstances = {character}
local floorPosition

--// MODULE CONFIGURATION
local ConfigFieldOfView = config.FieldOfView
local ConfigMaxDistance = config.MaxDistance

main.humanoidRootPart = humanoidRootPart

-- returns the distance between 2 vectors
function main.getDistance(vectorA: Vector3, vectorB: Vector3)
	return (vectorA - vectorB).Magnitude
end

-- gets the position of the floor relative to the character
function main.getFloorPosition(characterModel: Model?)
	local character = characterModel or character
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	assert(humanoidRootPart and humanoidRootPart:IsA("BasePart"))

	return workspace:Raycast(humanoidRootPart.Position, Vector3.new(0, -10, 0)).Position
end

floorPosition = main.getFloorPosition(character) - humanoidRootPart.Position

-- get nodes in a sort of 2d circle around the enemy
function main.getNodesInRadius(referencePos: Vector3, radius: number, includeSearched: boolean?): {BasePart}
	local nodesInRadius = {}
	for _, node: BasePart in nodesFolder:GetChildren() do
		local distance = (node.Position - referencePos).Magnitude
		if distance <= radius then
			if not includeSearched and node:GetAttribute("IsSearched") ~= true then table.insert(nodesInRadius, node) else table.insert(nodesInRadius, node) end
		end
	end
	return nodesInRadius
end

function main.evaluateSoundLoss(positionOne: Vector3, positionTwo: Vector3, loudness: number, lossPerWall: number): boolean
	local direction = (positionOne - positionTwo)
	local wallCount = 0
	
	local players = game.Players:GetPlayers()
	local exclusions = {}
	
	for _, player in players do
		if not player.Character then return end
		table.insert(exclusions, player.Character)
	end
	
	local rayCastParams = RaycastParams.new()
	rayCastParams.FilterType = Enum.RaycastFilterType.Exclude
	rayCastParams.FilterDescendantsInstances = exclusions
	
	local rayCast
	repeat 
		rayCast = workspace:Raycast(positionOne, direction) if rayCast.Instance.Parent ~= character then table.insert(exclusions, rayCast.Instance) wallCount += 1 end
	until
		rayCast.Instance.Parent == character
	
	return loudness - (lossPerWall * wallCount) > 0
end

-- gets a random node within the node folder
function main.getRandomNode(): BasePart
	local nodes: {BasePart} = nodesFolder:GetChildren()
	return nodes[math.random(1, #nodes)]
end

-- checks if every single node is already searched
function main.areAllNodesSearched(nodeList: {BasePart}?): boolean
	for _, node in nodeList or nodesFolder:GetChildren() do
		if not node:GetAttribute("IsSearched") then
			return false
		end
	end
	return true
end

-- get the closet node to the enemy
function main.getClosestNode(humanoidRootPart: BasePart, includeSearched: boolean?, nodeList: {BasePart}?): {}
	local nodes = nodeList or nodesFolder:GetChildren()
	local distances = {}
	for _, node in nodes do
		local distance = (node.Position - humanoidRootPart.Position).Magnitude
		if not includeSearched and node:GetAttribute("IsSearched") ~= true then distances[node] = distance end
	end
	local smallestDistance, smallestNode
	for node, distance in distances do
		if not smallestDistance or distance < smallestDistance then
			smallestDistance, smallestNode = distance, node
		end
	end
	return smallestNode
end

-- get the farthest node to the enemy
function main.getFarthestNode(humanoidRootPart: BasePart, includeSearched: boolean?, nodeList: {BasePart}?): {}
	local nodes = nodeList or nodesFolder:GetChildren()
	local distances = {}
	for _, node in nodes do
		local distance = (node.Position - humanoidRootPart.Position).Magnitude
		if not includeSearched and node:GetAttribute("IsSearched") ~= true then distances[node] = distance end
	end
	local largestDistance, largestNode
	for node, distance in distances do
		if not largestDistance or distance > largestDistance then
			largestDistance, largestNode = distance, node
		end
	end
	return largestNode
end

function main.createTempPart(position: Vector3, lifespan: number, color: BrickColor)
	local part = Instance.new("Part", workspace.Waypoints)
	part.Size = Vector3.new(0.5, 0.5, 0.5)
	part.Material = Enum.Material.Neon
	part.BrickColor = color
	part.Anchored = true
	part.CanCollide = false
	part.Position = position
	DebrisService:AddItem(part, lifespan)
end

function main.visualizeRay(origin: Vector3, direction: Vector3)
	local Raycast = Instance.new("Part")
	Raycast.CFrame = CFrame.new(origin + direction/2, origin + direction)
	Raycast.Anchored = true
	Raycast.CanCollide = false
	Raycast.CanQuery = false
	Raycast.Name = "Raycast"
	Raycast.Size = Vector3.new(0.075, 0.075, direction.Magnitude)
	Raycast.Parent = workspace
	Raycast.Material = Enum.Material.Neon
	Raycast.BrickColor = BrickColor.new("New Yeller")

	game.Debris:AddItem(Raycast, 0.1)
end

function main.compareDistanceFromCharacter(position: Vector3, maxDistance: number): boolean
	return (position - (floorPosition + humanoidRootPart.Position)).Magnitude < maxDistance
end

-- checks 4 parts of the body and returns how many parts are visible by the enemy
function main.isCharacterInLineOfSight(startingPart: BasePart, targetModel: Model, fieldOfView: number, maxDistance: number): number
	local fieldOfView = math.cos(math.rad(fieldOfView))
	local rayCastParams = RaycastParams.new()
	rayCastParams.FilterType = Enum.RaycastFilterType.Exclude
	rayCastParams.FilterDescendantsInstances = {startingPart.Parent}


	local limbs = {"Left Arm", "Right Arm", "Torso", "Head"}
	local visible = 0

	for _, limbName in limbs do
		local limb = targetModel:FindFirstChild(limbName)
		if limb then
			local direction = (limb.Position - startingPart.Position).Unit
			local lookVector = character:FindFirstChild("Head").CFrame.LookVector
			local dot = lookVector:Dot(direction)
			local rayResult = workspace:Raycast(startingPart.Position, direction * maxDistance, rayCastParams)
			if rayResult and rayResult.Instance and rayResult.Instance:IsDescendantOf(targetModel) and dot > fieldOfView then
				visible += 1
			end
		end
	end

	return visible > 0 and visible or false
end

-- basic line of sight raycast for nodes
function main.isInLineOfSight(startingPart: Vector3, targetPart: BasePart): boolean
	local rayCastParams = RaycastParams.new()
	local direction = (targetPart.Position + Vector3.new(0, 2, 0) - startingPart)
	local distance = direction.Magnitude
	local RayCast = workspace:Raycast(startingPart, direction, rayCastParams)
	if RayCast and RayCast.Instance then
		return RayCast.Instance == targetPart
	end
end

function main.isInFOV(targetPart: BasePart, fieldOfView: number, startingPart: Part?): boolean
	local fieldOfView = math.cos(math.rad(fieldOfView / 2))
	local head = startingPart or character:FindFirstChild("Head")
	local direction = (targetPart.Position - head.Position).Unit
	local lookVector = head.CFrame.LookVector
	local dot = lookVector:Dot(direction)

	return dot >= fieldOfView
end

function main.isInLineOfSightFOV(targetPart: BasePart): boolean
	local rayCastParams = RaycastParams.new()
	rayCastParams.FilterType = Enum.RaycastFilterType.Exclude
	rayCastParams.FilterDescendantsInstances = {character}
	local head = character:FindFirstChild("Head")
	local direction = (targetPart.Position - head.Position).Unit
	local rayResult = workspace:Raycast(head.Position, direction * ConfigMaxDistance, rayCastParams)
	if rayResult then
		if rayResult.Instance then
			if rayResult.Instance == targetPart then
				if main.isInFOV(targetPart, ConfigFieldOfView) then
					main.visualizeRay(head.Position, direction * 1000)
					return true
				end
			end
		end
	end
end

-- stops the script until a vector3 is in range of another vector3
function main.yieldUntilInRange(part: BasePart, targetVector3: Vector3, radius: number)
	while (part.Position - targetVector3).Magnitude >= radius do
		RunService.Heartbeat:Wait()
	end
end

-- calls a function when a part enters a raduis of a vector3
function main.callbackOnEnterRange(part: BasePart, targetVector3: Vector3, radius: number, callback: () -> nil)
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if (part.Position - targetVector3).Magnitude < radius then
			if main.isInLineOfSight(targetVector3, part) then
				callback()
				connection:Disconnect()
			end
		end
	end)
end

-- initiate first-time spawning for an enemy
function main.spawnEnemy(spawnNode: BasePart?)
	if not spawnNode then spawnNode = main.getRandomNode() end
	-- TODO: finish this
end

-- teleports the enemy to any node inside the map
function main.teleportEnemy(teleportNode: BasePart?)
	if not teleportNode then teleportNode = main.getRandomNode() end
	character:PivotTo(CFrame.new(Vector3.new(teleportNode.Position.X, teleportNode.Position.Y + character.Size.Y / 2, teleportNode.Position.Z)))
end

-- paths to a node via pathfindingservice
function main.pathToNode(nodePos: Vector3, callback: (Enum.PathStatus) -> nil, range: number)
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")

	local path = PathfindingService:CreatePath({
		AgentRadius = 3,
		AgentHeight = 5,
		AgentCanJump = true,
	})

	local pathFinished = false
	path:ComputeAsync(humanoidRootPart.Position, nodePos)

	for _, waypointPart: BasePart in workspace.Waypoints:GetChildren() do
		waypointPart:Destroy()
	end
	for _, waypoint: PathWaypoint in path:GetWaypoints() do
		local part = Instance.new("Part", workspace.Waypoints)
		part.Size = Vector3.new(0.5, 0.5, 0.5)
		part.Material = Enum.Material.Neon
		part.BrickColor = BrickColor.new("Institutional white")
		part.Anchored = true
		part.CanCollide = false
		part.Position = waypoint.Position
	end

	if range then
		main.callbackOnEnterRange(humanoidRootPart, nodePos, range, function()
			pathFinished = true
			if callback then
				callback(path.Status)
			end
		end)
	end

	path.Blocked:Connect(function(blockedWaypointIndex)
		if not pathFinished then
			path:ComputeAsync(humanoidRootPart.Position, nodePos)
			if path.Status == Enum.PathStatus.Success then
				local newWaypoints = path:GetWaypoints()
				if #newWaypoints > 0 then
					humanoid:MoveTo(newWaypoints[1].Position)
				end
			else
				if callback then
					callback(Enum.PathStatus.NoPath)
				end
			end
		end
	end)

	for _, waypoint: PathWaypoint in path:GetWaypoints() do
		if not pathFinished then
			while not main.compareDistanceFromCharacter(waypoint.Position, 4) do
				humanoid:MoveTo(waypoint.Position)
				task.wait() 
			end
		end
	end
	if callback then
		callback(path.Status)
	end
end

-- searches for player while actively pathing
function main.searchForPlayer(callback: (Player) -> ())
	local isChasing = false
	while not isChasing do
		task.wait(0.5)
		for _, player in Players:GetPlayers() do
			local detectionQuery = main.isCharacterInLineOfSight(character.Head, player.Character, ConfigFieldOfView, ConfigMaxDistance)
			if detectionQuery then
				local distance = main.getDistance(humanoidRootPart.Position, player.Character:FindFirstChild("HumanoidRootPart").Position)
				local limbsToDistanceRatio = detectionQuery / distance
				if limbsToDistanceRatio >= (4 / ConfigMaxDistance) then
					callback(player)
					isChasing = true
				end
			end
		end
	end
end

return main
