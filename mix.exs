defmodule FileStorageApi.MixProject do
  use Mix.Project

  def project do
    [
      app: :file_storage_api,
      version: "1.2.1",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: [warnings_as_errors: Mix.env() != :test],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      description:
        "Package to allow uploading to multiple different asset storage through 1 api. Configurable through env vars.",
      maintainers: ["Nulian"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/bettyblocks/file_storage_api"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_microsoft_azure_storage, "~> 1.0"},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_aws, "~> 2.1"},
      {:ex_aws_s3, "~> 2.0"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:file_info, "~> 0.0.4"},
      {:jason, "~> 1.4"},
      {:mox, "~> 1.0", only: :test},
      {:recase, "~> 0.5"},
      {:temp, "~> 0.4"}
    ]
  end
end
