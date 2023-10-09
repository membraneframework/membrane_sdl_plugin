defmodule Membrane.SDL.BundlexProject do
  use Bundlex.Project

  defp get_sdl2_url() do
    url_prefix =
      "https://github.com/membraneframework-precompiled/precompiled_sdl2/releases/latest/download/sdl2"

    case Bundlex.get_target() do
      %{os: "linux"} ->
        {:precompiled, "#{url_prefix}_linux.tar.gz"}

      %{architecture: "x86_64", os: "darwin" <> _rest_of_os_name} ->
        {:precompiled, "#{url_prefix}_macos_intel.tar.gz"}

      %{architecture: "aarch64", os: "darwin" <> _rest_of_os_name} ->
        {:precompiled, "#{url_prefix}_macos_arm.tar.gz"}

      _other ->
        nil
    end
  end

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
          {[get_sdl2_url(), :pkg_config], "sdl2"}
        ],
        preprocessor: Unifex
      ]
    ]
  end
end
