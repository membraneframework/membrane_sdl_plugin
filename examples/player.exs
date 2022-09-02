Mix.install([
  :membrane_core,
  :membrane_h264_ffmpeg_plugin,
  :membrane_hackney_plugin,
  :membrane_sdl_plugin
])

defmodule Example do
  use Membrane.Pipeline

  @media_url "http://raw.githubusercontent.com/membraneframework/static/gh-pages/samples/big-buck-bunny/bun33s_720x480.h264"

  @impl true
  def handle_init(_opts) do
    spec = %ParentSpec{
      children: %{
        source: %Membrane.Hackney.Source{location: @media_url, hackney_opts: [follow_redirect: true]},
        parser: %Membrane.H264.FFmpeg.Parser{framerate: {25, 1}},
        decoder: Membrane.H264.FFmpeg.Decoder,
        player: Membrane.SDL.Player
      },
      links: [
        link(:source) |> to(:parser) |> to(:decoder) |> to(:player)
      ]
    }

    # Initialize the spec and start the playback
    {{:ok, spec: spec, playback: :playing}, %{}}
  end

  # `handle_element_end_of_stream/3` clauses handle automatic termination of the pipeline after playback is finished
  @impl true
  def handle_element_end_of_stream({:player, :input}, _ctx, state) do
    __MODULE__.terminate(self())
    {:ok, state}
  end

  @impl true
  def handle_element_end_of_stream(_element, _ctx, state), do: {:ok, state}
end

# Start the pipeline
{:ok, pipeline} = Example.start_link()
monitor_ref = Process.monitor(pipeline)

# Make sure the script doesn't terminate before the pipeline finishes the playback
receive do
  {:DOWN, ^monitor_ref, :process, _pid, _reason} -> :ok
end
