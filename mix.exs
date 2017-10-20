defmodule Noizu.Scaffolding.Mixfile do
  use Mix.Project

  def project do
    [app: :noizu_scaffolding,
     version: "1.1.15",
     elixir: "~> 1.4",
     package: package(),
     deps: deps(),
     description: "Noizu Scaffolding",
     docs: docs()
   ]
  end # end procject

  defp package do
    [
      maintainers: ["noizu"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/noizu/elixir_scaffolding"}
    ]
  end # end package

  def application do
    [ applications: [:logger] ]
  end # end application

  defp deps do
    [
      {:amnesia, git: "https://github.com/meh/amnesia.git", ref: "87d8b4f", optional: true}, # Mnesia Wrapper
      {:uuid, "~> 1.1" },
      {:ex_doc, "~> 0.16.2", only: [:dev], optional: true}, # Documentation Provider
      {:markdown, github: "devinus/markdown", only: [:dev], optional: true}, # Markdown processor for ex_doc
      {:plug, "~> 1.0", optional: true}
    ]
  end # end deps

  defp docs do
    [
      source_url_pattern: "https://github.com/noizu/ElixirScaffolding/blob/master/%{path}#L%{line}",
      extras: ["README.md", "markdown/sample_conventions_doc.md"]
    ]
  end # end docs

end # end defmodule
