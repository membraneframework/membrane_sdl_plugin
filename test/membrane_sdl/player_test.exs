defmodule Membrane.SDL.PlayerTest do
  use ExUnit.Case

  import Membrane.Testing.Assertions

  alias Membrane.{H264, Hackney, SDL, Testing}

  @tag :manual
  test "integration test" do
    options = %Testing.Pipeline.Options{
      elements: [
        hackney: %Hackney.Source{
          location: "https://membraneframework.github.io/static/video-samples/test-video.h264"
        },
        parser: %H264.FFmpeg.Parser{framerate: {30, 1}},
        decoder: H264.FFmpeg.Decoder,
        sdl: SDL.Player
      ]
    }

    {:ok, pid} = Testing.Pipeline.start_link(options)
    Testing.Pipeline.play(pid)
    assert_end_of_stream(pid, :sdl, :input, 15_000)
    Testing.Pipeline.stop_and_terminate(pid, blocking?: true)
  end
end
