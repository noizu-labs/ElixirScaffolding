defmodule Noizu.Scaffolding.Mixfile do
  use Mix.Project

  def project do
    [app: :noizu_scaffolding,
     version: "0.1.0",
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
      { :amnesia, git: "https://github.com/meh/amnesia.git", ref: "87d8b4f", optional: true}, # Mnesia Wrapper
      { :uuid, "~> 1.1" },
      { :ex_doc, "~> 0.11", only: [:dev], optional: true },
      {:markdown, github: "devinus/markdown", only: [:dev], optional: true}, # Markdown processor for ex_doc
    ]
  end # end deps

  defp docs do
    [
      source_url_pattern: "https://github.com/noizu/ElixirScaffolding/blob/master/%{path}#L%{line}",
      extras: ["README.md"]
    ]
  end # end docs

end # end defmodule
