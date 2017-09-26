defmodule Noizu.Scaffolding.Mixfile do
  use Mix.Project

  def project do
    [app: :noizu_scaffolding,
     version: "0.0.3",
     elixir: "~> 1.3",
     package: package(),
     deps: deps(),
     description: "Noizu Scaffolding"
   ]
  end

  defp package do
    [
      maintainers: ["noizu"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/noizu/elixir_scaffolding"}
    ]
  end

  def application do
    [ applications: [:logger] ]
  end

  defp deps do
    [
      { :amnesia, git: "https://github.com/meh/amnesia.git", ref: "87d8b4f"}, # Mnesia Wrapper
      { :uuid, "~> 1.1" },
      { :ex_doc, "~> 0.11", only: [:dev] }
    ]
  end

end
