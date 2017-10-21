defmodule PASTRY.Pastry_node do
	
	use GenServer

	def start_node(nodeId, numNodes, numRequests) do
		nodeIdStr = Integer.to_string(nodeId)
		hashId = get_hash(nodeIdStr)
		all_nodes = Enum.sort(all_nodesId(numNodes, 1, []))
		size = Enum.count(all_nodes)
		index = binary_search(all_nodes, hashId, 0, size - 1)
		leaf_setL = get_leafSetL(all_nodes, index + 1, size, [], 16)
		leaf_setS = get_leafSetS(all_nodes, index - 1, [], 16)
		lastres = binary_search_lastAt(all_nodes, 0, numNodes - 1, 0, String.at(hashId, 0))
		firstres = binary_search_firstAt(all_nodes, 0, numNodes - 1, 0, String.at(hashId, 0))
		{:ok, last} = lastres
		{:ok, first} = firstres
		GenServer.start_link(__MODULE__, [], [name: String.to_atom(hashId)])
		IO.puts "start node #{hashId}"
	end

	def handle_cast(msg, []) do
		{:noreply, []}
	end

	def get_hash(input) do
		:crypto.hash(:md5, input)
		|> Base.encode16
	end

	def all_nodesId(numNodes, i, list) do
		case numNodes < i do
			false ->
				hashId = get_hash(Integer.to_string(i))
				all_nodesId(numNodes, i + 1, List.insert_at(list, 0, hashId))
			true ->
				List.flatten(list)
		end
	end

	def get_leafSetL(list, index, size, res, i) do
		case i > 0 && index < size do
			true -> 
				{id, rem} = List.pop_at(list, index)
				new_res = List.insert_at(res, 16 - i, id)
				get_leafSetL(list, index + 1, size, new_res, i - 1)
			false ->
				res
		end
	end

	def get_leafSetS(list, index, res, i) do
		case i > 0 && index >= 0 do
			true -> 
				{id, rem} = List.pop_at(list, index)
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
				localChar = String.at(localId, index)
				new_list = 
				for n <- 0..15 do
					new_list = 
					if n != String.to_integer(localChar) do
						searchRes = binary_search_index(list, left, right, index, localChar)
						new_list = 
						case searchRes do
							{:ok, firstIndex} ->
								{routeId, rem1} = List.pop_at(list, firstIndex)
								List.insert_at(new_list, 0, routeId)
							{:no} -> "do nothing"
						end
					end
				end
				List.insert_at(res, index, )
			false ->
				res
		end
	end

	def binary_search_index(list, left, right, index, char_atIndex) do
		mid = Integer.floor_div(left + right, 2)
		{nodeId, rem} = List.pop_at(list, mid)
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
		{nodeId, rem} = List.pop_at(list, mid)
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
				{rightNode, rem1} = List.pop_at(list, right)
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

	def binary_search_firstAt(list, left, right,index, char_atIndex) do
		mid = Integer.floor_div(left + right, 2)
		{nodeId, rem} = List.pop_at(list, mid)
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
				{rightNode, rem1} = List.pop_at(list, right)
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
		{nodeId, rem_list} = List.pop_at(list, mid)
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