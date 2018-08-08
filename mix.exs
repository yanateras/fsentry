defmodule FSentry.MixProject do
  use Mix.Project

  def project do
    [
      app: :fsentry,
      version: "0.1.0",
      aliases: ["compile.fsentry": &compile/1],
      compilers: [:fsentry] ++ Mix.compilers(),
      deps: [
        {:dialyxir, "~> 0.5", only: :dev, runtime: false},
        {:ex_doc, "~> 0.18.0", only: :dev, runtime: false}
      ],
      links: %{"GitHub" => "https://github.com/serokell/fsentry"}
    ]
  end

  def application do
    [mod: {FSentry.Application, []}]
  end

  def compile(_) do
    File.mkdir_p!("priv")

    include = [:code.root_dir(), "/erts-", :erlang.system_info(:version), "/include"]
    args = ["-shared", "-I#{include}", "src/fsentry_inotify.c", "-o", "priv/fsentry.so"]

    case System.cmd("cc", args) do
      {_, 0} -> :ok
      {_, _} -> Mix.raise("could not build fsentry port driver")
    end
  end
end
