defmodule PASTRY.Pastry_system do
	def start_system(numNodes, numRequests) do
		nodesNum = String.to_integer(numNodes)
		for n <- 1..nodesNum do
			PASTRY.Pastry_node.start_node(n, nodesNum, numRequests)
		end

	end


end