module OSPropE
  # Function to call the GUI
  export OSPropEGUI

  if Sys.islinux()
    pkgpath = joinpath(dirname(Base.source_path()))
    ;chmod +rwxc $pkgpath
  end

  # Include the main file .fl
  include("mainGUI_OSPropE.jl")
end
