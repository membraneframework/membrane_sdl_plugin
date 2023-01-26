defmodule Membrane.SDL.Player do
  @moduledoc """
  This module provides an [SDL](https://www.libsdl.org/)-based video player sink.
  """

  use Bunch
  use Membrane.Sink

  require Unifex.CNode

  alias Membrane.{Buffer, Time}
  alias Membrane.RawVideo
  alias Unifex.CNode

  # The measured latency needed to show a frame on a screen.
  @latency 20 |> Time.milliseconds()

  def_input_pad :input, caps: RawVideo, demand_unit: :buffers

  @impl true
  def handle_init(_options) do
    state = %{cnode: nil, timer_started?: false}
    {{:ok, latency: @latency}, state}
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

    cond do
      !input.caps -> :ok = CNode.call(cnode, :create, [caps.width, caps.height])
      caps == input.caps -> :ok
      true -> raise "Caps have changed while playing. This is not supported."
    end

    {:ok, state}
  end

  @impl true
  def handle_start_of_stream(:input, %{pads: %{input: %{caps: nil}}}, _state) do
    raise "No caps before start of stream"
  end

  @impl true
  def handle_start_of_stream(:input, ctx, state) do
    use Ratio
    {nom, denom} = ctx.pads.input.caps.framerate
    timer = {:demand_timer, Time.seconds(denom) <|> nom}

    {{:ok, demand: :input, start_timer: timer}, %{state | timer_started?: true}}
  end

  @impl true
  def handle_write(:input, %Buffer{payload: payload}, _ctx, state) do
    payload = Membrane.Payload.to_binary(payload)
    :ok = CNode.call(state.cnode, :display_frame, [payload])
    {:ok, state}
  end

  @impl true
  def handle_tick(:demand_timer, _ctx, state) do
    {{:ok, demand: :input}, state}
  end

  @impl true
  def handle_playing_to_prepared(_ctx, %{timer_started?: true} = state) do
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
