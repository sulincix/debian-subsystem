using Gtk;

int main(string[] args){
    Gtk.init (ref args);
    Gtk.Window window = new Gtk.Window (Gtk.WindowType.TOPLEVEL);
    var term = new Vte.Terminal();
    term.set_font_scale(1.1);
    term.child_exited.connect ( (t)=> { Gtk.main_quit(); } );
    var cmd = "";
    try{
        if(args.length < 2){
            term.spawn_sync(Vte.PtyFlags.DEFAULT,null,new string[] { "/bin/bash" },null,0,null,null);
        }else{
            for(int i=1;i<args.length;i++){
                cmd+=args[i]+" ";
            }
            term.spawn_sync(Vte.PtyFlags.DEFAULT,null,new string[] { "/bin/bash", "-c", cmd },null,0,null,null);
        }
        window.set_icon_from_file("/usr/lib/sulin/dsl/debian.svg");
    }catch(GLib.Error e){
        
    }
    var scrolled = new Gtk.ScrolledWindow(null,null);
    window.add(scrolled);
    scrolled.add(term);
    window.set_default_size(760,488);
    window.set_title("d-term");
    window.show_all ();
    Gtk.main ();
    return 0;
}

