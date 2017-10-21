defmodule PASTRY.Pastry_node do
	
	use GenServer

	def start_node(nodeId, numNodes, numRequests) do
		nodeIdStr = Integer.to_string(nodeId)
		hashId = get_hash(nodeIdStr)
		GenServer.start_link(__MODULE__, [], [name: String.to_atom(hashId)])
	end

	def handle_cast(msg, []) do
		{:noreply, []}
	end

	def get_hash(input) do
		:crypto.hash(:md5, input)
		|> Base.encode16
	end

end