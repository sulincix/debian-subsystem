#!/usr/bin/python3
import gi, sys,os
gi.require_version('Gtk', '3.0')
gi.require_version('Vte', '2.91')
from gi.repository import Gtk, Vte, GLib
terminal = Vte.Terminal()
scrolled_window = Gtk.ScrolledWindow()
terminal.connect("child_exited",Gtk.main_quit)
cmd=""
if len(sys.argv) > 1:
    if "--" not in sys.argv[1]:
        cmd+=sys.argv[1]
    for i in sys.argv[2:]:
        cmd+="\""+i+"\" "
if cmd == "":
  cmd = os.environ["SHELL"]
print(cmd)
win = Gtk.Window()
if os.path.isfile("/usr/lib/sulin/dsl/debian.svg"):
    win.set_icon_from_file("/usr/lib/sulin/dsl/debian.svg")
win.connect('delete-event', Gtk.main_quit)
win.add(scrolled_window)
scrolled_window.add(terminal)
if len(sys.argv) > 1 and sys.argv[1] == "--fullscreen":
    win.fullscreen()
else:
    win.set_size_request(547,352)
terminal.set_font_scale(0.9)
win.set_title("d-term")
win.show_all()
terminal.spawn_sync(Vte.PtyFlags.DEFAULT, None, ["sh","-c",cmd], [], GLib.SpawnFlags.DO_NOT_REAP_CHILD, None, None)
Gtk.main()
