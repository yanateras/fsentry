defmodule FSentry.MixProject do
  use Mix.Project

  def project do
    [
      app: :fsentry,
      version: "0.0.0",
      aliases: ["compile.fsentry": &compile/1]
      #      compilers: Mix.compilers() ++ [:fsentry]
    ]
  end

  def compile(_) do
    File.mkdir_p!("priv")

    include = [:code.root_dir(), "/erts-", :erlang.system_info(:version), "/include"]
    args = ["-shared", "-I#{include}", "src/fsentry_inotify.c", "-o", "priv/fsentry.so"]

    case System.cmd("cc", args) do
      0 -> :ok
      _ -> {:error, []}
    end
  end
end
