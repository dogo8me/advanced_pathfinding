-- dogo8me2

--// SERVICES
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--// CONSTANTS
local character = script.Parent
local config = require(script.Configuration)
local patrolState = require(script.Main.State.Patrolling)
local searchState = require(script.Main.State.Searching)
local main = require(script.Main)
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

floorPosition = main.getFloorPosition(character) - humanoidRootPart.Position

-- manually change the behavior state of the enemy
local function changeBehaviorState(state: BehaviorState, targetPlayer: Player?, lastKnownLocation: Vector3?)
	if patrolAlgorithm then task.cancel(patrolAlgorithm) end
	if searchAlgorithm then task.cancel(searchAlgorithm) end
	print(state)
	if state == "PATROLLING" then
		patrolAlgorithm = task.spawn(patrolState.patrol)

		main.searchForPlayer(function(targetPlayer)
			changeBehaviorState("CHASING", targetPlayer)
		end)
	elseif state == "SEARCHING" then -- searches for the player from the last known location
		searchAlgorithm = task.spawn(function() searchState.search(targetPlayer, lastKnownLocation) end)

		main.searchForPlayer(function(targetPlayer)
			changeBehaviorState("CHASING", targetPlayer)
		end)

		local nodesInRadius = main.getNodesInRadius(lastKnownLocation, 35)
		task.spawn(function()
			while task.wait() do
				if main.areAllNodesSearched(nodesInRadius) then
					main.changeBehaviorState("PATROLLING")
				end
			end
		end)

	elseif state == "CHASING" then
		while task.wait(0.25) do
			local targetCharacter = targetPlayer.Character
			local targetHumanoidRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
			if main.isCharacterInLineOfSight(character.Head, targetCharacter, 180, ConfigMaxDistance) then
				humanoid:MoveTo(targetHumanoidRootPart.Position)
			else
				print(targetCharacter)
				changeBehaviorState("SEARCHING", targetPlayer, targetHumanoidRootPart.Position) break 
			end
		end
	end
end

changeBehaviorState("PATROLLING")
