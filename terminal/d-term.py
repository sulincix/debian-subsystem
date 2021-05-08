#!/usr/bin/python3
import gi, sys,os
gi.require_version('Gtk', '3.0')
gi.require_version('Vte', '2.91')
from gi.repository import Gtk, Vte, GLib
terminal = Vte.Terminal()
scrolled_window = Gtk.ScrolledWindow()
terminal.connect("child_exited",Gtk.main_quit)
cmd=""
for i in sys.argv[1:]:
    cmd+=i+" "
if cmd == "":
  cmd = os.environ["SHELL"]
print(cmd)
terminal.spawn_sync(Vte.PtyFlags.DEFAULT, None, ["sh","-c",cmd], [], GLib.SpawnFlags.DO_NOT_REAP_CHILD, None, None)
win = Gtk.Window()
win.connect('delete-event', Gtk.main_quit)
win.add(scrolled_window)
scrolled_window.add(terminal)
terminal.set_font_scale(0.8)
win.set_title("d-term")
win.set_size_request(486,313)
win.show_all()
Gtk.main()