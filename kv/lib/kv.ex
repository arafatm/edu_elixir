defmodule KV do
  def start_link do
    Task.start_link(fn -> loop(%{}) end)
  end

  defp loop(map) do
    IO.puts "loop #{inspect map}"
    receive do
      {:get, key, caller} ->
        IO.puts ":get #{inspect key}, #{inspect caller}" 
        send caller, Map.get(map, key)
        loop(map)
      {:put, key, value} ->
        IO.puts ":put #{inspect key}, #{inspect value}" 
        loop(Map.put(map, key, value))
    end
  end
end
