defmodule BitCoin.Output do
    

    @result_stash :stash

    def init(count) do
        stash = :global.whereis_name(@result_stash)
        output(stash, count)
    end

    defp output(stash, count) do
        res = Agent.get(stash, &(&1))
        if length(res) != 0 do
            [ head | tail ] = res
            Agent.update(stash, fn _ -> tail end)
            { key, value } = head
            IO.puts to_string(key) <> <<9>> <> value
            Agent.update(count, &(&1 + 1))
        end
        output(stash, count)
    end

end