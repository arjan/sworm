defmodule Sworm.MixProject do
  use Mix.Project

  def project do
    [
      app: :sworm,
      version: File.read!("VERSION"),
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
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
      {:horde, "~> 0.6"},
      # {:horde, path: "../horde"},
      {:ex_unit_clustered_case,
       github: "arjan/ex_unit_clustered_case", branch: "feature/manual-stop", only: :test}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
