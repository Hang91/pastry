defmodule Pastry do
  @moduledoc """
  Documentation for Pastry.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Pastry.hello
      :world

  """
  def hello do
    :world
  end

  def main(args) do
    {numNodes,args} = List.pop_at(args,0)
    {numRequests,args} = List.pop_at(args,0)
    IO.puts "num of nodes: #{numNodes}"
    IO.puts "num of requests: #{numRequests}"

    PASTRY.Pastry_system.start_system(numNodes,numRequests)
  end
end
