defmodule FSentry.Application do
  @moduledoc """
    Fake application that loads native port driver.
  """

  @behaviour Application

  def start(_type, _args) do
    case FSentry.load() do
      :ok -> {:ok, spawn_link(&loop/0)}
      err -> err
    end
  end

  def stop(_state) do
    :ok
  end

  @spec loop :: no_return()
  defp loop do
    receive do
    end
  end
end
