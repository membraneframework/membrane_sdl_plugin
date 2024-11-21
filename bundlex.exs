defmodule Membrane.SDL.BundlexProject do
  use Bundlex.Project

  def project do
    [
      natives: natives()
    ]
  end

  defp natives() do
    [
      player: [
        interface: :cnode,
        sources: ["player.c"],
        os_deps: [
          sdl2: [
            {:precompiled, Membrane.PrecompiledDependencyProvider.get_dependency_url(:sdl2),
             "SDL2"},
            {:pkg_config, "sdl2"}
          ]
        ],
        preprocessor: Unifex
      ]
    ]
  end
end
