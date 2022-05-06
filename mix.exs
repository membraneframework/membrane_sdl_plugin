defmodule Membrane.SDL.Plugin.MixProject do
  use Mix.Project

  @version "0.13.0"
  @github_url "https://github.com/membraneframework/membrane_sdl_plugin"

  def project do
    [
      app: :membrane_sdl_plugin,
      version: @version,
      elixir: "~> 1.12",
      compilers: [:unifex, :bundlex] ++ Mix.compilers(),
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      description: "Membrane video player based on SDL",
      package: package(),
      name: "Membrane SDL plugin",
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
      extras: ["README.md", LICENSE: [title: "License"]],
      formatters: ["html"],
      source_ref: "v#{@version}"
    ]
  end

  defp package do
    [
      maintainers: ["Membrane Team"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @github_url,
        "Membrane Framework Homepage" => "https://membraneframework.org"
      },
      files: ["lib", "mix.exs", "README*", "LICENSE*", ".formatter.exs", "bundlex.exs", "c_src"]
    ]
  end

  defp deps do
    [
      {:membrane_core, "~> 0.10.0"},
      {:membrane_common_c, "~> 0.12.0"},
      {:membrane_raw_video_format, "~> 0.2.0"},
      {:unifex, "~> 0.7.0"},
      # Testing
      {:membrane_h264_ffmpeg_plugin, "~> 0.17", only: :test},
      {:membrane_hackney_plugin, "~> 0.7", only: :test},
      # Development
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false},
      {:credo, "~> 1.6", only: :dev, runtime: false}
    ]
  end
end
