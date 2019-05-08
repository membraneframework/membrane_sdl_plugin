# Membrane Multimedia Framework: MembraneElementSdl

This package provides an SDL-based video player.

It is part of [Membrane Multimedia Framework](https://membraneframework.org).

## Installation

The package can be installed by adding `membrane_element_sdl` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:membrane_element_sdl, "~> 0.1.0"}
  ]
end
```

The docs can be found at [HexDocs](https://hexdocs.pm/membrane_element_sdl).

## Usage

The pipeline below displays a sample h264 video from the net (with use of [Hackney](https://github.com/membraneframework/membrane-element-hackney) and [H264](https://github.com/membraneframework/membrane-element-ffmpeg-h264) elements):

```elixir
defmodule My.Pipeline do
  alias Membrane.Element.{FFmpeg.H264, Hackney, Sdl}
  alias Membrane.Pipeline.Spec
  use Membrane.Pipeline

  @impl true
  def handle_init(_) do
    children = [
      hackney: %Hackney.Source{
        location: "https://membraneframework.github.io/static/video-samples/test-video.h264"
      },
      parser: %H264.Parser{framerate: {30, 1}},
      decoder: H264.Decoder,
      sdl: Sdl.Sink
    ]

    links = %{
      {:hackney, :output} => {:parser, :input},
      {:parser, :output} => {:decoder, :input},
      {:decoder, :output} => {:sdl, :input}
    }

    {{:ok, %Spec{children: children, links: links}}, %{}}
  end
end

```

## Copyright and License

Copyright 2019, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane)

[![Software Mansion](https://membraneframework.github.io/static/logo/swm_logo_readme.png)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane)

Licensed under the [Apache License, Version 2.0](LICENSE)
