defmodule Project1Test do
  use ExUnit.Case
  doctest BitCoin.SubServer

  @tag timeout: 1000 * 60 * 60
  test "Find best work size" do
    {:ok, file} = File.open "hello", [:write]
    find_best(1, 0, file)
    File.close(file)
  end

  def find_best( _ , 30, _), do: { :ok }
  def find_best(worksize, times, file) do
    one = unit(worksize)
    two = unit(worksize)
    three = unit(worksize)
    avg = one + two + three
    IO.puts to_string(worksize) <> <<9>> <> to_string(avg / 3)
    IO.binwrite(file, to_string(worksize) <> <<9>> <> to_string(avg / 3))
    find_best(worksize + 2, times + 1, file)
  end

  def unit(worksize) do
    { :ok, r } = Agent.start_link(fn -> [] end, name: { :global, :stash })
    { :ok, n } = Agent.start_link(fn -> 1 end, name: { :global, :num })
    { :ok, c } = Agent.start_link(fn -> 0 end, name: { :global, :count } )
    spawn(BitCoin.Server, :start, [ worksize, self(), {:ok} ])
    receive do {:finish} -> {:finish} end
    cnt = Agent.get(c, &(&1))
    Agent.stop(r)
    Agent.stop(n)
    Agent.stop(c)
    cnt
  end

end
