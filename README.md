# Membrane SDL plugin

[![Hex.pm](https://img.shields.io/hexpm/v/membrane_sdl_plugin.svg)](https://hex.pm/packages/membrane_sdl_plugin)
[![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](https://hexdocs.pm/membrane_sdl_plugin/)
[![CircleCI](https://circleci.com/gh/membraneframework/membrane_sdl_plugin.svg?style=svg)](https://circleci.com/gh/membraneframework/membrane_sdl_plugin)

This package provides an [SDL](https://www.libsdl.org/)-based video player.

It is part of [Membrane Multimedia Framework](https://membraneframework.org).

Documentation is available at [HexDocs](https://hexdocs.pm/membrane_sdl_plugin).

## Installation

Add the following line to your `deps` in `mix.exs`. Run `mix deps.get`.

```elixir
def deps do
  [
    {:membrane_sdl_plugin, "~> 0.18.2"}
  ]
end
```
This package depends on the [SDL2](https://www.libsdl.org) library. The precompiled build will be pulled and linked automatically. However, should there be any problems, consider installing it manually. In the case of development mode, you need to install FFmpeg on your system.

### Manual instalation of dependencies
#### Ubuntu

```bash
sudo apt-get install sdl2
```

#### Arch/Manjaro

```bash
pacman -S sdl2
```

#### MacOS

```bash
brew install sdl2
```

## Usage

Usage example can be found in [`examples/player.exs`](examples/player.exs).
This example demonstrates how to play a H264 video, downloaded in real-time from Membrane's static repository over HTTP.

To run it, simply execute the following command in your terminal:

```bash
$ elixir examples/player.exs
```

## Testing

To run manual tests, type `mix test --include manual`

## Copyright and License

Copyright 2019, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane)

[![Software Mansion](https://logo.swmansion.com/logo?color=white&variant=desktop&width=200&tag=membrane-github)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane)

Licensed under the [Apache License, Version 2.0](LICENSE)
