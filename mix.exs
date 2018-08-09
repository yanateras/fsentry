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
      package: [
        description: "Efficient Inotify-based file system sentry",
        files: ["lib", "mix.exs"],
        licenses: ["CC0-1.0"],
        links: %{"GitHub" => "https://github.com/serokell/fsentry"}
      ]
    ]
  end

  def application do
    [mod: {FSentry.Application, []}]
  end

  @doc """
    Return CC flags required to build a shared library, depending on platform.
  """
  @spec shared_library :: [String.t()]
  def shared_library do
    case :os.type() do
      {:unix, :darwin} -> ["-dynamiclib", "-undefined", "dynamic_lookup"]
      {:unix, _rest} -> ["-shared"]
    end
  end

  @doc """
    Given a pkg-config module, return its CFLAGS and LDFLAGS.
  """
  @spec pkg_config(String.t()) :: [String.t()]
  def pkg_config(module) do
    case System.cmd("pkg-config", ["--cflags", "--libs", module]) do
      {output, 0} -> OptionParser.split(output)
      {_output, _status} -> Mix.raise("could not use pkg-config module '#{module}'")
    end
  end

  @doc """
    Return CC flags that add required native dependencies, if any.
  """
  @spec native_deps :: [String.t()]
  def native_deps do
    case :os.type() do
      {:unix, :linux} -> []
      {:unix, _rest} -> pkg_config("libinotify")
    end
  end

  @doc """
    Create a path from parent directory and file name, ensuring that parent directory exists.
  """
  @spec ensure_path(Path.t(), Path.t()) :: Path.t()
  def ensure_path(parent, child) do
    File.mkdir_p!(parent)
    Path.join(parent, child)
  end

  @doc """
    Return path to directory with ERTS headers.
  """
  @spec erts_headers :: Path.t()
  def erts_headers do
    Path.join([:code.root_dir(), ["erts-", :erlang.system_info(:version)], "/include"])
  end

  @spec compile_args :: [String.t()]
  def compile_args do
    [
      "-I" <> erts_headers(),
      ensure_path("src", "fsentry.c"),
      "-o",
      ensure_path("priv", "fsentry.so")
    ] ++ native_deps() ++ shared_library()
  end

  @doc """
    Build FSentry port driver.
  """
  def compile(_args) do
    case System.cmd("cc", compile_args()) do
      {_, 0} -> :ok
      {_, _} -> Mix.raise("could not build FSentry port driver")
    end
  end
end
