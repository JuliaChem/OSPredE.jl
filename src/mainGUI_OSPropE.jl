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
    global pathPUREDIPPR =
        joinpath(dirname(Base.source_path()), "database\\PUREDIPPR.csv")
    global filename_in =
        joinpath(dirname(Base.source_path()), "img\\molsvg.svg")
    global filename_out =
        joinpath(dirname(Base.source_path()), "img\\molpng.png")
    imgpath = joinpath(dirname(Base.source_path()), "img")
    global filename_in2 =
        joinpath(dirname(Base.source_path()), "img\\molsvg2.svg")
    global filename_out2 =
        joinpath(dirname(Base.source_path()), "img\\molpng2.png")
    imgpath = joinpath(dirname(Base.source_path()), "img")

    try
        rm(imgpath, recursive = true)
    catch
        Nothing
    end

    try
        mkdir(imgpath)
    catch
        Nothing
    end
end

if Sys.islinux()
    global pathPUREDIPPR =
        joinpath(dirname(Base.source_path()), "database/PUREDIPPR.csv")
    global filename_in = joinpath(dirname(Base.source_path()), "img/molsvg.svg")
    global filename_out =
        joinpath(dirname(Base.source_path()), "img/molpng.png")
    global filename_in2 =
        joinpath(dirname(Base.source_path()), "img/molsvg2.svg")
    global filename_out2 =
        joinpath(dirname(Base.source_path()), "img/molpng2.png")

    # Delete image file to avoid problems (linux)
    imgpath = joinpath(dirname(Base.source_path()), "img")

    try
        rm(imgpath, recursive = true)
    catch
        Nothing
    end

    try
        mkdir(imgpath)
    catch
        Nothing
    end
end

# Load default database
#@async global databaseDIPPR = CSV.read(pathPUREDIPPR)

# Main function
function OSPropEGUI()
    # Suppress warnings
    #@suppress begin

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
    set_gtk_property!(winOSPropE, :width_request, w * 0.50)
    set_gtk_property!(winOSPropE, :height_request, h * 0.75)
    set_gtk_property!(winOSPropE, :visible, false)

    ################################################################################
    # Toolbar
    ################################################################################
    # Menu Icons
    tb1 = ToolButton("gtk-new")
    set_gtk_property!(tb1, :label, "New")
    set_gtk_property!(tb1, :tooltip_markup, "New analysis")
    signal_connect(tb1, :clicked) do widget
        empty!(imgSVG)
        set_gtk_property!(smilesEntry, :text, "")
        set_gtk_property!(tb6, :sensitive, false)

    end

    tb2 = ToolButton("gtk-floppy")
    set_gtk_property!(tb2, :label, "Export")
    set_gtk_property!(tb2, :tooltip_markup, "Export to .pdf")
    set_gtk_property!(tb2, :sensitive, false)

    # Close toolbar
    tb3 = ToolButton("gtk-close")
    set_gtk_property!(tb3, :label, "Close")
    set_gtk_property!(tb3, :tooltip_markup, "Close")

    signal_connect(tb3, :clicked) do widget
        destroy(winOSPropE)
    end

    signal_connect(winOSPropE, "key-press-event") do widget, event
        if event.keyval == 65307
            destroy(newWin)
        end
    end

    tb4 = ToolButton("gtk-preferences")
    set_gtk_property!(tb4, :label, "Tools")
    set_gtk_property!(tb4, :tooltip_markup, "Tools")

    tb5 = ToolButton("gtk-about")
    set_gtk_property!(tb5, :label, "Help")
    set_gtk_property!(tb5, :tooltip_markup, "Help")

    tb6 = ToolButton("gtk-media-play")
    set_gtk_property!(tb6, :label, "Run")
    set_gtk_property!(tb6, :tooltip_markup, "Compute properties")
    set_gtk_property!(tb6, :sensitive, false)
    signal_connect(tb6, :clicked) do widget
        global mol, filename_out2, filename_in2, listFG

        try
            global listFG
            canvas = MG.SvgCanvas()
            MG.draw2d!(canvas, mol)
            MG.drawatomindex!(canvas, mol)
            mol_svg2 =
                MG.tosvg(canvas, Int(round(h * 0.28)), Int(round(h * 0.28)))

            # Export svg file
            open(filename_in2, "w") do io
                write(io, mol_svg2)
            end

            # Code needed to convert SVG to PNG
            r = Rsvg.handle_new_from_file(filename_in2)
            d = Rsvg.handle_get_dimensions(r)
            cs = Cairo.CairoImageSurface(d.width, d.height, Cairo.FORMAT_ARGB32)
            c = Cairo.CairoContext(cs)
            Rsvg.handle_render_cairo(c, r)
            Cairo.write_to_png(cs, filename_out2)

            set_gtk_property!(imgAtomIndex, :file, filename_out2)
            Gtk.Showall(winOSPropE)

            fg = MG.functionalgroupgraph(mol)
            global funcgroups =
                DF.DataFrame(Group = String[], Counts = Int[], Sets = String[])

            for (term, components) in fg.componentmap
                nodes = [sort(collect(comp)) for comp in components]
                push!(
                    funcgroups,
                    (string(term), length(collect(nodes)), string(nodes...)),
                )
            end

            println(1)
            for i = 1:size(funcgroups)[1]
                println(i)
                push!(
                    listFG,
                    (
                     funcgroups[i, 1],
                     funcgroups[i, 2],
                     funcgroups[i, 3],
                    ),
                )
            end
        catch
            Nothing
        end
        set_gtk_property!(nb, :page, 1)
    end


    # Toolbar
    newToolbar = Toolbar()
    set_gtk_property!(newToolbar, :height_request, (h * 0.75) * 0.09)
    set_gtk_property!(newToolbar, :toolbar_style, 2)
    push!(newToolbar, tb1)
    push!(newToolbar, tb2)
    push!(newToolbar, tb3)
    push!(newToolbar, tb4)
    push!(newToolbar, tb5)
    push!(newToolbar, tb6)

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
    set_gtk_property!(
        nb,
        :height_request,
        h * 0.75 - (h * 0.75) * 0.09 - (h * 0.75) * 0.07,
    )
    set_gtk_property!(nb, :name, "nb")
    screen = Gtk.GAccessor.style_context(nb)
    push!(screen, StyleProvider(provider), 600)

    ################################################################################
    # Drawing Smiles
    ################################################################################
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

    labelSmile = Label("Smile: ")
    smilesEntry = Entry()
    set_gtk_property!(smilesEntry, :width_request, round(w * 0.22))

    imgSVG = Gtk.Image()

    runsmiles = Button("Draw")
    set_gtk_property!(runsmiles, :name, "runsmiles")
    set_gtk_property!(runsmiles, :width_request, round(w * 0.08))

    signal_connect(runsmiles, :clicked) do widget
        global nb
        try
            smilesString = get_gtk_property(smilesEntry, :text, String)

            # Convert String to mol
            global mol = MG.smilestomol(smilesString)

            # Convert mol to a string of svg format
            mol_svg =
                MG.drawsvg(mol, Int(round(h * 0.40)), Int(round(h * 0.40)))

            # Export svg file
            open(filename_in, "w") do io
                write(io, mol_svg)
            end

            # Code needed to convert SVG to PNG
            r = Rsvg.handle_new_from_file(filename_in)
            d = Rsvg.handle_get_dimensions(r)
            cs = Cairo.CairoImageSurface(d.width, d.height, Cairo.FORMAT_ARGB32)
            c = Cairo.CairoContext(cs)
            Rsvg.handle_render_cairo(c, r)
            Cairo.write_to_png(cs, filename_out)

            # Assing png file to Gtk.Image
            set_gtk_property!(imgSVG, :file, filename_out)
            Gtk.showall(winOSPropE)

            set_gtk_property!(tb6, :sensitive, true)
            global status = 1
        catch
            Nothing
        end
    end

    ################################################################################
    # Buttons for smiles
    ################################################################################
    gDrawB = Grid()
    set_gtk_property!(gDrawB, :valign, 3)
    set_gtk_property!(gDrawB, :halign, 3)
    set_gtk_property!(gDrawB, :column_spacing, 20)
    set_gtk_property!(gDrawB, :row_spacing, 20)
    set_gtk_property!(gDrawB, :column_homogeneous, true)
    set_gtk_property!(gDrawB, :row_homogeneous, true)

    doublebond = Button("=")
    set_gtk_property!(doublebond, :width_request, round(w * 0.078))
    signal_connect(doublebond, :clicked) do widget
        smiletext = get_gtk_property(smilesEntry, :text, String)
        set_gtk_property!(smilesEntry, :text, string(smiletext, "="))
    end

    triplebond = Button("≡")
    signal_connect(triplebond, :clicked) do widget
        smiletext = get_gtk_property(smilesEntry, :text, String)
        set_gtk_property!(smilesEntry, :text, string(smiletext, "#"))
    end

    alkane = Button("C-C")
    alkene = Button("C=C")
    alkine = Button("C≡C")
    ring = Button("O")
    signal_connect(ring, :clicked) do widget
        smiletext = get_gtk_property(smilesEntry, :text, String)
        set_gtk_property!(smilesEntry, :text, string(smiletext, "C1CCCCC1"))
    end

    clear = Button("Clear")
    signal_connect(clear, :clicked) do widget
        empty!(imgSVG)
        set_gtk_property!(smilesEntry, :text, "")
        set_gtk_property!(tb6, :sensitive, false)
    end

    expFig = Button("Export")

    smilesFrame = Frame()
    set_gtk_property!(smilesFrame, :height_request, round(h * 0.40))
    screen = Gtk.GAccessor.style_context(smilesFrame)
    push!(screen, StyleProvider(provider), 600)

    push!(smilesFrame, imgSVG)

    gDrawB[1, 1] = doublebond
    gDrawB[2, 1] = triplebond
    gDrawB[3, 1] = alkane
    gDrawB[4, 1] = clear

    gDrawB[1, 2] = alkene
    gDrawB[2, 2] = alkine
    gDrawB[3, 2] = ring
    gDrawB[4, 2] = expFig

    gDraw[1, 1] = labelSmile
    gDraw[2, 1] = smilesEntry
    gDraw[3, 1] = runsmiles
    gDraw[1:3, 2] = smilesFrame
    gDraw[1:3, 3] = gDrawB


    push!(nbFrame0, gDraw)
    push!(nb, nbFrame0, "  Drawing  ")

    ################################################################################
    # Resuls
    ################################################################################
    nbFrame1 = Frame()
    screen = Gtk.GAccessor.style_context(nbFrame1)
    push!(screen, StyleProvider(provider), 600)

    # Notebook for nbResults
    global nbRes = Notebook()
    set_gtk_property!(nbRes, :tab_pos, 3)
    set_gtk_property!(nbRes, :name, "nbRes")
    screen = Gtk.GAccessor.style_context(nbRes)
    push!(screen, StyleProvider(provider), 600)
    #set_gtk_property!(nbRes, :height_request, h*.75 - (h*.75)*0.09 - (h*.75)*0.07)

    # Summary
    nbResFrame0 = Frame()
    screen = Gtk.GAccessor.style_context(nbResFrame0)
    push!(screen, StyleProvider(provider), 600)

    gSumm = Grid()
    set_gtk_property!(gSumm, :margin_top, 20)
    set_gtk_property!(gSumm, :margin_bottom, 20)
    set_gtk_property!(gSumm, :margin_left, 20)
    set_gtk_property!(gSumm, :margin_right, 20)
    set_gtk_property!(gSumm, :valign, 3)
    set_gtk_property!(gSumm, :halign, 3)
    set_gtk_property!(gSumm, :column_spacing, 20)
    set_gtk_property!(gSumm, :row_spacing, 20)

    molFrame = Frame("Molecule")
    set_gtk_property!(molFrame, :label_xalign, 0.50)
    set_gtk_property!(molFrame, :height_request, round(h * 0.28))
    set_gtk_property!(molFrame, :width_request, round(h * 0.32))
    screen = Gtk.GAccessor.style_context(molFrame)
    push!(screen, StyleProvider(provider), 600)

    imgAtomIndex = Gtk.Image()

    push!(molFrame, imgAtomIndex)

    global fgFrame = Frame("Functional Groups")
    set_gtk_property!(fgFrame, :label_xalign, 0.50)
    set_gtk_property!(fgFrame, :height_request, round(h * 0.28))
    set_gtk_property!(fgFrame, :width_request, round(h * 0.32))
    screen = Gtk.GAccessor.style_context(fgFrame)
    push!(screen, StyleProvider(provider), 600)

    # GtkListStore where the data is actually saved
    global listFG = ListStore(
        String,
        Float64,
        String
    )

    # Gtk TreeView to show the graphical element
    global viewFG = TreeView(TreeModel(listFG))
    set_gtk_property!(viewFG, :enable_grid_lines, 3)
    set_gtk_property!(viewFG, :enable_search, true)

    # Window that allow scroll the TreeView
    scrollFG = ScrolledWindow(viewFG)
    #set_gtk_property!(scrollFG, :width_request, 750)
    #set_gtk_property!(scrollFG, :height_request, 250)
    selection1 = Gtk.GAccessor.selection(viewFG)

    # Column definitions
    cTxt1 = CellRendererText()

    c11 = TreeViewColumn("FG", cTxt1, Dict([("text", 0)]))
    c12 = TreeViewColumn("Count", cTxt1, Dict([("text", 1)]))
    c13 = TreeViewColumn("Index", cTxt1, Dict([("text", 2)]))

    # Add column to TreeView
    push!(viewFG, c11, c12, c13)

    push!(fgFrame, scrollFG)

    propFrame = Frame("Properties Estimated")
    set_gtk_property!(propFrame, :label_xalign, 0.50)
    set_gtk_property!(propFrame, :height_request, round(h * 0.20))
    set_gtk_property!(propFrame, :width_request, round(h * 0.32))
    screen = Gtk.GAccessor.style_context(propFrame)
    push!(screen, StyleProvider(provider), 600)

    gSumm[1, 1] = molFrame
    gSumm[2, 1] = fgFrame
    gSumm[1:2, 2] = propFrame

    push!(nbResFrame0, gSumm)

    # Marrero & Gani
    nbResFrame1 = Frame()
    screen = Gtk.GAccessor.style_context(nbResFrame1)
    push!(screen, StyleProvider(provider), 600)

    # Sánchez & Jímenez
    nbResFrame2 = Frame()
    screen = Gtk.GAccessor.style_context(nbResFrame2)
    push!(screen, StyleProvider(provider), 600)

    push!(nbRes, nbResFrame0, "  Summary  ")
    push!(nbRes, nbResFrame1, "  Marrero & Gani  ")
    push!(nbRes, nbResFrame2, "  Jimenez & Sánchez  ")

    push!(nbFrame1, nbRes)
    push!(nb, nbFrame1, "  Results  ")

    # Frame for main notebook
    nbFrame = Frame()
    screen = Gtk.GAccessor.style_context(nbFrame)
    push!(screen, StyleProvider(provider), 600)

    push!(nbFrame, nb)
    gridToolbar[1, 2] = nbFrame

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
    set_gtk_property!(gLabel, :height_request, (h * 0.75) * 0.07)

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
