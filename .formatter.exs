[
  inputs: [
    "{lib,test,config}/**/*.{ex,exs}",
    ".formatter.exs",
    "*.exs",
    "c_src/**/*.spec.exs"
  ],
  import_deps: [:membrane_core, :bundlex, :unifex]
]
