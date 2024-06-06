defmodule Membrane.SDL.Player do
  @moduledoc """
  This module provides an [SDL](https://www.libsdl.org/)-based video player sink.
  """

  use Bunch
  use Membrane.Sink

  require Membrane.Logger
  require Unifex.CNode

  alias Membrane.{Buffer, Time}
  alias Membrane.RawVideo
  alias Unifex.CNode

  # The measured latency needed to show a frame on a screen.
  @latency 20 |> Time.milliseconds()

  def_input_pad :input,
    accepted_format: %RawVideo{pixel_format: :I420},
    flow_control: :manual,
    demand_unit: :buffers

  @impl true
  def handle_init(_options, _ctx) do
    {[latency: @latency], %{cnode: nil, last_pts: nil, last_payload: nil}}
  end

  @impl true
  def handle_setup(_ctx, state) do
    {:ok, cnode} = CNode.start_link(:player)

    {[], %{state | cnode: cnode}}
  end

  @impl true
  def handle_stream_format(:input, stream_format, ctx, %{cnode: cnode} = state) do
    %{input: input} = ctx.pads

    if !input.stream_format || stream_format == input.stream_format do
      :ok = CNode.call(cnode, :create, [stream_format.width, stream_format.height])
      {[], state}
    else
      raise "Stream format have changed while playing. This is not supported."
    end
  end

  @impl true
  def handle_start_of_stream(:input, _ctx, state) do
    {[demand: :input, start_timer: {:demand_timer, :no_interval}], state}
  end

  @impl true
  def handle_buffer(:input, %Buffer{payload: payload, pts: pts}, _ctx, state) do
    payload = Membrane.Payload.to_binary(payload)

    actions =
      case state do
        %{last_pts: nil, last_payload: nil} ->
          :ok = CNode.call(state.cnode, :display_frame, [payload])

          [demand: :input]

        %{last_pts: last_pts} ->
          [timer_interval: {:demand_timer, pts - last_pts}]
      end

    {actions, %{state | last_pts: pts, last_payload: payload}}
  end

  @impl true
  def handle_tick(:demand_timer, _ctx, state) do
    :ok = CNode.call(state.cnode, :display_frame, [state.last_payload])
    {[timer_interval: {:demand_timer, :no_interval}, demand: :input], state}
  end
end
