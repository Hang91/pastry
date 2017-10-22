defmodule PASTRY.Pastry_node do
	
	use GenServer

	def start_node(nodeId, numNodes, numRequests, all_nodes) do

		localId = get_hash(Integer.to_string(nodeId))
		size = numNodes

		index = binary_search(all_nodes, localId, 0, size - 1)
		leaf_setL = get_leafSetL(all_nodes, index + 1, size, [], 16)
		leaf_setS = get_leafSetS(all_nodes, index - 1, [], 16)
		route_table = get_routeTable(all_nodes, localId, [], 0, size - 1, 0)
		neighborSet = get_neighborSet(all_nodes, size, 0, [], localId)

		GenServer.start(__MODULE__, [localId, leaf_setL, leaf_setS, route_table, neighborSet,numNodes], [name: String.to_atom(localId)])

		send String.to_atom("0"), {:start}

		waitTime = numNodes * simple_log(numNodes, 2, 1)
		:timer.sleep(waitTime)
		spawn fn -> send_message(all_nodes, size, numRequests, localId, leaf_setL, leaf_setS, route_table, neighborSet, numNodes) end

	end

	def get_charToInteger(str, index) do
		String.at(str, index)
		|> to_string
		|> String.to_integer(16)
	end

	def integerToCharBase16(int) do
		Integer.to_string(int, 16)
		|> String.at(0)
	end

	def send_message(list, size, numRequests, localId, leaf_setL, leaf_setS, route_table, neighborSet, numNodes) do
		if numRequests > 0 do
			key = Enum.random(list)
			case String.equivalent?(key, localId) do
				false -> 
					send_message(localId, key, 0, leaf_setL, leaf_setS, route_table, neighborSet, numNodes)
					send_message(list, size, numRequests - 1, localId, leaf_setL, leaf_setS, route_table, neighborSet, numNodes)
				true ->
					send_message(list, size, numRequests, localId, leaf_setL, leaf_setS, route_table, neighborSet, numNodes)
			end
		end
	end

	def send_message(localId, key, hops, leaf_setL, leaf_setS, route_table, neighborSet, numNodes) do
		case inSet?(leaf_setL, key) || inSet?(leaf_setS, key) do
			true ->
				try do 
					res = GenServer.call(String.to_atom(key), {key, hops + 1})
				catch
					:exit, reason ->
						send String.to_atom("0"), {:failure, hops, localId, key}
				end
			false ->
				routingRes = routing(key, route_table, localId, 0, neighborSet)
				try do
					res = GenServer.call(String.to_atom(routingRes), {key, hops + 1})
				catch
					:exit, reason ->
						send String.to_atom("0"), {:failure, hops, localId, routingRes}
				end
		end
	end

	def simple_log(input, res, i) do
		case res < input do
			true ->
				simple_log(input, res * 2, i + 1)
			false ->
				i
		end
	end

	def routing(key, route_table, localId, index, neighborSet) do
		keyChar = String.at(key, index)
		localChar = String.at(localId, index)
		case keyChar == localChar do
			true -> 
				routing(key, route_table, localId, index + 1, neighborSet)
			false -> 
				res = find_closest(key, route_table, localId, index)
				case res do
					:none -> getFromNeighbor(neighborSet)
					id -> id
				end
		end
	end

	def find_closest(key, route_table, localId, index) do
		list = Enum.at(route_table, index, :none)
		case list do
			:none -> :none
			nil -> 
				:none
			_ ->
				keyVal = String.at(key, index) |> to_string |> String.to_integer(16)
				localVal = String.at(localId, index) |> to_string |> String.to_integer(16)
				minDistance = abs(keyVal - localVal)
				closest = find_closest(list, key, index, 0, minDistance, localId)
				case String.equivalent?(closest, localId) do
					true -> :none
					false -> closest
				end
		end
	end

	def find_closest(list, key, index, i, minDistance, closest) do
		case i < Enum.count(list) do
			true ->
				nodeId = Enum.at(list, i)
				distance = 
				case nodeId != nil do
					true -> 
						keyVal = String.at(key, index) |> to_string 
						|> String.to_integer(16)
						nodeVal = String.at(nodeId, index) |> to_string 
						|> String.to_integer(16)
						abs(keyVal - nodeVal)
					false -> 16
				end

				case distance < minDistance do
					true -> 
						find_closest(list, key, index, i + 1, distance, nodeId)
					false -> 
						find_closest(list, key, index, i + 1, minDistance, closest)
				end
			false ->
				closest
		end
	end

	def getFromNeighbor(neighborSet) do
		Enum.random(neighborSet)
	end 

	def inSet?(list, key) do
		res = Enum.find(list, -1, fn(id) -> String.equivalent?(key, id) end)
		case res >= 0 do
			true -> true
			false -> false
		end
	end

	def handle_call(msg, from, [localId, leaf_setL, leaf_setS, route_table, neighborSet, numNodes]) do
		case msg do
			{key, hops} -> 
				case String.equivalent?(key, localId) do
					true -> 
						# 0 is server name
						send String.to_atom("0"), {:arrive, hops}
					false -> 
						send_message(localId, key, hops, leaf_setL, leaf_setS, route_table, neighborSet, numNodes)
				end
			_ -> 
				IO.puts "call exception"
		end
		{:reply, :ok, [localId, leaf_setL, leaf_setS, route_table, neighborSet, numNodes]}
	end

	def get_hash(input) do
		:crypto.hash(:md5, input)
		|> Base.encode16
	end


	def get_leafSetL(list, index, size, res, i) do
		case i > 0 && index < size do
			true -> 
				id = Enum.at(list, index)
				new_res = List.insert_at(res, 16 - i, id)
				get_leafSetL(list, index + 1, size, new_res, i - 1)
			false ->
				res
		end
	end

	def get_leafSetS(list, index, res, i) do
		case i > 0 && index >= 0 do
			true -> 
				id = Enum.at(list, index)
				new_res = List.insert_at(res, 16 - i, id)
				get_leafSetS(list, index - 1, new_res, i - 1)
			false ->
				res
		end
	end

	def get_routeTable(list, localId, res, left, right, index) do		
		case index < 32 do
			true ->
				new_list = []
				case left < 0 || right < 0 do
					true -> 
						new_res = List.insert_at(res, index, new_list)
						get_routeTable(list, localId, new_res, left, right, index + 1)
					false ->
						localChar = get_charToInteger(localId, index)
						new_list = 
						for n <- 0..15 do
							new_list = 
							if n != localChar do
								charN = integerToCharBase16(n)
								searchRes = binary_search_index(list, left, right, index, charN)
								new_list = 
								case searchRes do
									{:ok, charIndex} ->
										routeId = Enum.at(list, charIndex)
										List.insert_at(new_list, 0, routeId)
									{:no} -> []
								end
							end
						end
						new_list = List.flatten(new_list)
						new_res = List.insert_at(res, index, new_list)
						searchRes1 = binary_search_firstAt(list, left, right, index, String.at(localId, index))
						case searchRes1 do
							{:ok, new_left} ->
								searchRes2 = binary_search_lastAt(list, left, right, index, String.at(localId, index))
								case searchRes2 do
									{:ok, new_right} ->
										get_routeTable(list, localId, new_res, new_left, new_right, index + 1)
									{:no} ->
										get_routeTable(list, localId, new_res, -1, -1, index + 1)
								end
							{:no} -> 
								get_routeTable(list, localId, new_res, -1, -1, index + 1)
						end
				end
			false ->
				res
		end
	end

	def get_neighborSet(list, size, i, res, localId) do
		case i < 32 do
			true -> 
				id = Enum.random(list)
				case String.equivalent?(id, localId) do
					true -> 
						get_neighborSet(list, size, i, res, localId)
					false ->
						new_res = List.insert_at(res, 0, id)
						get_neighborSet(list, size, i + 1, new_res, localId)
				end
			false -> res
		end
	end


	def binary_search_index(list, left, right, index, char_atIndex) do
		mid = Integer.floor_div(left + right, 2)
		nodeId = Enum.at(list, mid)
		findRes = String.at(nodeId, index)
		case left <= right do
			true -> 
				case findRes == char_atIndex do
					true -> 
						{:ok, mid}
					false ->
						case findRes > char_atIndex do
							true -> 
								binary_search_index(list, left, mid - 1, index, char_atIndex)
							false ->
								binary_search_index(list, mid + 1, right, index, char_atIndex)
						end
				end
			false ->
				{:no}
		end
	end

	def binary_search_lastAt(list, left, right, index, char_atIndex) do
		mid = Integer.floor_div(left + right, 2)
		nodeId = Enum.at(list, mid)
		findRes = String.at(nodeId, index)
		case left < right - 1 do
			true -> 
				case findRes > char_atIndex do
					true -> 
						binary_search_lastAt(list, left, mid, index, char_atIndex)
					false ->
						binary_search_lastAt(list, mid, right, index, char_atIndex)
				end
			false ->
				rightNode = Enum.at(list, right)
				rightRes = String.at(rightNode, index)				
				case rightRes == char_atIndex do
					true -> {:ok, right}
					false -> 
						case findRes == char_atIndex do
							true -> {:ok, left}
							false -> {:no}
						end
				end
		end
	end

	def binary_search_firstAt(list, left, right, index, char_atIndex) do
		mid = Integer.floor_div(left + right, 2)
		nodeId = Enum.at(list, mid)
		findRes = String.at(nodeId, index)
		case left < right - 1 do
			true -> 
				case findRes < char_atIndex do
					true -> 
						binary_search_firstAt(list, mid, right, index, char_atIndex)
					false ->
						binary_search_firstAt(list, left, mid, index, char_atIndex)
				end
			false -> 
				rightNode = Enum.at(list, right)
				rightRes = String.at(rightNode, index)
				case findRes == char_atIndex do
					true -> {:ok, left}
					false -> 
						case rightRes == char_atIndex do
							true -> {:ok, right}
							false -> {:no}
						end
				end
		end
	end	

	def binary_search(list, localId, left, right) do
		mid = Integer.floor_div((left + right), 2)
		nodeId = Enum.at(list, mid)
		localIdNum = String.to_integer(localId, 16)
		nodeIdNum = String.to_integer(nodeId, 16)
		case nodeIdNum == localIdNum do
			true -> mid
			false ->
			case nodeIdNum > localIdNum do
				true -> 
					binary_search(list, localId, left, mid - 1)
				false ->
					binary_search(list, localId, mid + 1, right)
			end
		end
	end

end