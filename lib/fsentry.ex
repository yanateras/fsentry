defmodule FSentry do
  @on_load :load

  def load do
    :erl_ddll.load_driver(:code.priv_dir(:fsentry), 'fsentry')
  end

  def start(self_pid \\ self(), path) do
    pid = spawn_link(fn -> watch(self_pid, open_port(path)) end)
    {:ok, pid}
  end

  def stop(pid) do
    send(pid, :stop)
    :ok
  end

  defp open_port(path) do
    Port.open({:spawn_driver, ['fsentry #{path}']}, [:in])
  end

  defp watch(pid, port) do
    receive do
      {^port, path, message} ->
        send(pid, {self(), path, message})

      :stop ->
        exit(:stop)
    end

    watch(pid, port)
  end
end
