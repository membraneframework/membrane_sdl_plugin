defmodule Membrane.Element.SDL.BundlexProject do
  use Bundlex.Project

  def project do
    [
      cnodes: cnodes(Bundlex.platform())
    ]
  end

  defp cnodes(_platform) do
    [
      sink: [
        sources: ["sink.c", "cnodeserver.c"],
        deps: [shmex: :lib_cnode, bunch_native: :bunch],
        pkg_configs: ["sdl2"]
      ]
    ]
  end
end
