defmodule ExDissonance.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_dissonance,
      version: "0.1.0",
      elixir: "~> 1.18",
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
      {:typed_struct, "~> 0.3.0"},
      {:phoenix_pubsub, "~> 2.1"},
      {:fnv1a, "~> 0.1.0"}
    ]
  end
end
