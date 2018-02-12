defmodule MapsAsFunctions.MixProject do
  use Mix.Project

  def project, do: [
    app: :maps_as_functions,
    version: "0.1.0",
    elixir: "~> 1.6",
    start_permanent: Mix.env() == :prod,
    deps: deps(),

    name: "MapsAsFunctions",
    source_url: "https://github.com/tsutsu/maps_as_functions",
    docs: [
      main: "MapsAsFunctions",
      extras: ["README.md"]
    ]
  ]

  def application, do: [
    extra_applications: [:logger]
  ]

  defp deps, do: [
    {:ex_doc, "~> 0.16", only: :dev, runtime: false}
  ]
end
