defmodule Sworm.MixProject do
  use Mix.Project

  def project do
    [
      app: :sworm,
      version: File.read!("VERSION"),
      elixir: "~> 1.7",
      description:
        "A combination of a global, distributed process registry and supervisor, rolled into one, friendly API.",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Sworm.Application, []}
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE.md"],
      maintainers: ["Arjan Scherpenisse"],
      licenses: ["MIT"],
      links: %{Github: "https://github.com/arjan/sworm"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:horde, "~> 0.6"},
      {:ex_unit_clustered_case,
       github: "arjan/ex_unit_clustered_case", branch: "feature/manual-stop", only: :test}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
