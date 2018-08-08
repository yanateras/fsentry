defmodule FSentry do
  @moduledoc """
    Module for creating (eventually) cross-platform file system sentries.
  """

  @doc """
    Load native port driver.
  """
  @spec load :: :ok | {:error, reason :: term()}
  def load do
    :erl_ddll.load_driver(:code.priv_dir(:fsentry), 'fsentry')
  end

  @doc """
    Start sentry listening for changes on path, returns PID.

    Change events are sent to `self_pid` and assume `{sentry_pid, path, message}`
    format where `message` is `:create | :modify | :delete`.
  """
  @spec start!(pid(), Path.t()) :: pid()
  def start!(self_pid \\ self(), path) do
    spawn_link(fn -> watch(self_pid, open_port(path)) end)
  end

  @doc """
    Stop sentry by PID.
  """
  @spec stop(pid()) :: :ok
  def stop(pid) do
    send(pid, :stop)
    :ok
  end

  # Create port driver instance listening on given path.
  @spec open_port(Path.t()) :: port()
  defp open_port(path) do
    Port.open({:spawn_driver, "fsentry #{path}"}, [:in])
  end

  # Listen for port driver events and retransmit them to given PID. Exit on :stop.
  @spec watch(pid(), port()) :: no_return()
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
