defmodule Membrane.Element.Sdl.Sink do
  alias Membrane.Buffer
  alias Membrane.Caps.Video.Raw
  alias __MODULE__.Native
  use Membrane.Element.Base.Sink

  def_input_pads input: [
                   caps: Raw,
                   demand_unit: :buffers
                 ]

  @impl true
  def handle_init(_options) do
    {:ok, %{native: nil}}
  end

  @impl true
  def handle_caps(:input, caps, _ctx, state) do
    {:ok, native} = Native.create(caps.width, caps.height)
    {{:ok, demand: :input}, %{state | native: native}}
  end

  @impl true
  def handle_write(:input, %Buffer{payload: payload}, _ctx, state) do
    :ok = Native.display_frame(payload, state.native)
    :timer.sleep(33)
    {{:ok, demand: :input}, state}
  end

  @impl true
  def handle_playing_to_prepared(_ctx, state) do
    if state.native do
      :ok = Native.destroy(state.native)
    end

    {:ok, %{state | native: nil}}
  end
end
