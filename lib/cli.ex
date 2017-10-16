defmodule Project1.CLI do

    def main(arg) do
        [ value ] = arg
        list = String.split(value, ".")
        ip = getip()
        cond do
            length(list) == 1 ->
                IO.puts "This is a MainServer."
                Enum.at(list, 0) |> String.to_integer |> BitCoin.Server.start(ip)
            length(list) == 4 ->
                IO.puts "This is a SubServer"
                BitCoin.SubServer.start(ip, value)
            :true -> IO.puts "Wrong Input"
        end
    end

    defp getip() do
        case :inet.getif() do
            { :ok, [ _, _, _, _ ] } -> getip_windows()
            { :ok, [ _, _ ] } -> getip_linux()
        end
    end

    defp getip_windows() do
        { :ok, [ _, _, _, { {a,b,c,d} , _, _ } ] } = :inet.getif()
        ip_to_string(a, b, c, d)
    end

    defp getip_linux() do
        { :ok, [ { {a,b,c,d}, _, _ }, _ ] } = :inet.getif()
        ip_to_string(a, b, c, d)
    end

    defp ip_to_string(a, b, c, d) do
        to_string(a) <> <<?.>> <> 
        to_string(b) <> <<?.>> <> 
        to_string(c) <> <<?.>> <> 
        to_string(d)
    end

end