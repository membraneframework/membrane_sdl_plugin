defmodule Membrane.Element.FFmpeg.SWResample.BundlexProject do
  use Bundlex.Project

  def project do
    [
      nifs: nifs(Bundlex.platform())
    ]
  end

  defp nifs(_platform) do
    [
      sink: [
        sources: ["sink.c", "_generated/sink.c"],
        deps: [unifex: :unifex, membrane_common_c: :membrane],
        pkg_configs: ["sdl2"]
      ]
    ]
  end
end
