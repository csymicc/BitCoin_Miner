defmodule BitCoin.Server do
    
    @moduledoc """
    This module provides function to create a main node in cluster and 
    maintain subnode in cluster. Main node will also has a local subserver
    """
    @worktime 1000 * 30
    @result_stash :stash
    @num_stash :num
    @count :count
    

    def start(k, ip) do
        create_server_node(ip)
        Agent.start_link(fn -> [] end, name: { :global, @result_stash })   #store the result
        Agent.start_link(fn -> 1 end, name: { :global, @num_stash })       #store the start num of next work
        { :ok, count_pid } = Agent.start_link(fn -> 0 end, name: @count )
        spawn_link(BitCoin.Output, :init, [ count_pid ])
        spawn_link(Timer, :start_timer, [ self(), @worktime ])
        subserver_pid = spawn_link(BitCoin.SubServer, :start, [ k ])
        maintain(k, [ subserver_pid ] )
        IO.puts "Found #{Agent.get(@count, &(&1))} BitCoins"
    end

    @doc """
    used for measure work unit's effect
    def start(worksize, pid, {:ok}) do
        create_server_node("192.168.0.10")
        count_pid  = :global.whereis_name(:count)
        spawn_link(BitCoin.Output, :init, [ count_pid ])
        spawn_link(Timer, :start_timer, [ self(), @worktime ])
        subserver_pid = spawn_link(BitCoin.SubServer, :start, [ 4, worksize ])
        maintain(4, [ subserver_pid ] )
        send(pid, {:finish})
    end
    """
    def test(), do: 0

    #This function turn server node into distributed node
    defp create_server_node(ip) do
        nodename = String.to_atom("server@" <> ip)
        Node.start(nodename)
        Node.set_cookie(Node.self, :"blalalala")
        :global.register_name(nodename, self())
        #change IO.puts "Start Server process. Server name is #{nodename}"
    end

    
    #This function is used to maintain server state.
    #It will receive two message. First is timeout and function will stop all process.
    #Second is query message from remote subserver and 
    #function will add it into subserver list(Stored all subserver's pid).
    defp maintain(k, subservers) do
        receive do
            { :timeout } ->
                stop_server(subservers)
            { :query_info, pid } ->
                IO.puts "Remote SubServer #{inspect pid} requires information"
                subservers = subservers ++ [ pid ]
                send(pid, { k } )
                maintain(k, subservers)
            { :start_work, pid } ->
                IO.puts "Remote SubServer #{inspect pid} gets to work"
                maintain(k, subservers)
        end
    end

    
    #This function is used to stop main server and all its subserver.
    defp stop_server(subservers) do
        :timer.sleep(100)
        stop_subserver(subservers)
    end

    defp stop_subserver( [] ), do: 0 #change IO.puts "All subservers have been stopped"
    defp stop_subserver(subservers) do
        [ head | tail ] = subservers
        send(head, { :stop })
        stop_subserver(tail)
    end

end