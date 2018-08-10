defmodule FSentry.MixProject do
  use Mix.Project

  def project do
    [
      app: :fsentry,
      version: "0.1.0",
      aliases: ["compile.fsentry": &compile_lazy/1],
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
      {output, 0} -> OptionParser.split(String.trim(output))
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

  @doc """
    Return path modification time.
  """
  @spec mtime(Path.t()) :: Integer.t()
  def mtime(path) do
    File.stat!(path).mtime
  end

  @doc """
    Compile FSentry port driver only if source is newer than target.
  """
  def compile_lazy(_args) do
    source = ensure_path("src", "fsentry.c")
    target = ensure_path("priv", "fsentry.so")

    unless File.exists?(target) && mtime(source) < mtime(target) do
      compile(source, target)
    end

    :ok
  end

  @spec compile_args(Path.t(), Path.t()) :: [String.t()]
  def compile_args(source, target) do
    ["-I" <> erts_headers(), source, "-o", target] ++ native_deps() ++ shared_library()
  end

  @spec compile(Path.t(), Path.t()) :: :ok
  def compile(source, target) do
    case System.cmd("cc", compile_args(source, target)) do
      {_output, 0} -> :ok
      {_output, _status} -> Mix.raise("could not build #{source}")
    end
  end
end
