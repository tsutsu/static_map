defmodule StaticMap.MixProject do
  use Mix.Project

  @version "0.1.1"

  def project, do: [
    app: :static_map,
    version: @version,
    elixir: "~> 1.6",
    start_permanent: Mix.env() == :prod,
    deps: deps(),

    description: description(),
    package: package(),
    name: "StaticMap",
    source_url: "https://github.com/tsutsu/static_map",
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
    links: %{"GitHub" => "https://github.com/tsutsu/static_map"}
  ]

  defp docs, do: [
    source_ref: "v#\{@version\}",
    canonical: "https://hexdocs.pm/static_map",
    main: "readme",
    extras: ["README.md"],
    groups_for_extras: [
      "Readme": Path.wildcard("*.md")
    ]
  ]
end
