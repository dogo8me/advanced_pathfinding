local PatrolState = {}
local main = require(script.Parent.Parent)
local configuration = require(script.Parent.Parent.Parent.Configuration)
local patrolAlgorithm

function PatrolState.patrol()
	local lastClosestNode = nil

	task.spawn(function()
		while task.wait(0.1) do
			local nodesInRadius = main.getNodesInRadius(main.humanoidRootPart.Position, configuration.MaxDistance)
			for i, node in nodesInRadius do
				if main.isInLineOfSightFOV(node) and node:GetAttribute("IsSearched") ~= true then
					node:SetAttribute("IsSearched", true)
					node.BrickColor = BrickColor.new("Bright blue")
				end
			end
		end
	end)

	local radius = 35

	while task.wait() do
		print("\n[Patrol Loop] Starting new patrol cycle")

		local farthestNode = main.getFarthestNode(main.humanoidRootPart, false)
		local nodesInRadius = main.getNodesInRadius(farthestNode.Position, radius, false)
		local startNode = lastClosestNode or nodesInRadius[math.random(1, #nodesInRadius)]
		lastClosestNode = main.getClosestNode(main.humanoidRootPart, false)
		if lastClosestNode then
			lastClosestNode.BrickColor = BrickColor.new("Bright red")
		end

		nodesInRadius = main.getNodesInRadius(startNode.Position, radius, false)
		if next(nodesInRadius) == nil then
			repeat radius += 15 until next(main.getNodesInRadius(startNode.Position, radius, false)) ~= nil
		end

		local nodeToPathTo = nodesInRadius[math.random(1, #nodesInRadius)]
		print("[Patrol Loop] Node chosen to path to at position:", tostring(nodeToPathTo.Position))

		main.pathToNode(nodeToPathTo.Position, function(pathStatus)
			print("[Path Callback] Path status:", pathStatus.Name)
			if pathStatus == Enum.PathStatus.Success then
				print("[Path Callback] Successful path, marking node as searched at position:", tostring(nodeToPathTo.Position))
				nodeToPathTo:SetAttribute("IsSearched", true)
				nodeToPathTo.BrickColor = BrickColor.new("Bright blue")
			else
				print("[Path Callback] Failed to path to node at position:", tostring(nodeToPathTo.Position))
			end
		end, 25)
	end
end

return PatrolState
