defmodule Membrane.Element.SDL.Player do
  @moduledoc """
  This module provides an [SDL](https://www.libsdl.org/)-based video player sink.
  """

  alias Membrane.{Buffer, Time}
  alias Membrane.Caps.Video.Raw
  alias Bundlex.CNode

  require CNode

  use Membrane.Sink
  use Bunch

  @experimental_latency 20 |> Time.milliseconds()

  def_options latency: [
                type: :time,
                default: @experimental_latency,
                description: """
                Time needed to show a frame on a screen.
                May have to be adjusted for your system.
                """
              ]

  def_input_pad :input, caps: Raw, demand_unit: :buffers

  @impl true
  def handle_init(options) do
    state = %{cnode: nil, timer_started?: false}
    {{:ok, latency: options.latency}, state}
  end

  @impl true
  def handle_stopped_to_prepared(_ctx, state) do
    {:ok, cnode} = CNode.start_link(:player)
    {:ok, %{state | cnode: cnode}}
  end

  @impl true
  def handle_caps(:input, caps, ctx, state) do
    %{input: input} = ctx.pads
    %{cnode: cnode} = state

    if !input.caps || caps == input.caps do
      {cnode |> CNode.call({:create, caps.width, caps.height}), state}
    else
      raise "Caps have changed while playing. This is not supported."
    end
  end

  @impl true
  def handle_start_of_stream(:input, %{pads: %{input: %{caps: nil}}}, _state) do
    raise "No caps before start of stream"
  end

  def handle_start_of_stream(:input, ctx, state) do
    use Ratio
    {nom, denom} = ctx.pads.input.caps.framerate
    timer = {:demand_timer, Time.seconds(denom) <|> nom}

    {{:ok, demand: :input, start_timer: timer}, %{state | timer_started?: true}}
  end

  @impl true
  def handle_write(:input, %Buffer{payload: payload}, _ctx, state) do
    with :ok <- state.cnode |> CNode.call({:display_frame, payload}) do
      Shmex.ensure_not_gc(payload)
      {:ok, state}
    else
      :error -> raise "Error while displaying frame"
    end
  end

  @impl true
  def handle_tick(:demand_timer, _ctx, state) do
    {{:ok, demand: :input}, state}
  end

  @impl true
  def handle_playing_to_prepared(_ctx, %{timer_started?: true} = state) do
    :ok = state.cnode |> CNode.call(:destroy)
    {{:ok, stop_timer: :demand_timer}, %{state | timer_started?: false}}
  end

  @impl true
  def handle_playing_to_prepared(_ctx, state) do
    {:ok, state}
  end

  @impl true
  def handle_prepared_to_stopped(_ctx, state) do
    :ok = state.cnode |> CNode.stop()
    {:ok, %{state | cnode: nil}}
  end
end
