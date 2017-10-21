defmodule PASTRY.Pastry_system do
	def start_system(numNodes, numRequests) do
		nodesNum = String.to_integer(numNodes)
		requestsNum = String.to_integer(numRequests)
		for n <- 1..nodesNum do
			spawn fn -> PASTRY.Pastry_node.start_node(n, nodesNum, requestsNum) end
		end

		# 0 is the server process name

		Process.register self(), String.to_atom("0")
		server_cycle(0, 0, nodesNum * requestsNum, nodesNum, 0)
	end

	def server_cycle(sum, count, numMessages, numNodes, startNodes) do
		receive do
			{:arrive, hops} ->
				case count + 1 == numMessages do
					true -> 
						averageHops = sum / count
						IO.puts "message number is #{count + 1}"
						IO.puts "average number of hops is #{averageHops}"
					false ->
						IO.puts "message number is #{count + 1}"
						server_cycle(sum + hops, count + 1, numMessages, numNodes, startNodes)
				end
			{:start} ->
				IO.puts "start nodes number #{startNodes + 1}"
				server_cycle(sum, count, numMessages, numNodes, startNodes + 1)
		end
	end

	def close_nodes(numNodes) do
		for n <- 1..numNodes do
			hashId = PASTRY.Pastry_node.get_hash(Integer.to_string(n))
			Process.exit(String.to_atom(hashId), :normal)
		end
	end

end