defmodule MapsAsFunctions.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project, do: [
    app: :maps_as_functions,
    version: @version,
    elixir: "~> 1.6",
    start_permanent: Mix.env() == :prod,
    deps: deps(),

    description: description(),
    package: package(),
    name: "MapsAsFunctions",
    source_url: "https://github.com/tsutsu/maps_as_functions",
    docs: docs()
  ]

  def application, do: [
    extra_applications: [:logger]
  ]

  defp deps, do: [
    {:ex_doc, "~> 0.16", only: :dev, runtime: false}
  ]

  defp description, do: """
  A macro to create compile-time-expanded maps.
  """

  defp package, do: [
    # These are the default files included in the package
    files: ["lib", "mix.exs", "README*", "LICENSE*"],
    maintainers: ["Levi Aul"],
    licenses: ["MIT"],
    links: %{"GitHub" => "https://github.com/tsutsu/maps_as_functions"}
  ]

  defp docs, do: [
    source_ref: "v#\{@version\}",
    canonical: "https://hexdocs.pm/maps_as_functions",
    main: "readme",
    extras: ["README.md"],
    groups_for_extras: [
      "Readme": Path.wildcard("*.md")
    ]
  ]
end
