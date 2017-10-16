defmodule BitCoin.SubServer do
    @moduledoc """
    This module provides function to create and maintain subserver
    Main function of subserver is to invoke all workers and manage their work
    """
    @worker_num 10
    @workload 200
    @num_stash :num
    @result_stash :stash
    
    @doc """
    This start function is to create a local subserver
    """
    def start(k) when is_integer(k) do
        IO.puts "SubServer #{inspect self()} begins to work"
        start_subserver(k)
    end

    @doc """
    This start function is to create a remote subserver
    """
    def start(ip, serverip), do: link_server_node(ip, serverip) |> init
    defp init(server_pid) do
        if send(server_pid, { :query_info, self() }) == :false do
            IO.puts "cannot connect to server"
        else
            receive do
                { k } ->
                    IO.puts "Retrieve information successfully. Worker num is #{@worker_num}, workload is #{@workload}, k is #{k}"  
                    send(server_pid, { :start_work, self() })
                    sync_process()
                    start_subserver(k)
            after 5000 ->
                reconnect(server_pid)
            end
        end
    end

    defp link_server_node(ip, serverip) do
        nodename = String.to_atom("subserver@" <> ip)
        Node.start(nodename)
        Node.set_cookie(Node.self, :"blalalala")
        servernode = String.to_atom("server@" <> serverip)
        case Node.connect(servernode) do
            :true ->
                :timer.sleep(500)
                :global.whereis_name(servernode)
                |> get_server_pid(servernode)
            :false -> :false
        end
    end 

    defp get_server_pid(pid, _ ) when pid != :undefined, do: pid
    defp get_server_pid( _ , servernode ) do
        :timer.sleep(500)
        :global.whereis_name(servernode)
        |> get_server_pid(servernode)
    end

    defp sync_process() do
        stash_pid = :global.whereis_name(@result_stash)
        num_pid = :global.whereis_name(@num_stash)
        if stash_pid == :undefined || num_pid == :undefined do
            :global.sync()
            :timer.sleep(100)
            sync_process()
        end
    end

    defp reconnect(server_pid) do
        nodelist = Node.list()
        if length(nodelist) == 0 do
            IO.puts "lost connection to server"
        else
            IO.puts "Server doesn't react, resend query"
            init(server_pid)
        end
    end

    defp start_subserver(k) do
        Enum.map(1..@worker_num, 
        fn _ -> GenServer.start_link(BitCoin.Worker, k) end)
        |> start_mining
    end

    #This function is to inital all workers
    defp start_mining([]), do: maintain()
    defp start_mining(workerlist) do
        [ {:ok, pid} | tail ] = workerlist
        num_stash = :global.whereis_name(@num_stash)
        cur_num = Agent.get_and_update(num_stash, &({ &1, &1 + @workload }))
        GenServer.cast(pid, [ cur_num, @workload, self()])
        start_mining(tail)
    end

    #This function is to manage all workers
    defp maintain() do
        receive do
            {:finish, pid} ->
                num_stash = :global.whereis_name(@num_stash)
                cur_num = Agent.get_and_update(num_stash, &({ &1, &1 + @workload }))
                GenServer.cast(pid, [ cur_num, @workload, self()])
                maintain()
            { :stop } -> :true
        end
    end

    @doc """
    used for measure work unit's effect
    def start(k, worksize, { :ok }) when is_integer(k) do
        start_subserver(k, worksize)
    end
    
    defp start_subserver(k, worksize) do
        Enum.map(1..@worker_num, 
        fn _ -> GenServer.start_link(BitCoin.Worker, k) end)
        |> start_mining(worksize)
    end

    #This function is to inital all workers
    defp start_mining([], worksize), do: maintain(worksize)
    defp start_mining(workerlist, worksize) do
        [ {:ok, pid} | tail ] = workerlist
        num_stash = :global.whereis_name(@num_stash)
        cur_num = Agent.get_and_update(num_stash, &({ &1, &1 + worksize }))
        GenServer.cast(pid, [ cur_num, worksize, self()])
        start_mining(tail, worksize)
    end

    #This function is to manage all workers
    defp maintain(worksize) do
        receive do
            {:finish, pid} ->
                num_stash = :global.whereis_name(@num_stash)
                cur_num = Agent.get_and_update(num_stash, &({ &1, &1 + worksize }))
                GenServer.cast(pid, [ cur_num, worksize, self()])
                maintain(worksize)
            { :stop } -> :true
        end
    end
    """
    def test(), do: 0

end