# Membrane Multimedia Framework: SDL element

[![Hex.pm](https://img.shields.io/hexpm/v/membrane_element_sdl.svg)](https://hex.pm/packages/membrane_element_sdl)
[![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](https://hexdocs.pm/membrane_element_sdl/)
[![CircleCI](https://circleci.com/gh/membraneframework/membrane-element-sdl.svg?style=svg)](https://circleci.com/gh/membraneframework/membrane-element-sdl)

This package provides an [SDL](https://www.libsdl.org/)-based video player.

It is part of [Membrane Multimedia Framework](https://membraneframework.org).

## Installation

The package can be installed by adding `membrane_element_sdl` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:membrane_element_sdl, "~> 0.3.0"}
  ]
end
```

The docs can be found at [HexDocs](https://hexdocs.pm/membrane_element_sdl).

## Usage

The pipeline below displays a sample h264 video from the net (with use of [Hackney](https://github.com/membraneframework/membrane-element-hackney) and [H264](https://github.com/membraneframework/membrane-element-ffmpeg-h264) elements):

```elixir
defmodule My.Pipeline do
  alias Membrane.Element.{FFmpeg.H264, Hackney, SDL}
  use Membrane.Pipeline

  @impl true
  def handle_init(_) do
    children = [
      hackney: %Hackney.Source{
        location: "https://membraneframework.github.io/static/video-samples/test-video.h264"
      },
      parser: %H264.Parser{framerate: {30, 1}},
      decoder: H264.Decoder,
      sdl: SDL.Player
    ]

    links = [
      link(:hackney)
      |> to(:parser)
      |> to(:decoder)
      |> to(:sdl)
    ]

    {{:ok, spec: %ParentSpec{children: children, links: links}}, %{}}
  end
end
```

## Testing

To run manual tests, type `mix test --include manual`

## Copyright and License

Copyright 2019, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane)

[![Software Mansion](https://logo.swmansion.com/logo?color=white&variant=desktop&width=200&tag=membrane-github)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane)

Licensed under the [Apache License, Version 2.0](LICENSE)
