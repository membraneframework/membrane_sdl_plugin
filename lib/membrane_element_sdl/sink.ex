defmodule Membrane.Element.Sdl.Sink do
  alias Membrane.{Buffer, Time}
  alias Membrane.Caps.Video.Raw
  alias __MODULE__.Native
  use Membrane.Element.Base.Sink

  def_input_pads input: [
                   caps: Raw,
                   demand_unit: :buffers
                 ]

  @impl true
  def handle_init(_options) do
    {:ok, %{native: nil, timer: nil, expected_tick: nil, tick_err: nil}}
  end

  @impl true
  def handle_caps(:input, caps, ctx, state) do
    if !ctx.pads.input.caps do
      {:ok, native} = Native.create(caps.width, caps.height)
      tick(caps, %{state | expected_tick: Time.monotonic_time(), tick_err: 0, native: native})
    else
      {:ok, state}
    end
  end

  @impl true
  def handle_write(:input, %Buffer{payload: payload}, _ctx, state) do
    :ok = Native.display_frame(payload, state.native)
    {:ok, state}
  end

  @impl true
  def handle_other(:tick, ctx, state) do
    tick(ctx.pads.input.caps, state)
  end

  @impl true
  def handle_playing_to_prepared(_ctx, state) do
    if state.native do
      :ok = Native.destroy(state.native)
    end

    {:ok, %{state | native: nil}}
  end

  defp tick(caps, state) do
    {nom, denom} = caps.framerate
    {duration, err} = Bunch.Math.div_rem(1000 * denom, nom, state.tick_err)
    next_tick = state.expected_tick + Time.milliseconds(duration)
    timer = Process.send_after(self(), :tick, next_tick |> Time.to_milliseconds(), abs: true)
    {{:ok, demand: :input}, %{state | tick_err: err, expected_tick: next_tick, timer: timer}}
  end
end
