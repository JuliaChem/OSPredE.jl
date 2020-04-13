module OSPropE
  # Function to call the GUI
  export OSPropEGUI

  if Sys.islinux()
    pkgpath = joinpath(dirname(Base.source_path()),"img")
    println(pkgpath)

    mycommand = `chmod 777 $(pkgpath)`

    run(mycommand)
  end

  # Include the main file .fl
  include("mainGUI_OSPropE.jl")
end
