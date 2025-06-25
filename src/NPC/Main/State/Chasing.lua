local ChaseState = {}
local main = require(script.Parent.Parent)
local searchAlgorithm

function ChaseState.chase(targetPlayer: Player)
	local nodesToReset = main.getNodesInRadius(lastKnownLocation, 50)

	for _, node in nodesToReset do
		node:SetAttribute("IsSearched", false)
		node.BrickColor = BrickColor.new("New Yeller")
	end

	local nodesInRadius = main.getNodesInRadius(lastKnownLocation, 35)

	searchAlgorithm = task.spawn(function()
		local lastClosestNode = nil
		main.pathToNode(lastKnownLocation)
		while task.wait() do
			local startNode = lastClosestNode or nodesInRadius[math.random(1, #nodesInRadius)]
			lastClosestNode = main.getClosestNode(humanoidRootPart, false, nodesInRadius)
			lastClosestNode.BrickColor = BrickColor.new("Bright red")
			main.pathToNode(startNode.Position, function(pathStatus)
				if pathStatus == Enum.PathStatus.Success then
					startNode:SetAttribute("IsSearched", true)
					startNode.BrickColor = BrickColor.new("Bright blue")
					for _, node in main.getNodesInRadius(lastClosestNode.Position, 35) do
						if main.isInLineOfSight(lastClosestNode.Position + Vector3.new(0, 2, 0), node) then
							node:SetAttribute("IsSearched", true)
							node.BrickColor = BrickColor.new("Bright blue")
						end
					end
				end
			end, 5)
			if main.areAllNodesSearched(nodesInRadius) then
				main.changeBehaviorState("PATROLLING")
			end
		end
	end)

	main.searchForPlayer(function(targetPlayer)
		main.changeBehaviorState("CHASING", targetPlayer)
	end)
end

return ChaseState
