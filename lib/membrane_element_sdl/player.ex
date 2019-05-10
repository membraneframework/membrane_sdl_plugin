defmodule Membrane.Element.SDL.Player do
  @moduledoc """
  This module provides an [SDL](https://www.libsdl.org/)-based video player sink.
  """

  alias Membrane.{Buffer, Sync, Time}
  alias Membrane.Caps.Video.Raw
  alias Membrane.Event.StartOfStream
  alias Bundlex.CNode
  require CNode
  use Membrane.Element.Base.Sink
  use Bunch

  def_input_pad :input, caps: Raw, demand_unit: :buffers

  def_options sync: [], clock: []

  @impl true
  def handle_init(%__MODULE__{sync: sync, clock: clock}) do
    :ok = Sync.register(sync)
    {:ok, %{cnode: nil, clock: clock, sync: sync, synced?: false}}
  end

  @impl true
  def handle_stopped_to_prepared(_ctx, state) do
    {:ok, cnode} = CNode.start_link(:player)
    {:ok, %{state | cnode: cnode}}
  end

  @impl true
  def handle_caps(:input, caps, ctx, state) do
    %{input: input} = ctx.pads

    if !input.caps || caps == input.caps do
      {:ok, state}
    else
      {{:error, :caps_change}, state}
    end
  end

  @impl true
  def handle_event(:input, %StartOfStream{}, _ctx, state) do
    {{:ok, sync: state.sync}, state}
  end

  @impl true
  def handle_event(pad, event, ctx, state) do
    super(pad, event, ctx, state)
  end

  @impl true
  def handle_write(:input, %Buffer{payload: payload}, _ctx, state) do
    with :ok <- state.cnode |> CNode.call({:display_frame, payload}) do
      Shmex.ensure_not_gc(payload)
      {:ok, state}
    else
      :error -> {{:error, :display_frame}, state}
    end
  end

  def handle_tick(_timer, _ctx, state) do
    {{:ok, demand: :input}, state}
  end

  def handle_sync(sync, ctx, %{sync: sync, synced?: false} = state) do
    IO.inspect(:sdl_sync)
    %{caps: caps} = ctx.pads.input
    %{cnode: cnode} = state

    with :ok <- cnode |> CNode.call({:create, caps.width, caps.height}) do
      use Ratio
      {nom, denom} = ctx.pads.input.caps.framerate

      {{:ok, demand: :input, timer: {:timer, Time.seconds(denom) <|> nom, state.clock}},
       %{state | synced?: true}}
    else
      :error -> {{:error, :create}, state}
    end
  end

  def handle_synced(_sync, _ctx, state) do
    {:ok, state}
  end

  @impl true
  def handle_playing_to_prepared(_ctx, %{synced?: true} = state) do
    :ok = state.cnode |> CNode.call(:destroy)
    {{:ok, untimer: :timer}, %{state | synced?: false}}
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
