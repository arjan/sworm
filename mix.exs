defmodule Sworm.MixProject do
  use Mix.Project

  def project do
    [
      app: :sworm,
      version: File.read!("VERSION"),
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:horde, github: "derekkraan/horde", branch: "fix_register"},
      # {:horde, path: "../horde"},
      {:ex_unit_clustered_case,
       github: "xinz/ex_unit_clustered_case", branch: "master", only: :test}
    ]
  end
end
