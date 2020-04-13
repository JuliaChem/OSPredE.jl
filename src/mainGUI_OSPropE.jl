# OSPropE
# Instituto Tecnológico de Celaya/TecNM - México 2020
# Sánchez-Sánchez Kelvyn Baruc
# Jímenez-Gutierrez Arturo
# CONACyT-SENER-Hidrocarburos

using Gtk, Gtk.ShortNames, JLD, Suppressor, CSV, Mustache, Dates, Rsvg, Cairo
import DataFrames, MolecularGraph

# Aliasing for shortname
const MG = MolecularGraph
const DF = DataFrames

# Path to CSS Gtk-Style dataFile
global style_file = joinpath(dirname(Base.source_path()), "style2020.css")

# General Settings
# Database path
if Sys.iswindows()
    global pathPUREDIPPR = joinpath(dirname(Base.source_path()), "database\\PUREDIPPR.csv")
    global filename_in = joinpath(dirname(Base.source_path()), "img\\molsvg.svg")
    global filename_out = joinpath(dirname(Base.source_path()), "img\\molpng.png")

    # Delete image file to avoid problems (linux)
    imgpath = joinpath(dirname(Base.source_path()),"\\img")
    println(imgpath)
    rm(imgpath, recursive=true)
    mkdir(imgpath)
end

if Sys.islinux()
    global pathPUREDIPPR = joinpath(dirname(Base.source_path()), "database/PUREDIPPR.csv")
    global filename_in = joinpath(dirname(Base.source_path()), "img/molsvg.svg")
    global filename_out = joinpath(dirname(Base.source_path()), "img/molpng.png")

    # Delete image file to avoid problems (linux)
    imgpath = joinpath(dirname(Base.source_path()),"/img")
    println(imgpath)
    rm(imgpath, recursive=true)
    mkdir(imgpath)
end

################################################################################
# Load default database
################################################################################
@async global databaseDIPPR = CSV.read(pathPUREDIPPR)

# Main function
function OSPropEGUI()
    # Suppress warnings
    #@suppress begin
    global filename_in
    global filename_out

    # Environmental variable to allow Windows decorations
    ENV["GTK_CSD"] = 0

    # CSS style
    @sync global provider = CssProviderLeaf(filename = style_file)

    # Measurement of screen size to allow compatibility to all screen devices
    global w, h = screen_size()

    ################################################################################
    # Main Win
    ################################################################################
    winOSPropE = Window()
    # Properties for mainWin
    set_gtk_property!(winOSPropE, :title, "OSPropE")
    set_gtk_property!(winOSPropE, :window_position, 3)
    set_gtk_property!(winOSPropE, :accept_focus, true)
    set_gtk_property!(winOSPropE, :resizable, false)
    set_gtk_property!(winOSPropE, :width_request, w*0.50)
    set_gtk_property!(winOSPropE, :height_request, h*0.75)
    set_gtk_property!(winOSPropE, :visible, false)

    ################################################################################
    # Toolbar
    ################################################################################
    # Menu Icons
    tb1 = ToolButton("gtk-new")
    set_gtk_property!(tb1, :label, "New")
    set_gtk_property!(tb1, :tooltip_markup, "Create a new simulation environment")

    tb2 = ToolButton("gtk-open")
    set_gtk_property!(tb2, :label, "Open")
    set_gtk_property!(tb2, :tooltip_markup, "Open a simulation file")

    tb3 = ToolButton("gtk-floppy")
    set_gtk_property!(tb3, :label, "Export")
    set_gtk_property!(
        tb3,
        :tooltip_markup,
        "Save the current state environment to a JLD file",
    )
    set_gtk_property!(tb3, :sensitive, false)

    # Close toolbar
    tb4 = ToolButton("gtk-close")
    set_gtk_property!(tb4, :label, "Close")
    set_gtk_property!(tb4, :tooltip_markup, "Close current simulation environment")

    signal_connect(tb4, :clicked) do widget
        destroy(winOSPropE)
    end

    signal_connect(winOSPropE, "key-press-event") do widget, event
        if event.keyval == 65307
            destroy(newWin)
        end
    end

    tb5 = ToolButton("gtk-preferences")
    set_gtk_property!(tb5, :label, "Tools")
    set_gtk_property!(tb5, :tooltip_markup, "Tools")

    tb6 = ToolButton("gtk-about")
    set_gtk_property!(tb6, :label, "Help")
    set_gtk_property!(tb6, :tooltip_markup, "Help")

    # Toolbar
    newToolbar = Toolbar()
    set_gtk_property!(newToolbar, :height_request, (h*.75)*.09)
    set_gtk_property!(newToolbar, :toolbar_style, 2)
    push!(newToolbar, tb1)
    push!(newToolbar, tb2)
    push!(newToolbar, tb3)
    push!(newToolbar, tb5)
    push!(newToolbar, tb6)
    push!(newToolbar, tb4)

    gridToolbar = Grid()
    set_gtk_property!(gridToolbar, :column_homogeneous, true)
    set_gtk_property!(gridToolbar, :row_homogeneous, false)

    frameToolbar = Frame()
    push!(frameToolbar, newToolbar)
    gridToolbar[1, 1] = frameToolbar

    ################################################################################
    # Notebook
    ################################################################################
    # newNotebook
    global nb = Notebook()
    set_gtk_property!(nb, :tab_pos, 0)
    set_gtk_property!(nb, :height_request, h*.75 - (h*.75)*0.09 - (h*.75)*0.07)
    screen = Gtk.GAccessor.style_context(nb)
    push!(screen, StyleProvider(provider), 600)

    # Drawing
    nbFrame0 = Frame()
    screen = Gtk.GAccessor.style_context(nbFrame0)
    push!(screen, StyleProvider(provider), 600)

    gDraw = Grid()
    set_gtk_property!(gDraw, :margin_top, 20)
    set_gtk_property!(gDraw, :margin_bottom, 20)
    set_gtk_property!(gDraw, :margin_left, 20)
    set_gtk_property!(gDraw, :margin_right, 20)
    set_gtk_property!(gDraw, :valign, 3)
    set_gtk_property!(gDraw, :halign, 3)
    set_gtk_property!(gDraw, :column_spacing, 20)
    set_gtk_property!(gDraw, :row_spacing, 20)

    smilesEntry = Entry()
    set_gtk_property!(smilesEntry, :width_request, round(w*.22))

    imgSVG = Gtk.Image()

    runsmiles = Button("Draw")
    set_gtk_property!(runsmiles, :name, "runsmiles")
    set_gtk_property!(runsmiles, :width_request, round(w*.08))
    screen = Gtk.GAccessor.style_context(runsmiles)
    push!(screen, StyleProvider(provider), 600)

    signal_connect(runsmiles, :clicked) do widget
        global filename_in
        global filename_out

        smilesString = get_gtk_property(smilesEntry, :text, String)

        # Convert String to mol
        mol = MG.smilestomol(smilesString)

        # Convert mol to a string of svg format
        mol_svg = MG.drawsvg(mol, Int(round(h*.45)), Int(round(h*.45)))

        # Export svg file
        open(filename_in, "w") do io
            write(io, mol_svg)
        end

        # Code needed to convert SVG to PNG
        r = Rsvg.handle_new_from_file(filename_in)
        d = Rsvg.handle_get_dimensions(r)
        cs = Cairo.CairoImageSurface(d.width,d.height,Cairo.FORMAT_ARGB32)
        c = Cairo.CairoContext(cs)
        Rsvg.handle_render_cairo(c,r)
        Cairo.write_to_png(cs,filename_out)

        # Assing png file to Gtk.Image
        set_gtk_property!(imgSVG, :file, filename_out)

        Gtk.showall(winOSPropE)
    end

    smilesFrame = Frame()
    set_gtk_property!(smilesFrame, :name, "smileFrame")
    set_gtk_property!(smilesFrame, :height_request, round(h*.45))
    screen = Gtk.GAccessor.style_context(smilesFrame)
    push!(screen, StyleProvider(provider), 600)

    push!(smilesFrame, imgSVG)

    gDraw[1, 1] = smilesEntry
    gDraw[2, 1] = runsmiles
    gDraw[1:2, 2] = smilesFrame


    push!(nbFrame0, gDraw)
    push!(nb, nbFrame0, "  Drawing  ")

    # Resuls
    nbFrame1 = Frame()
    screen = Gtk.GAccessor.style_context(nbFrame1)
    push!(screen, StyleProvider(provider), 600)
    push!(nb, nbFrame1, "  Results  ")

    gridToolbar[1, 2] = nb

    ################################################################################
    # Acknowledgment
    ################################################################################
    gLabel = Grid()
    set_gtk_property!(gLabel, :halign, 3)
    #set_gtk_property!(gLabel, :halign, 3)
    set_gtk_property!(gLabel, :margin_top, 20)
    #set_gtk_property!(gLabel, :margin_bottom, 20)
    set_gtk_property!(gLabel, :margin_left, 20)
    set_gtk_property!(gLabel, :margin_right, 20)
    set_gtk_property!(gLabel, :height_request, (h*.75)*.07)

    newLabel = Label("Designed at Instituto Tecnológico de Celaya/México - 2020
    Support granted by the Conacyt-Secretaría de Energía-Hidrocarburos sectorial fund")
    Gtk.GAccessor.justify(newLabel, Gtk.GConstants.GtkJustification.CENTER)
    screen = Gtk.GAccessor.style_context(newLabel)
    push!(screen, StyleProvider(provider), 600)

    gLabel[1, 1] = newLabel
    gridToolbar[1, 3] = gLabel


    push!(winOSPropE, gridToolbar)

    Gtk.showall(winOSPropE)
    set_gtk_property!(winOSPropE, :visible, true)
end
