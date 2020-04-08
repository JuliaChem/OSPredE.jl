using Gtk.ShortNames
using MolecularGraph, DataFrames

# Environmental variable to allow Windows decorations
ENV["GTK_CSD"] = 0

win = Window("My First Gtk.jl Program", 300, 300)
#set_gtk_property!(win, :window_position, 3)
set_gtk_property!(win, :accept_focus, true)

open1 = Button("Open")

close1 = Button("Close")

f1 = Frame("1")

gMain = Grid()

g1 = Grid()

g2 = Grid()

g1[1,1] = open1
g2[1,1] = close1
gMain[1,1] = f1
gMain[2,1] = g2

push!(f1, g1)

push!(win,gMain)
Gtk.showall(win)
