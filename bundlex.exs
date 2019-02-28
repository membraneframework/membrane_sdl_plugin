defmodule Membrane.Element.FFmpeg.SWResample.BundlexProject do
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
        deps: [shmex: :lib_cnode],
        pkg_configs: ["sdl2"]
      ]
    ]
  end
end
