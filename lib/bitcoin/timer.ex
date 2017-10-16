defmodule Timer do
    def start_timer(pid, time) do
        #change IO.puts "Timer is on"
        :timer.sleep(time)
        send(pid, { :timeout })
    end
end