#!/usr/bin/python3
import os
if os.system("ls /var/debian/usr/bin/x-terminal-emulator &>/dev/null") == 0:
    if 0 == os.system("/usr/bin/debian /usr/bin/x-terminal-emulator"):
        exit(0)
import gi
gi.require_version('Gtk', '3.0')
gi.require_version('Vte', '2.91')
from gi.repository import Gtk, Vte, GLib
terminal = Vte.Terminal()
terminal.connect("child_exited",Gtk.main_quit)
terminal.spawn_sync(Vte.PtyFlags.DEFAULT, None, ["/usr/bin/debian"], [], GLib.SpawnFlags.DO_NOT_REAP_CHILD, None, None)
win = Gtk.Window()
win.connect('delete-event', Gtk.main_quit)
win.add(terminal)
win.show_all()
Gtk.main()
