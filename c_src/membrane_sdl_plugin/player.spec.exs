state_type "State"

callback :main, :main_function

spec create(width :: int, height :: int) :: {:ok :: label, state}
spec display_frame(payload, state) :: :ok :: label
