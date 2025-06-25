local PatrolState = {}
local main = require(script.Parent.Parent)
local configuration = require(script.Parent.Parent.Parent.Configuration)
local patrolAlgorithm

function PatrolState.patrol()
	local lastClosestNode = nil
	
	task.spawn(function()
		while task.wait(0.1) do
			local nodesInRadius = main.getNodesInRadius(main.humanoidRootPart.Position, 10)
			for i, node in nodesInRadius do
				if main.isInLineOfSightFOV(node, configuration.FieldOfView) and node:GetAttribute("IsSearched") ~= true then
					node:SetAttribute("IsSearched", true)
					node.BrickColor = BrickColor.new("Bright blue")
				end
			end
		end
	end)
	while task.wait() do
		local nodesInRadius = main.getNodesInRadius(main.humanoidRootPart.Position, 50)
		local startNode = lastClosestNode or nodesInRadius[math.random(1, #nodesInRadius)]
		lastClosestNode = main.getClosestNode(main.humanoidRootPart)
		lastClosestNode.BrickColor = BrickColor.new("Bright red")
		local nodesInRadius = main.getNodesInRadius(startNode.Position, 35)
		local nodeToPathTo = nodesInRadius[math.random(1, #nodesInRadius)]
		main.pathToNode(nodeToPathTo.Position, function(pathStatus)
			if pathStatus == Enum.PathStatus.Success then
				nodeToPathTo:SetAttribute("IsSearched", true)
				nodeToPathTo.BrickColor = BrickColor.new("Bright blue")
				for _, node in main.getNodesInRadius(nodeToPathTo.Position, 35) do
					if main.isInLineOfSight(nodeToPathTo.Position + Vector3.new(0, 2, 0), node) then
						node:SetAttribute("IsSearched", true)
						node.BrickColor = BrickColor.new("Bright blue")
					end
				end
			end 
		end, 25)
	end
end

return PatrolState
