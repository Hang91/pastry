defmodule PASTRY.Pastry_system do
	def start_system(numNodes, numRequests) do
		nodesNum = String.to_integer(numNodes)
		requestsNum = String.to_integer(numRequests)

		all_nodes = Enum.sort(all_nodesId(nodesNum, 1, []))

		for n <- 1..nodesNum do
			spawn fn -> PASTRY.Pastry_node.start_node(n, nodesNum, requestsNum, all_nodes) end
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
			{:failure, hops, localId, key} ->
				IO.puts "#{localId} send to #{key} is failed"
				server_cycle(sum, count, numMessages, numNodes, startNodes)
		end
	end

	def close_nodes(numNodes) do
		for n <- 1..numNodes do
			hashId = PASTRY.Pastry_node.get_hash(Integer.to_string(n))
			Process.exit(String.to_atom(hashId), :normal)
		end
	end

	def all_nodesId(numNodes, count, list) do
		case count <= numNodes do
			true ->
				hashId = PASTRY.Pastry_node.get_hash(Integer.to_string(count))
				all_nodesId(numNodes, count + 1, List.insert_at(list, 0, hashId))
			false ->
				List.flatten(list)
		end
	end

	def get_idhashMap(numNodes, count, map) do
		case count <= numNodes do
			true -> 
				hashId = PASTRY.Pastry_node.get_hash(Integer.to_string(count))
				get_idhashMap(numNodes, count + 1, Map.put(map, hashId, count))
			false ->
				map
		end
	end

end