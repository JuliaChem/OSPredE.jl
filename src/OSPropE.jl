module OSPropE
  # Function to call the GUI
  export OSPropEGUI

  using Gtk, Gtk.ShortNames, JLD, Suppressor, CSV, Mustache, Dates
  import DataFrames

  # Path to CSS Gtk-Style dataFile
  global style_file = joinpath(dirname(Base.source_path()), "style2020.css")

  # General Settings
  global pathPUREDIPPR = joinpath(dirname(Base.source_path()), "PUREDIPPR.csv")

  # Load default database
  global databaseDIPPR = CSV.read(pathPUREDIPPR)
  println(1)

  # Include the main file .fl
  include("mainGUI_OSPropE.jl")
end
