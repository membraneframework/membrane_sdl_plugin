defmodule Membrane.Element.SDL.BundlexProject do
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
        pkg_configs: ["sdl2"],
        preprocessor: Unifex
      ]
    ]
  end
end
