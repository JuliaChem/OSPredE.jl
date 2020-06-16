# OSPropE
# Instituto Tecnológico de Celaya/TecNM - México 2020
# Sánchez-Sánchez Kelvyn Baruc
# Jímenez-Gutierrez Arturo
# CONACyT-SENER-Hidrocarburos

using Gtk, Gtk.ShortNames, JLD, Suppressor, CSV, Mustache, Dates, Rsvg, Cairo
using DefaultApplication
import DataFrames, MolecularGraph

# Aliasing for shortname
const MG = MolecularGraph
const DF = DataFrames

# Path to CSS Gtk-Style dataFile
global style_file = joinpath(dirname(Base.source_path()), "style2020.css")

# General Settings
if Sys.iswindows()
    # DIPPR Database path
    global pathPUREDIPPR =
        joinpath(dirname(Base.source_path()), "database\\PUREDIPPR.csv")

    # Path for images generated
    global filename_in = "C:\\Windows\\Temp\\molsvg.svg"
    global filename_out = "C:\\Windows\\Temp\\molpng.png"
    global filename_in2 = "C:\\Windows\\Temp\\molsvg2.svg"
    global filename_out2 = "C:\\Windows\\Temp\\molpng2.png"

    # MG Database for functional groups
    global MG_FirstOrder_Method1 =
    joinpath(dirname(Base.source_path()), "FGdatabase\\HukkerikarDatabaseM1G1.csv")

    global MG_SecondOrder_Method1 =
    joinpath(dirname(Base.source_path()), "FGdatabase\\HukkerikarDatabaseM1G2.csv")

    global MG_ThirdOrder_Method1 =
    joinpath(dirname(Base.source_path()), "FGdatabase\\HukkerikarDatabaseM1G3.csv")

    global Joback_Database =
    joinpath(dirname(Base.source_path()), "FGdatabase\\JobackDatabase.csv")

    # Icons path
    global ico1 = joinpath(dirname(Base.source_path()), "icons\\icon_new.ico")
    global ico2 = joinpath(dirname(Base.source_path()), "icons\\icon_pdf.ico")
    global ico3 = joinpath(dirname(Base.source_path()), "icons\\icon_close.ico")
    global ico4 = joinpath(dirname(Base.source_path()), "icons\\icon_settings.ico")
    global ico5 = joinpath(dirname(Base.source_path()), "icons\\icon_help.ico")
end

if Sys.islinux()
    global pathPUREDIPPR =
        joinpath(dirname(Base.source_path()), "database/PUREDIPPR.csv")
    global filename_in = "/temp/molsvg.svg"
    global filename_out = "/temp/molpng.png"
    global filename_in2 = "/temp/molsvg2.svg"
    global filename_out2 = "/temp/molpng2.png"

    # MG Database for functional groups
    global MG_FirstOrder_Method1 =
    joinpath(dirname(Base.source_path()), "FGdatabase/HukkerikarDatabaseM1G1.csv")

    global MG_SecondOrder_Method1 =
    joinpath(dirname(Base.source_path()), "FGdatabase/HukkerikarDatabaseM1G2.csv")

    global MG_ThirdOrder_Method1 =
    joinpath(dirname(Base.source_path()), "FGdatabase/HukkerikarDatabaseM1G3.csv")

    global Joback_Database =
    joinpath(dirname(Base.source_path()), "FGdatabase/JobackDatabase.csv")
    # Icons path
    global ico1 = joinpath(dirname(Base.source_path()), "icons/icon_new.ico")
    global ico2 = joinpath(dirname(Base.source_path()), "icons/icon_pdf.ico")
    global ico3 = joinpath(dirname(Base.source_path()), "icons/icon_close.ico")
    global ico4 = joinpath(dirname(Base.source_path()), "icons/icon_settings.ico")
    global ico5 = joinpath(dirname(Base.source_path()), "icons/icon_help.ico")
end

# Loading functional groups
MG_FirstOrder_Method1 = CSV.read(MG_FirstOrder_Method1, header=false);
MG_SecondOrder_Method1 = CSV.read(MG_SecondOrder_Method1, header=false);
MG_ThirdOrder_Method1 = CSV.read(MG_ThirdOrder_Method1, header=false);
JobackDatabase = CSV.read(Joback_Database, header=false);

# Load default database
databaseDIPPR = CSV.read(pathPUREDIPPR)

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
    tb1 = ToolButton("")
    itb1 = Image()
    set_gtk_property!(itb1, :file, ico1)
    set_gtk_property!(tb1, :icon_widget, itb1)
    set_gtk_property!(tb1, :label, "New")
    set_gtk_property!(tb1, :tooltip_markup, "New analysis")
    signal_connect(tb1, :clicked) do widget
        set_gtk_property!(smilesEntry, :text, "")
        set_gtk_property!(tb6, :sensitive, false)
        set_gtk_property!(tb2, :sensitive, false)
        empty!(listFGHukkerikar1)
        empty!(listFGHukkerikar2)
        empty!(listFGHukkerikar3)
        empty!(listPropHukkerikar)
        empty!(imgSVG)
        empty!(imgAtomIndex)
        empty!(imgAtomIndex)
        set_gtk_property!(nb, :page, 0)
    end

    # pdf report
    tb2 = ToolButton("")
    itb2 = Image()
    set_gtk_property!(itb2, :file, ico2)
    signal_connect(tb2, :clicked) do widget
        global Lili = save_dialog_native("Save as...", Null(), ("*.pdf",))
        global FirstOrderGroups, SecondOrderGroups, PropHuk

        if ~isempty(Lili)
            # Time for report
            timenow = Dates.now()
            timenow1 = Dates.format(timenow, "dd u yyyy HH:MM:SS")

            if Sys.iswindows()

                # Headers for dataframes

                fmtH1 = string("|",repeat("c|", size(FirstOrderGroups,2)))
                headerH1 = join(string.(names(FirstOrderGroups)), " & ")
                rowH1 = join(["{{:$x}}" for x in map(string, names(FirstOrderGroups))], " & ")

                fmtH2 = string("|",repeat("c|", size(SecondOrderGroups,2)))
                headerH2 = join(string.(names(SecondOrderGroups)), " & ")
                rowH2 = join(["{{:$x}}" for x in map(string, names(SecondOrderGroups))], " & ")

                fmtPropH = string("|",repeat("c|", size(PropHuk,2)))
                headerPropH = join(string.(names(PropHuk)), " & ")
                rowPropH = join(["{{:$x}}" for x in map(string, names(PropHuk))], " & ")

                LSNS = """
                \\documentclass{article}
                \\usepackage{graphicx}
                \\graphicspath{ {C:/Windows/Temp/} }
                \\usepackage[letterpaper, portrait, margin=1in]{geometry}
                \\begin{document}
                \\begin{center}
                \\Huge{\\textbf{OSPropE}}\\\\
                \\vspace{2mm}
                \\large{\\textbf{Properties Estimation Report}}\\break
                \\normalsize{{:time}}\n
                \\vspace{5mm}
                \\rule{15cm}{0.05cm}\n\n\n
                \\vspace{2mm}
                \\includegraphics[width=9cm, height=8cm]{molpng}\n
                \\normalsize{Figure 1. Molecule}\n
                \\vspace{2mm}
                \\includegraphics[width=9cm, height=8cm]{molpng2}\n
                \\normalsize{Figure 2. Molecule with atoms indicated}\n
                \\vspace{3mm}\n
                \\rule{15cm}{0.05cm}\n
                \\pagebreak

                \\large{\\textbf{Hukkerikar's Method (2012)}}\\break
                \\vspace{5mm}
                \\rule{15cm}{0.05cm}\n\n\n
                \\vspace{2mm}
                \\normalsize{Table 1. Functional Groups of First Order}\n
                \\vspace{2mm}
                \\begin{tabular}{$fmtH1}
                \\hline
                $headerH1\\\\
                \\hline
                {{#:FGH1}} $rowH1\\cr
                {{/:FGH1}}
                \\hline\n
                \\end{tabular}

                \\vspace{5mm}\n
                \\normalsize{Table 2. Functional Groups of Second Order}\n
                \\vspace{2mm}
                \\begin{tabular}{$fmtH2}
                \\hline
                $headerH2\\\\
                \\hline
                {{#:FGH2}} $rowH2\\cr
                {{/:FGH2}}
                \\hline\n
                \\end{tabular}

                \\vspace{5mm}\n
                \\normalsize{Table 3. Thermodynamic properties estimated}\n
                \\vspace{2mm}
                \\begin{tabular}{$fmtPropH}
                \\hline
                $headerPropH\\\\
                \\hline
                {{#:PropH}} $rowPropH\\cr
                {{/:PropH}}
                \\hline\n
                \\end{tabular}
                \\vspace{3mm}\n
                \\end{center}
                \\end{document}
                """

                rendered = render(LSNS, time = timenow1, FGH1 = FirstOrderGroups,
                FGH2 = SecondOrderGroups, PropH = PropHuk)

                fileNameBase = string(basename(Lili), ".tex")
                fileName = string("C:\\Windows\\Temp\\", fileNameBase)
                Base.open(fileName, "w") do file
                    write(file, rendered)
                end
                run(`pdflatex -output-directory="C:\\Windows\\Temp\\" $(fileNameBase)`)

                pdfName = string(Lili, ".pdf")
                fileNameBase = string(basename(Lili), ".pdf")
                fileName = string("C:\\Windows\\Temp\\", fileNameBase)
                cp(fileName, string(Lili, ".pdf"); force=true)
                DefaultApplication.open(pdfName)
            end

            if Sys.islinux()
                warn_dialog("Export as .pdf is not currently implemented on Linux Operating System", winOSPropE)
            end
        end
    end

    set_gtk_property!(tb2, :icon_widget, itb2)
    set_gtk_property!(tb2, :label, "Export")
    set_gtk_property!(tb2, :tooltip_markup, "Export to .pdf")
    set_gtk_property!(tb2, :sensitive, false)

    # Close toolbar
    tb3 = ToolButton("")
    itb3 = Image()
    set_gtk_property!(itb3, :file, ico3)
    set_gtk_property!(tb3, :icon_widget, itb3)
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

    tb4 = ToolButton("")
    itb4 = Image()
    set_gtk_property!(itb4, :file, ico4)
    set_gtk_property!(tb4, :icon_widget, itb4)
    set_gtk_property!(tb4, :label, "Tools")
    set_gtk_property!(tb4, :tooltip_markup, "Tools")

    tb5 = ToolButton("")
    itb5 = Image()
    set_gtk_property!(itb5, :file, ico5)
    set_gtk_property!(tb5, :icon_widget, itb5)
    set_gtk_property!(tb5, :label, "Help")
    set_gtk_property!(tb5, :tooltip_markup, "Help")

    tb6 = ToolButton("gtk-media-play")
    set_gtk_property!(tb6, :label, "Run")
    set_gtk_property!(tb6, :tooltip_markup, "Compute properties")
    set_gtk_property!(tb6, :sensitive, false)
    signal_connect(tb6, :clicked) do widget
        global mol, filename_out2, filename_in2, listFG
        global MG_FirstOrder_Method1
        global MG_SecondOrder_Method1
        global MG_ThirdOrder_Method1
        global JobackDatabase

        ########################################################################
        # Hukkerikar
        try
            global listFGHukkerikar1
            global listFGHukkerikar2
            global listFGHukkerikar3
            global listPropHukkerikar

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

            # Functional Groups Analysis
            fg = MG.functionalgroupgraph(mol, "Hukkerikar")
            global funcgroups =
                DF.DataFrame(Group = String[], Counts = Int[], Sets = String[])

            for (term, components) in fg.componentmap
                nodes = [sort(collect(comp)) for comp in components]
                push!(
                funcgroups,
                (string(term), length(collect(nodes)), string(nodes...)),
                )
            end

            # Size for list of FG First-Order
            rowsFirstOrder = size(MG_FirstOrder_Method1)[1]

            # Size for list of FG First-Order
            rowsSecondOrder = size(MG_SecondOrder_Method1)[1]

            # Size for list of FG First-Order
            rowsThirdOrder = size(MG_ThirdOrder_Method1)[1]

            rowsFG = size(funcgroups)[1]

            countsFirstOrder = Array{Int64}(undef, rowsFirstOrder, rowsFG)
            countsSecondOrder = Array{Int64}(undef, rowsSecondOrder, rowsFG)
            countsThirdOrder = Array{Int64}(undef, rowsThirdOrder, rowsFG)

            # Extracting equalities for FirstOrder
            global FirstOrderGroups = DF.DataFrame(Group = String[], Times = Int[], Sets = String[])

            for i=1:rowsFirstOrder
                for j=1:rowsFG
                    countsFirstOrder[i,j] = convert(Int64, funcgroups[j,1] == MG_FirstOrder_Method1[i,1])

                    if countsFirstOrder[i,j] == 1
                        push!(FirstOrderGroups, (funcgroups[j,1], funcgroups[j,2], funcgroups[j,3]))
                    end
                end
            end

            # Extracting equalities for SecondOrder
            global SecondOrderGroups = DF.DataFrame(Group = String[], Times = Int[], Sets = String[])

            for i=1:rowsSecondOrder
                for j=1:rowsFG
                    countsSecondOrder[i,j] = convert(Int64, funcgroups[j,1] == MG_SecondOrder_Method1[i,1])

                    if countsSecondOrder[i,j] == 1
                        push!(SecondOrderGroups, (funcgroups[j,1], funcgroups[j,2], funcgroups[j,3]))
                    end
                end
            end

            for i = 1:size(FirstOrderGroups)[1]
                push!(
                listFGHukkerikar1,
                (FirstOrderGroups[i, 1], FirstOrderGroups[i, 2], FirstOrderGroups[i, 3]),
                )
            end

            for i = 1:size(SecondOrderGroups)[1]
                push!(
                listFGHukkerikar2,
                (SecondOrderGroups[i, 1], SecondOrderGroups[i, 2], SecondOrderGroups[i, 3]),
                )
            end

            # Compute properties for Hukkerikar
            global PropHuk = DF.DataFrame(Property = String[], Value = Float64[])
            # MW
            MW =  MG.standardweight(mol)[1]
            push!(listPropHukkerikar, ("Mw (g/mol)", MW))
            push!(PropHuk, ("Mw", MW))

            # Normal boiling point [K]
            Tb0 = 244.5165
            Tb =
            Tb0 * log(
            sum(
            (countsFirstOrder[:, :] .* MG_FirstOrder_Method1[:, 2]) *
            funcgroups[:, 2],
            ) + sum(
            (countsSecondOrder[:, :] .* MG_SecondOrder_Method1[:, 2]) *
            funcgroups[:, 2],
            ),
            )
            push!(listPropHukkerikar, ("Tb (K)", Tb))
            push!(PropHuk, ("Tb", Tb))

            # Critical temperature [K]
            Tc0 = 181.6716
            Tc =
            Tc0 * log(
            sum(
            (countsFirstOrder[:, :] .* MG_FirstOrder_Method1[:, 3]) *
            funcgroups[:, 2],
            ) + sum(
            (countsSecondOrder[:, :] .* MG_SecondOrder_Method1[:, 3]) *
            funcgroups[:, 2],
            ),
            )
            push!(listPropHukkerikar, ("Tc (K)", Tc))
            push!(PropHuk, ("Tc", Tc))

            # Critical pressure [bar]
            Pc1 = 0.0519
            Pc2 = 0.1347
            Pc =
            Pc1 +
            1 /
            (
            Pc2 +
            sum(
            (countsFirstOrder[:, :] .* MG_FirstOrder_Method1[:, 4]) *
            funcgroups[:, 2],
            ) +
            sum(
            (countsSecondOrder[:, :] .* MG_SecondOrder_Method1[:, 4]) *
            funcgroups[:, 2],
            )
            )^2
            push!(listPropHukkerikar, ("Pc bar", Pc))
            push!(PropHuk, ("Pc", Pc))

            # Critical volume [cc/mol]
            Vc0 = 28.0018
            Vc =
            Vc0 +
            sum(
            (countsFirstOrder[:, :] .* MG_FirstOrder_Method1[:, 5]) *
            funcgroups[:, 2],
            ) +
            sum(
            (countsSecondOrder[:, :] .* MG_SecondOrder_Method1[:, 5]) *
            funcgroups[:, 2],
            )
            push!(listPropHukkerikar, ("Vc (cc/mol)", Vc))
            push!(PropHuk, ("Vc", Vc))

            # Normal melting point [K]
            Tm0 = 143.5706
            Tm =
            Tm0 * log(
            sum(
            (countsFirstOrder[:, :] .* MG_FirstOrder_Method1[:, 6]) *
            funcgroups[:, 2],
            ) + sum(
            (countsSecondOrder[:, :] .* MG_SecondOrder_Method1[:, 6]) *
            funcgroups[:, 2],
            ),
            )
            push!(listPropHukkerikar, ("Tm (K)", Tm))
            push!(PropHuk, ("Tm", Tm))

            # Gibbs free energy [kJ/mol]
            Gf0 = -1.3385
            Gf =
            Gf0 +
            sum(
            (countsFirstOrder[:, :] .* MG_FirstOrder_Method1[:, 7]) *
            funcgroups[:, 2],
            ) +
            sum(
            (countsSecondOrder[:, :] .* MG_SecondOrder_Method1[:, 7]) *
            funcgroups[:, 2],
            )
            push!(listPropHukkerikar, ("Gf[298 K] (kJ/mol)", Gf))
            push!(PropHuk, ("Gf[298 K]", Gf))

            # Enthalpy of formation [kJ/mol]
            Hf0 = 35.1778
            Hf =
            Hf0 +
            sum(
            (countsFirstOrder[:, :] .* MG_FirstOrder_Method1[:, 8]) *
            funcgroups[:, 2],
            ) +
            sum(
            (countsSecondOrder[:, :] .* MG_SecondOrder_Method1[:, 8]) *
            funcgroups[:, 2],
            )
            push!(listPropHukkerikar, ("Hf[298 K] (kJ/mol)", Hf))
            push!(PropHuk, ("Hf[298 K]", Hf))

            # Enthalpy of fusion [kJ/mol]
            Hfus0 = -1.7795
            Hfus =
            Hfus0 +
            sum(
            (countsFirstOrder[:, :] .* MG_FirstOrder_Method1[:, 9]) *
            funcgroups[:, 2],
            ) +
            sum(
            (countsSecondOrder[:, :] .* MG_SecondOrder_Method1[:, 9]) *
            funcgroups[:, 2],
            )
            push!(listPropHukkerikar, ("Hfus (kJ/mol)", Hfus))
            push!(PropHuk, ("Hfus", Hfus))

            # Octanol/Water partition coefficient
            LogKow0 = 0.4876
            LogKow =
            LogKow0 +
            sum(
            (countsFirstOrder[:, :] .* MG_FirstOrder_Method1[:, 10]) *
            funcgroups[:, 2],
            ) +
            sum(
            (countsSecondOrder[:, :] .* MG_SecondOrder_Method1[:, 10]) *
            funcgroups[:, 2],
            )
            push!(listPropHukkerikar, ("Log(Kow)", LogKow))
            push!(PropHuk, ("Log(Kow)", LogKow))

            # Flash point [K]
            Fp0 = 170.7058
            Fp =
            Fp0 +
            sum(
            (countsFirstOrder[:, :] .* MG_FirstOrder_Method1[:, 11]) *
            funcgroups[:, 2],
            ) +
            sum(
            (countsSecondOrder[:, :] .* MG_SecondOrder_Method1[:, 11]) *
            funcgroups[:, 2],
            )
            push!(listPropHukkerikar, ("Fp (K)", Fp))
            push!(PropHuk, ("Fp", Fp))

            # Enthalpy of vaporization (298 K) [kJ/mol]
            Hv0 = 10.4327
            Hv =
            Hv0 +
            sum(
            (countsFirstOrder[:, :] .* MG_FirstOrder_Method1[:, 12]) *
            funcgroups[:, 2],
            ) +
            sum(
            (countsSecondOrder[:, :] .* MG_SecondOrder_Method1[:, 12]) *
            funcgroups[:, 2],
            )
            push!(listPropHukkerikar, ("Hv[298 K] (kJ/mol)", Hv))
            push!(PropHuk, ("Hv[298 K]", Hv))

            # Enthalpy of vaporization (Tb) [kJ/mol]
            Hvb0 = 15.4199
            Hvb =
            Hvb0 +
            sum(
            (countsFirstOrder[:, :] .* MG_FirstOrder_Method1[:, 13]) *
            funcgroups[:, 2],
            ) +
            sum(
            (countsSecondOrder[:, :] .* MG_SecondOrder_Method1[:, 13]) *
            funcgroups[:, 2],
            )
            push!(listPropHukkerikar, ("Hv[Tb] (kJ/mol)", Hvb))
            push!(PropHuk, ("Hv[Tb]", Hvb))

            # Entropy of vaporization (Tb) [J/mol K]
            Svb0 = 83.3097
            Svb =
            Svb0 +
            sum(
            (countsFirstOrder[:, :] .* MG_FirstOrder_Method1[:, 14]) *
            funcgroups[:, 2],
            ) +
            sum(
            (countsSecondOrder[:, :] .* MG_SecondOrder_Method1[:, 14]) *
            funcgroups[:, 2],
            )
            push!(listPropHukkerikar, ("Sv[Tb] (J/mol K)", Svb))
            push!(PropHuk, ("Sv[Tb]", Svb))

            # Hildebrand solubility parameter [MPa^(1/2)]
            δ0 = 21.6654
            δ =
            δ0 + (
            sum(
            (countsFirstOrder[:, :] .* MG_FirstOrder_Method1[:, 18]) *
            funcgroups[:, 2],
            ) + sum(
            (countsSecondOrder[:, :] .* MG_SecondOrder_Method1[:, 18]) *
            funcgroups[:, 2],
            )
            )
            push!(listPropHukkerikar, ("δ (MPa^(0.5))", δ))
            push!(PropHuk, ("D", δ))

            # Hansen solubility parameter [MPa^(1/2)]
            δ0 = 21.6654
            δD =
            δ0 + (
            sum(
            (countsFirstOrder[:, :] .* MG_FirstOrder_Method1[:, 15]) *
            funcgroups[:, 2],
            ) + sum(
            (countsSecondOrder[:, :] .* MG_SecondOrder_Method1[:, 15]) *
            funcgroups[:, 2],
            )
            )
            push!(listPropHukkerikar, ("δD (MPa^(0.5))", δD))
            push!(PropHuk, ("DD", δD))

            δP =
            δ0 + (
            sum(
            (countsFirstOrder[:, :] .* MG_FirstOrder_Method1[:, 16]) *
            funcgroups[:, 2],
            ) + sum(
            (countsSecondOrder[:, :] .* MG_SecondOrder_Method1[:, 16]) *
            funcgroups[:, 2],
            )
            )
            push!(listPropHukkerikar, ("δP (MPa^(0.5))", δP))
            push!(PropHuk, ("DP", δP))

            δH =
            δ0 + (
            sum(
            (countsFirstOrder[:, :] .* MG_FirstOrder_Method1[:, 17]) *
            funcgroups[:, 2],
            ) + sum(
            (countsSecondOrder[:, :] .* MG_SecondOrder_Method1[:, 17]) *
            funcgroups[:, 2],
            )
            )
            push!(listPropHukkerikar, ("δH (MPa^(0.5))", δH))
            push!(PropHuk, ("DH", δH))

            # Acentric factor
            ωa = 0.9080
            ωb = 0.1055
            ωc = 1.0012
            ω =
            ωa * log(
            (
            sum(
            (countsFirstOrder[:, :] .* MG_FirstOrder_Method1[:, 19]) *
            funcgroups[:, 2],
            ) +
            sum(
            (countsSecondOrder[:, :] .* MG_SecondOrder_Method1[:, 19]) *
            funcgroups[:, 2],
            ) +
            ωc
            )^(1 / ωb),
            )
            push!(listPropHukkerikar, ("ω", ω))
            push!(PropHuk, ("Acentric Factor", ω))

            # Liquid molar volume [cc/kmol]
            Vm0 = 0.0160
            Vm =
            Vm0 +
            sum(
            (countsFirstOrder[:, :] .* MG_FirstOrder_Method1[:, 20]) *
            funcgroups[:, 2],
            ) +
            sum(
            (countsSecondOrder[:, :] .* MG_SecondOrder_Method1[:, 20]) *
            funcgroups[:, 2],
            )
            Vm = 1000 * Vm
            push!(listPropHukkerikar, ("Vm (cc/mol)", Vm))
            push!(PropHuk, ("Vm", Vm))

            ####################################################################
            # Joback

            set_gtk_property!(imgAtomIndexJ, :file, filename_out2)
            # Functional Groups Analysis
            fgJoback = MG.functionalgroupgraph(mol, "Joback")

            funcgroupsJoback = DF.DataFrame(Group = String[], Times = Int[], Sets = String[])

            for (term, components) in fgJoback.componentmap
                nodes = [sort(collect(comp)) for comp in components]
                push!(
                funcgroupsJoback,
                (string(term), length(collect(nodes)), string(nodes...)),
                )
            end

            # Size for list for Joback
            rowsJ = size(JobackDatabase)[1]
            rowsFGJoback = size(funcgroupsJoback)[1]
            countsJoback = Array{Int64}(undef, rowsJ, rowsFGJoback)

            # Extracting equalities for Joback
            FGJoback = DF.DataFrame(Group = String[], Times = Int[], Sets = String[])

            for i=1:rowsJ
                for j=1:rowsFGJoback
                    countsJoback[i,j] = convert(Int64, funcgroupsJoback[j,1] == JobackDatabase[i,1])

                    if countsJoback[i,j] == 1
                        push!(FGJoback, (funcgroupsJoback[j,1], funcgroupsJoback[j,2], funcgroupsJoback[j,3]))
                    end
                end
            end

            setsJoback = FGJoback[:,3]
            sizeSetsJoback = length(setsJoback)

            setss = []
            for i=1:sizeSetsJoback
                if length(setsJoback[i]) == 3
                    push!(setss, (setsJoback[i], i))
                end
            end

            test = zeros(length(setss),sizeSetsJoback)
            for i=1:length(setss)
                for j=1:sizeSetsJoback
                    testu = findfirst(isequal(setss[i][1][2]), setsJoback[j])
                    if isnothing(testu)
                        test[i,j] = 0
                    else
                        if setss[i][1] == setsJoback[j]
                            test[i,j] = 0
                        else
                            test[i,j] = 1
                        end
                    end
                end
            end

            setdelete = []
            for i=1:length(setss)
                a = test[i,:]*setss[:][i][2]
                if sum(a) != 0
                    DF.delete!(FGJoback, Int64(sum(a)))
                end
            end

            # Size for list for Joback
            rowsJNew = size(JobackDatabase)[1]
            rowsFGJobackNew = size(FGJoback)[1]
            countsJobackNew = Array{Int64}(undef, rowsJ, rowsFGJobackNew)

            # Extracting equalities for Joback
            FGJobackNew = DF.DataFrame(Group = String[], Times = Int[], Sets = String[])

            for i=1:rowsJNew
                for j=1:rowsFGJobackNew
                    countsJobackNew[i,j] = convert(Int64, FGJoback[j,1] == JobackDatabase[i,1])

                    if countsJobackNew[i,j] == 1
                        push!(FGJobackNew, (FGJoback[j,1], FGJoback[j,2], FGJoback[j,3]))
                    end
                end
            end

            for i = 1:size(FGJobackNew)[1]
                push!(
                listFGJoback,
                (FGJobackNew[i, 1], FGJobackNew[i, 2], FGJobackNew[i, 3]),
                )
            end

            # Property calculations
            # Molecular weigth
            Mw = MG.standardweight(mol)[1]

            # Normal boiling point
            Tbi = sum((countsJobackNew[:,:] .* JobackDatabase[:,5])*FGJobackNew[:,2])
            Tb = 198.2 + Tbi

            # Melting point
            Tmi = sum((countsJobackNew[:,:] .* JobackDatabase[:,6])*FGJobackNew[:,2])
            Tm = 122.5 + Tmi

            # Critical Temperature
            Tci = sum((countsJobackNew[:,:] .* JobackDatabase[:,2])*FGJobackNew[:,2])
            Tc = Tb*(0.584 + 0.965*Tci - (Tci)^2)^(-1)

            # Critical pressure
            numAtoms = MG.countatoms(mol)
            akeys = keys(numAtoms)

            Na = 0
            for i in akeys
                Na = Na + numAtoms[i]
            end
            Pci = sum((countsJobackNew[:,:] .* JobackDatabase[:,3])*FGJobackNew[:,2])
            Pc = (0.113 + 0.0032*Na - Pci)^(-2)

            # Critical volume
            Vci = sum((countsJobackNew[:,:] .* JobackDatabase[:,4])*FGJobackNew[:,2])
            Vc = 17.5 + Vci

            # Heat of formation (ideal gas, 298 K)
            Hformi = sum((countsJobackNew[:,:] .* JobackDatabase[:,7])*FGJobackNew[:,2])
            Hform = 68.29 + Hformi

            # Gibbs energy of formation (ideal gas, 298 K)
            Gformi = sum((countsJobackNew[:,:] .* JobackDatabase[:,8])*FGJobackNew[:,2])
            Gform = 53.88 + Gformi

            # Heat capacity (ideal gas)
            T = 298
            ai = sum((countsJobackNew[:,:] .* JobackDatabase[:,9])*FGJobackNew[:,2])
            bi = sum((countsJobackNew[:,:] .* JobackDatabase[:,10])*FGJobackNew[:,2])
            ci = sum((countsJobackNew[:,:] .* JobackDatabase[:,11])*FGJobackNew[:,2])
            di = sum((countsJobackNew[:,:] .* JobackDatabase[:,12])*FGJobackNew[:,2])
            Cp = ai - 37.93 + (bi + 0.210)*T + (ci - 3.91e-4)*T^2 + (di + 2.06e-7)*T^3

            # Heat of vaporization at normal boiling point
            Hvapi = sum((countsJobackNew[:,:] .* JobackDatabase[:,14])*FGJobackNew[:,2])
            ΔHvap = 15.30 + Hvapi

            # Heat of fusion
            Hfusi = sum((countsJobackNew[:,:] .* JobackDatabase[:,13])*FGJobackNew[:,2])
            ΔHfus = -0.88 + Hfusi

            # Liquid dynamic viscosity
            ŋa = sum((countsJobackNew[:,:] .* JobackDatabase[:,15])*FGJobackNew[:,2])
            ŋb = sum((countsJobackNew[:,:] .* JobackDatabase[:,16])*FGJobackNew[:,2])

            ŋL = Mw*exp(((ŋa - 597.82)/T) + ŋb - 11.202)

            # Print
            push!(listPropJoback, ("Mw (g/mol)", Mw))
            push!(listPropJoback, ("Tb (K)", Tb))
            push!(listPropJoback, ("Tm (K)", Tm))
            push!(listPropJoback, ("Tc (K)", Tc))
            push!(listPropJoback, ("Pc (bar)", Pc))
            push!(listPropJoback, ("Vc (cc/mol)", Vc))
            push!(listPropJoback, ("Hform (kJ/mol)", Hform))
            push!(listPropJoback, ("Gform (kJ/mol)", Gform))
            push!(listPropJoback, ("Cp (J/mol K)", Cp))
            push!(listPropJoback, ("ΔHvap (kJ/mol)", ΔHvap))
            push!(listPropJoback, ("ΔHfus (kJ/mol)", ΔHfus))
            push!(listPropJoback, ("ŋL (Pa s)", ŋL))

            set_gtk_property!(tb2, :sensitive, true)
            ####################################################################
        catch
            Nothing
        end
        set_gtk_property!(nb, :page, 2)
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

            smilesString = convert(String, smilesString)
            # Convert String to mol
            global mol = MG.smilestomol(string(smilesString))
            global mol = MG.kekulize(mol)

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
    push!(nb, nbFrame0, "  Estructure Drawing  ")

    ################################################################################
    # Molecular search
    ################################################################################
    nbFrame01 = Frame()
    push!(nb, nbFrame01, "  Molecular Search  ")

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

    # Hukkerikar et al., (2012)#################################################
    nbResFrame0 = Frame()
    screen = Gtk.GAccessor.style_context(nbResFrame0)
    push!(screen, StyleProvider(provider), 600)

    gHukkerikar = Grid()
    set_gtk_property!(gHukkerikar, :margin_top, 20)
    set_gtk_property!(gHukkerikar, :margin_bottom, 20)
    set_gtk_property!(gHukkerikar, :margin_left, 20)
    set_gtk_property!(gHukkerikar, :margin_right, 20)
    set_gtk_property!(gHukkerikar, :valign, 3)
    set_gtk_property!(gHukkerikar, :halign, 3)
    set_gtk_property!(gHukkerikar, :column_spacing, 20)
    set_gtk_property!(gHukkerikar, :row_spacing, 20)

    molFrameHukkerikar = Frame("Molecule")
    set_gtk_property!(molFrameHukkerikar, :label_xalign, 0.50)
    set_gtk_property!(molFrameHukkerikar, :height_request, round(h * 0.28))
    set_gtk_property!(molFrameHukkerikar, :width_request, round(h * 0.32))
    screen = Gtk.GAccessor.style_context(molFrameHukkerikar)
    push!(screen, StyleProvider(provider), 600)

    imgAtomIndex = Gtk.Image()

    push!(molFrameHukkerikar, imgAtomIndex)

    # Notebook for FG
    global nbFGHukkerikar = Notebook()
    set_gtk_property!(nbFGHukkerikar, :tab_pos, 2)
    set_gtk_property!(nbFGHukkerikar, :name, "nbFGHukkerikar")

    FGHukkerikar1 = Frame()
    screen = Gtk.GAccessor.style_context(FGHukkerikar1)
    push!(screen, StyleProvider(provider), 600)

    FGHukkerikar2 = Frame()
    screen = Gtk.GAccessor.style_context(FGHukkerikar2)
    push!(screen, StyleProvider(provider), 600)

    FGHukkerikar3 = Frame()
    screen = Gtk.GAccessor.style_context(FGHukkerikar3)
    push!(screen, StyleProvider(provider), 600)

    push!(nbFGHukkerikar, FGHukkerikar1, "First Order")
    push!(nbFGHukkerikar, FGHukkerikar2, "Second Order")
    push!(nbFGHukkerikar, FGHukkerikar3, "Third Order")


    global fgFrameHukkerikar = Frame("Functional Groups")
    set_gtk_property!(fgFrameHukkerikar, :label_xalign, 0.50)
    set_gtk_property!(fgFrameHukkerikar, :height_request, round(h * 0.28))
    set_gtk_property!(fgFrameHukkerikar, :width_request, round(h * 0.32))
    screen = Gtk.GAccessor.style_context(fgFrameHukkerikar)
    push!(screen, StyleProvider(provider), 600)

    ##################################################33333
    # First order fgFrameHukkerikar
    # GtkListStore where the data is actually saved
    global listFGHukkerikar1 = ListStore(String, Int64, String)

    # Gtk TreeView to show the graphical element
    global viewFGHukkerikar1 = TreeView(TreeModel(listFGHukkerikar1))
    set_gtk_property!(viewFGHukkerikar1, :enable_grid_lines, 3)
    set_gtk_property!(viewFGHukkerikar1, :enable_search, true)

    # Window that allow scroll the TreeView
    scrollFGHukkerikar1 = ScrolledWindow(viewFGHukkerikar1)
    #set_gtk_property!(scrollFG, :width_request, 750)
    #set_gtk_property!(scrollFG, :height_request, 250)
    selection1 = Gtk.GAccessor.selection(viewFGHukkerikar1)

    # Column definitions
    cTxt1 = CellRendererText()

    c11 = TreeViewColumn("FG", cTxt1, Dict([("text", 0)]))
    c12 = TreeViewColumn("Count", cTxt1, Dict([("text", 1)]))
    c13 = TreeViewColumn("Index", cTxt1, Dict([("text", 2)]))

    # Add column to TreeView
    push!(viewFGHukkerikar1, c11, c12, c13)

    #push!(fgFrameHukkerikar, scrollFGHukkerikar)
    push!(FGHukkerikar1, scrollFGHukkerikar1)

    ##################################################33333
    # Second order fgFrameHukkerikar
    # GtkListStore where the data is actually saved
    global listFGHukkerikar2 = ListStore(String, Int64, String)

    # Gtk TreeView to show the graphical element
    global viewFGHukkerikar2 = TreeView(TreeModel(listFGHukkerikar2))
    set_gtk_property!(viewFGHukkerikar1, :enable_grid_lines, 3)
    set_gtk_property!(viewFGHukkerikar1, :enable_search, true)

    # Window that allow scroll the TreeView
    scrollFGHukkerikar2 = ScrolledWindow(viewFGHukkerikar2)
    #set_gtk_property!(scrollFG, :width_request, 750)
    #set_gtk_property!(scrollFG, :height_request, 250)
    selection1 = Gtk.GAccessor.selection(viewFGHukkerikar2)

    # Column definitions
    cTxt1 = CellRendererText()

    c11 = TreeViewColumn("FG", cTxt1, Dict([("text", 0)]))
    c12 = TreeViewColumn("Count", cTxt1, Dict([("text", 1)]))
    c13 = TreeViewColumn("Index", cTxt1, Dict([("text", 2)]))

    # Add column to TreeView
    push!(viewFGHukkerikar2, c11, c12, c13)

    #push!(fgFrameHukkerikar, scrollFGHukkerikar)
    push!(FGHukkerikar2, scrollFGHukkerikar2)

    ##################################################33333
    # Second order fgFrameHukkerikar
    # GtkListStore where the data is actually saved
    global listFGHukkerikar3 = ListStore(String, Int64, String)

    # Gtk TreeView to show the graphical element
    global viewFGHukkerikar3 = TreeView(TreeModel(listFGHukkerikar3))
    set_gtk_property!(viewFGHukkerikar3, :enable_grid_lines, 3)
    set_gtk_property!(viewFGHukkerikar3, :enable_search, true)

    # Window that allow scroll the TreeView
    scrollFGHukkerikar3 = ScrolledWindow(viewFGHukkerikar3)
    #set_gtk_property!(scrollFG, :width_request, 750)
    #set_gtk_property!(scrollFG, :height_request, 250)
    selection1 = Gtk.GAccessor.selection(viewFGHukkerikar3)

    # Column definitions
    cTxt1 = CellRendererText()

    c11 = TreeViewColumn("FG", cTxt1, Dict([("text", 0)]))
    c12 = TreeViewColumn("Count", cTxt1, Dict([("text", 1)]))
    c13 = TreeViewColumn("Index", cTxt1, Dict([("text", 2)]))

    # Add column to TreeView
    push!(viewFGHukkerikar3, c11, c12, c13)

    #push!(fgFrameHukkerikar, scrollFGHukkerikar)
    push!(FGHukkerikar3, scrollFGHukkerikar3)

    ###########################################################################

    propFrameHukkerikar = Frame("Properties Estimated")
    set_gtk_property!(propFrameHukkerikar, :label_xalign, 0.50)
    set_gtk_property!(propFrameHukkerikar, :height_request, round(h * 0.20))
    set_gtk_property!(propFrameHukkerikar, :width_request, round(h * 0.32))
    screen = Gtk.GAccessor.style_context(propFrameHukkerikar)
    push!(screen, StyleProvider(provider), 600)


    ##################################################33333
    # Properties fgFrameHukkerikar
    # GtkListStore where the data is actually saved
    global listPropHukkerikar = ListStore(String, Float64)

    # Gtk TreeView to show the graphical element
    global viewPropHukkerikar = TreeView(TreeModel(listPropHukkerikar))
    set_gtk_property!(viewPropHukkerikar, :enable_grid_lines, 3)
    set_gtk_property!(viewPropHukkerikar, :enable_search, true)

    # Window that allow scroll the TreeView
    scrollPropHukkerikar = ScrolledWindow(viewPropHukkerikar)
    #set_gtk_property!(scrollFG, :width_request, 750)
    #set_gtk_property!(scrollFG, :height_request, 250)
    selection1 = Gtk.GAccessor.selection(viewPropHukkerikar)

    # Column definitions
    cTxt1 = CellRendererText()

    c11 = TreeViewColumn("Property", cTxt1, Dict([("text", 0)]))
    c12 = TreeViewColumn("Value", cTxt1, Dict([("text", 1)]))

    # Add column to TreeView
    push!(viewPropHukkerikar, c11, c12)

    #push!(fgFrameHukkerikar, scrollFGHukkerikar)
    push!(propFrameHukkerikar, scrollPropHukkerikar)

    gHukkerikar[1, 1] = molFrameHukkerikar
    gHukkerikar[2, 1:2] = nbFGHukkerikar
    gHukkerikar[1, 2] = propFrameHukkerikar

    push!(nbResFrame0, gHukkerikar)

    # Joback & Reid #################################################
    nbResFrame1 = Frame()
    screen = Gtk.GAccessor.style_context(nbResFrame1)
    push!(screen, StyleProvider(provider), 600)

    gJoback = Grid()
    set_gtk_property!(gJoback, :margin_top, 20)
    set_gtk_property!(gJoback, :margin_bottom, 20)
    set_gtk_property!(gJoback, :margin_left, 20)
    set_gtk_property!(gJoback, :margin_right, 20)
    set_gtk_property!(gJoback, :valign, 3)
    set_gtk_property!(gJoback, :halign, 3)
    set_gtk_property!(gJoback, :column_spacing, 20)
    set_gtk_property!(gJoback, :row_spacing, 20)

    molFrameJoback = Frame("Molecule")
    set_gtk_property!(molFrameJoback, :label_xalign, 0.50)
    set_gtk_property!(molFrameJoback, :height_request, round(h * 0.28))
    set_gtk_property!(molFrameJoback, :width_request, round(h * 0.32))
    screen = Gtk.GAccessor.style_context(molFrameJoback)
    push!(screen, StyleProvider(provider), 600)

    imgAtomIndexJ = Gtk.Image()

    push!(molFrameJoback, imgAtomIndexJ)

    # Notebook for FG
    global nbFGJoback = Notebook()
    set_gtk_property!(nbFGJoback, :tab_pos, 2)
    set_gtk_property!(nbFGJoback, :name, "nbFGJoback")

    FGJoback = Frame()
    set_gtk_property!(FGJoback, :label_xalign, 0.50)
    set_gtk_property!(FGJoback, :height_request, round(h * 0.28))
    set_gtk_property!(FGJoback, :width_request, round(h * 0.32))
    screen = Gtk.GAccessor.style_context(FGJoback)
    push!(screen, StyleProvider(provider), 600)

    push!(nbFGJoback, FGJoback, "General Groups")


    global fgFrameJoback = Frame("Functional Groups")
    set_gtk_property!(fgFrameJoback, :label_xalign, 0.50)
    set_gtk_property!(fgFrameJoback, :height_request, round(h * 0.28))
    set_gtk_property!(fgFrameJoback, :width_request, round(h * 0.32))
    screen = Gtk.GAccessor.style_context(fgFrameJoback)
    push!(screen, StyleProvider(provider), 600)

    ##################################################33333
    # First order fgFrameHukkerikar
    # GtkListStore where the data is actually saved
    global listFGJoback = ListStore(String, Int64, String)

    # Gtk TreeView to show the graphical element
    global viewFGJoback = TreeView(TreeModel(listFGJoback))
    set_gtk_property!(viewFGJoback, :enable_grid_lines, 3)
    set_gtk_property!(viewFGJoback, :enable_search, true)

    # Window that allow scroll the TreeView
    scrollFGJoback = ScrolledWindow(viewFGJoback)
    #set_gtk_property!(scrollFG, :width_request, 750)
    #set_gtk_property!(scrollFG, :height_request, 250)
    selection1 = Gtk.GAccessor.selection(viewFGJoback)

    # Column definitions
    cTxt1 = CellRendererText()

    c11 = TreeViewColumn("FG", cTxt1, Dict([("text", 0)]))
    c12 = TreeViewColumn("Count", cTxt1, Dict([("text", 1)]))
    c13 = TreeViewColumn("Index", cTxt1, Dict([("text", 2)]))

    # Add column to TreeView
    push!(viewFGJoback, c11, c12, c13)

    #push!(fgFrameHukkerikar, scrollFGHukkerikar)
    push!(FGJoback, scrollFGJoback)


    ###########################################################################

    propFrameJoback = Frame("Properties Estimated")
    set_gtk_property!(propFrameJoback, :label_xalign, 0.50)
    set_gtk_property!(propFrameJoback, :height_request, round(h * 0.20))
    set_gtk_property!(propFrameJoback, :width_request, round(h * 0.32))
    screen = Gtk.GAccessor.style_context(propFrameJoback)
    push!(screen, StyleProvider(provider), 600)


    ##################################################33333
    # Properties fgFrameHukkerikar
    # GtkListStore where the data is actually saved
    global listPropJoback = ListStore(String, Float64)

    # Gtk TreeView to show the graphical element
    global viewPropJoback = TreeView(TreeModel(listPropJoback))
    set_gtk_property!(viewPropJoback, :enable_grid_lines, 3)
    set_gtk_property!(viewPropJoback, :enable_search, true)

    # Window that allow scroll the TreeView
    scrollPropJoback = ScrolledWindow(viewPropJoback)
    #set_gtk_property!(scrollFG, :width_request, 750)
    #set_gtk_property!(scrollFG, :height_request, 250)
    selection1 = Gtk.GAccessor.selection(viewPropJoback)

    # Column definitions
    cTxt1 = CellRendererText()

    c11 = TreeViewColumn("Property", cTxt1, Dict([("text", 0)]))
    c12 = TreeViewColumn("Value", cTxt1, Dict([("text", 1)]))

    # Add column to TreeView
    push!(viewPropJoback, c11, c12)

    #push!(fgFrameHukkerikar, scrollFGHukkerikar)
    push!(propFrameJoback, scrollPropJoback)

    gJoback[1, 1] = molFrameJoback
    gJoback[2, 1:2] = nbFGJoback
    gJoback[1, 2] = propFrameJoback

    push!(nbResFrame1, gJoback)

    # Sánchez & Jímenez
    nbResFrame2 = Frame()
    screen = Gtk.GAccessor.style_context(nbResFrame2)
    push!(screen, StyleProvider(provider), 600)

    push!(nbRes, nbResFrame0, "  Hukkerikar et al., (2012)  ")
    push!(nbRes, nbResFrame1, "  Joback & Reid (1987)  ")
    push!(nbRes, nbResFrame2, "  Summary  ")

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
