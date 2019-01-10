module Membrane.Element.Sdl.Sink.Native

spec create(width :: int, height :: int) ::
       {:ok :: label, state} | {:error :: label, reason :: atom}

spec display_frame(payload, state) :: :ok :: label

spec destroy(state) :: :ok :: label
