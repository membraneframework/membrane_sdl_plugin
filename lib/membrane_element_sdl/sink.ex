defmodule Membrane.Element.Sdl.Sink do
  alias Membrane.{Buffer, Time}
  alias Membrane.Caps.Video.Raw
  alias Bundlex.CNode
  require CNode
  use Membrane.Element.Base.Sink
  use Bunch

  def_input_pad :input, caps: Raw, demand_unit: :buffers

  @impl true
  def handle_init(_options) do
    {:ok, %{cnode: nil, timer: nil, expected_tick: nil, tick_err: nil}}
  end

  @impl true
  def handle_stopped_to_prepared(_ctx, state) do
    {:ok, cnode} = CNode.start_link(:sink)
    {:ok, %{state | cnode: cnode}}
  end

  @impl true
  def handle_caps(:input, caps, ctx, state) do
    %{cnode: cnode, timer: timer} = state
    %{input: input} = ctx.pads

    withl caps: true <- input.caps != caps,
          stop: :ok <- if(input.caps, do: cnode |> CNode.call(:destroy), else: :ok),
          call: :ok <- cnode |> CNode.call({:create, caps.width, caps.height}) do
      if timer, do: Process.cancel_timer(timer)
      tick(caps, %{state | expected_tick: Time.monotonic_time(), tick_err: 0})
    else
      caps: false -> {:ok, state}
      stop: :error -> {{:error, :destroy}, state}
      call: :error -> {{:error, :create}, state}
    end
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

  @impl true
  def handle_other(:tick, %{playback_state: :playing} = ctx, state) do
    tick(ctx.pads.input.caps, state)
  end

  @impl true
  def handle_other(:tick, _ctx, state) do
    {:ok, state}
  end

  @impl true
  def handle_playing_to_prepared(_ctx, state) do
    Process.cancel_timer(state.timer)
    state = %{state | timer: nil}
    :ok = state.cnode |> CNode.call(:destroy)
    {:ok, state}
  end

  @impl true
  def handle_prepared_to_stopped(_ctx, state) do
    :ok = state.cnode |> CNode.stop()
    {:ok, %{state | cnode: nil}}
  end

  defp tick(caps, state) do
    {nom, denom} = caps.framerate
    {duration, err} = Bunch.Math.div_rem(1000 * denom, nom, state.tick_err)
    next_tick = state.expected_tick + Time.milliseconds(duration)
    timer = Process.send_after(self(), :tick, next_tick |> Time.to_milliseconds(), abs: true)
    {{:ok, demand: :input}, %{state | tick_err: err, expected_tick: next_tick, timer: timer}}
  end
end
