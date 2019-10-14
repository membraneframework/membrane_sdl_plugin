defmodule Membrane.Element.SDL.MixProject do
  use Mix.Project

  @version "0.2.1"
  @github_url "https://github.com/membraneframework/membrane-element-sdl"

  def project do
    [
      app: :membrane_element_sdl,
      version: @version,
      elixir: "~> 1.7",
      compilers: [:unifex, :bundlex] ++ Mix.compilers(),
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      description: "Membrane Multimedia Framework (SDL Element)",
      package: package(),
      name: "Membrane Element: SDL",
      source_url: @github_url,
      docs: docs(),
      homepage_url: "https://membraneframework.org",
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_ref: "v#{@version}"
    ]
  end

  defp package do
    [
      maintainers: ["Membrane Team"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => @github_url,
        "Membrane Framework Homepage" => "https://membraneframework.org"
      },
      files: ["lib", "mix.exs", "README*", "LICENSE*", ".formatter.exs", "bundlex.exs", "c_src"]
    ]
  end

  defp deps do
    [
      {:membrane_core, "~> 0.4.1"},
      {:membrane_common_c, "~> 0.2.0"},
      {:membrane_caps_video_raw, "~> 0.1.0"},
      {:bundlex, "~> 0.2.6"},
      {:shmex, "~> 0.2.0"},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0.0-rc.6", only: [:dev], runtime: false}
    ]
  end
end
