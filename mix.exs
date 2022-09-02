defmodule Hashcash.Mixfile do
  use Mix.Project

  def project do
    [
      app: :hashcash,
      version: "1.1.0",
      elixir: "~> 1.6",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),

      description: "Proof of work resource creation, generation and verification",
      package: package(),

    ]
  end

  defp package do
    [
      maintainers: [ "Dan Janowski" ],
      licenses: [ "Apache 2.0" ],
      links: %{
        "GitHub" => "https://github.com/danj3/elixir-hashcash"
      }
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :crypto]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:dialyxir, "~> 0.4", only: [:dev], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
    ]
  end
end
