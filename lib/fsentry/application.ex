defmodule FSentry.Application do
  @moduledoc """
    Fake application that loads native port driver.
  """

  @behaviour Application

  def start(_, _) do
    case FSentry.load() do
      :ok -> {:ok, spawn_link(&loop/0)}
      err -> err
    end
  end

  def stop(_) do
    :ok
  end

  @spec loop :: no_return()
  defp loop do
    receive do
    end
  end
end
