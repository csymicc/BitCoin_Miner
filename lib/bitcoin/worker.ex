 defmodule BitCoin.Worker do
    @moduledoc """
    This module provides function to find bitcoin.
    """
    
    use GenServer

    @prefix "csymicc/"
    @result_stash :stash

    def handle_cast(offset, k) when is_list(offset) do
        IO.puts Agent.get(:)
        start_num = Enum.at(offset, 0)
        size = Enum.at(offset, 1)
        parent = Enum.at(offset, 2)
        stash = :global.whereis_name(@result_stash)
        find_bitcoin(start_num, start_num + size, k, stash)
        send(parent, {:finish, self()})
        { :noreply, k }
    end

    #This function generate string according to current number.
    defp generate_key(cur_num, value) do
        remain = rem(cur_num, 96)
        value = <<remain + 32>> <> value
        cur_num = div(cur_num, 96)
        if cur_num == 0, do: value,
        else: generate_key(cur_num, value)
    end
    
    #This function generates all the key based on working range and check their shd256 hashcodes
    #fulfill the requirement.
    defp find_bitcoin(cur_num, end_num, k, _) 
    when cur_num == end_num, do: {:noreply, k}

    defp find_bitcoin(cur_num, end_num, k, stash) when cur_num != end_num do
        key = @prefix <> generate_key(cur_num, "")
        value = Base.encode16(:crypto.hash(:sha256, key))
        res = value |> to_charlist |> check(k)
        if res, do: Agent.update(stash, &( &1 ++ [{String.to_atom(key), value}] ))
        find_bitcoin(cur_num + 1, end_num, k, stash)
    end

    defp check(_ , 0), do: :true
    defp check([], _), do: :false
    defp check(hashcode, k) do
        [head | tail] = hashcode
        if head != 48, do: :false, 
        else: check(tail, k - 1)
    end

end