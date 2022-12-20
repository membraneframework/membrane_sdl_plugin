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

  def_input_pad :input, accepted_format: RawVideo, demand_unit: :buffers

  @impl true
  def handle_init(_options, _ctx) do
    state = %{cnode: nil, timer_started?: false}
    {[latency: @latency], state}
  end

  @impl true
  def handle_setup(ctx, state) do
    {:ok, cnode} = CNode.start_link(:player)

    Membrane.ResourceGuard.register(
      ctx.resource_guard,
      fn -> CNode.stop(cnode) end
    )

    {[], %{state | cnode: cnode}}
  end

  @impl true
  def handle_stream_format(:input, stream_format, ctx, state) do
    %{input: input} = ctx.pads
    %{cnode: cnode} = state

    if !input.stream_format || stream_format == input.stream_format do
      :ok = CNode.call(cnode, :create, [stream_format.width, stream_format.height])
      {[], state}
    else
      raise "Stream format have changed while playing. This is not supported."
    end
  end

  @impl true
  def handle_start_of_stream(:input, ctx, state) do
    use Ratio
    {nom, denom} = ctx.pads.input.stream_format.framerate
    timer = {:demand_timer, Time.seconds(denom) <|> nom}

    {[demand: :input, start_timer: timer], %{state | timer_started?: true}}
  end

  @impl true
  def handle_write(:input, %Buffer{payload: payload}, _ctx, state) do
    payload = Membrane.Payload.to_binary(payload)
    :ok = CNode.call(state.cnode, :display_frame, [payload])
    {[], state}
  end

  @impl true
  def handle_tick(:demand_timer, _ctx, state) do
    {[demand: :input], state}
  end
end
