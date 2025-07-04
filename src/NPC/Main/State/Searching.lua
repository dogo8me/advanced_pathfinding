local SearchState = {}
local main = require(script.Parent.Parent)
local character = script.Parent.Parent.Parent.Parent
local humanoidRootPart = character.HumanoidRootPart

function SearchState.search(targetPlayer: Player, lastKnownLocation: Vector3)
	local nodesToReset = main.getNodesInRadius(lastKnownLocation, 50, true)

	for _, node in nodesToReset do
		node:SetAttribute("IsSearched", false)
		node.BrickColor = BrickColor.new("New Yeller")
	end

	local nodesInRadius = main.getNodesInRadius(lastKnownLocation, 35, true)
	
	local lastClosestNode = nil

	main.pathToNode(lastKnownLocation, nil, 2)

	while task.wait() do
		local startNode = lastClosestNode or nodesInRadius[math.random(1, #nodesInRadius)]
		lastClosestNode = main.getClosestNode(humanoidRootPart, false, nodesInRadius)
		if not lastClosestNode then print(nodesInRadius) end
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
	end

end

return SearchState
