defmodule Membrane.SDL.PlayerTest do
  use ExUnit.Case

  import Membrane.ChildrenSpec
  import Membrane.Testing.Assertions

  alias Membrane.{H264, Hackney, SDL, Testing}

  @tag :manual
  test "integration test" do
    options = [
      structure:
        child(:hackney, %Hackney.Source{
          location:
            "https://raw.githubusercontent.com/membraneframework/static/gh-pages/samples/ffmpeg-testsrc.h264",
          hackney_opts: [follow_redirect: true]
        })
        |> child(:parser, %H264.Parser{generate_best_effort_timestamps: %{framerate: {30, 1}}})
        |> child(:decoder, H264.FFmpeg.Decoder)
        |> child(:sdl, SDL.Player)
    ]

    pipeline = Testing.Pipeline.start_link_supervised!(options)
    assert_end_of_stream(pipeline, :sdl, :input, 15_000)
  end
end
