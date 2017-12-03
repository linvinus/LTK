using Posix;

static Xcb.VisualType? find_visual(Xcb.Connection c, Xcb.VisualID visual)
{
    Xcb.ScreenIterator screen_iter = c.get_setup().roots_iterator();

    for (; screen_iter.rem != 0; Xcb.ScreenIterator.next(ref screen_iter)) {
        var screen = screen_iter.data;
        Xcb.DepthIterator depth_iter = screen.allowed_depths_iterator();
        for (; depth_iter.rem != 0; Xcb.DepthIterator.next(ref depth_iter)) {
            Xcb.Depth depth = depth_iter.data;
            foreach(var v in depth.visuals){
               if (v.visual_id == visual)
                return v;
            }
//~             Xcb.VisualTypeIterator visual_iter = depth.visuals_iterator();
//~             for (; visual_iter.rem; xcb_visualtype_next(&visual_iter))
//~                 if (visual == visual_iter.data->visual_id)
//~                     return visual_iter.data;
        }
    }

    return null;
}

int main (string[] argv) {
  uint32 mask[2];
  var c = new Xcb.Connection();
  if (c.has_error() != 0) {
          printf( "Could not connect to X11 server");
          return 1;
  }
  mask[0] = 1;
  mask[1] = Xcb.EventMask.EXPOSURE;

  var setup = c.get_setup();
  var s_iterator = setup.roots_iterator();
  var screen = s_iterator.data;
  var window = c.generate_id();
  c.create_window(Xcb.COPY_FROM_PARENT, window, screen.root,
            20, 20, 800, 600, 0,
            Xcb.WindowClass.INPUT_OUTPUT,
            screen.root_visual,
            /*Xcb.CW.OVERRIDE_REDIRECT |*/ Xcb.CW.BACK_PIXEL| Xcb.CW.EVENT_MASK,
            mask);

  /* set the title of the window */

  string title = "xcb_vala";
  c.change_property_uint8  ( Xcb.PropMode.REPLACE,
                       window,
                       Xcb.Atom.WM_NAME,
                       Xcb.Atom.STRING,
//~                        8,
                       title.length,
                       title );

  var I = Xcb.Icccm.new(c);

  var hints =  new Xcb.Icccm.WmHints ();
  Xcb.Icccm.wm_hints_set_normal(ref hints);
  I.set_wm_hints(window, hints);

  var size_hints = new Xcb.Icccm.SizeHints();
//~   Xcb.Icccm.SizeHints size_hints;
  size_hints.flags=(Xcb.Icccm.SizeHint.US_SIZE|Xcb.Icccm.SizeHint.P_SIZE);
  size_hints.height=size_hints.base_height=60;
  size_hints.width=size_hints.base_width=60;
  I.set_wm_normal_hints(window, size_hints);

  Xcb.AtomT[] atoms={};
  var deleteWindowAtom = c.intern_atom_reply(c.intern_atom(true,"WM_DELETE_WINDOW")).atom;
  atoms += deleteWindowAtom;
  atoms += c.intern_atom_reply(c.intern_atom(true,"WM_TAKE_FOCUS")).atom;
  atoms += c.intern_atom_reply(c.intern_atom(true,"_NET_WM_PING")).atom;
  atoms += c.intern_atom_reply(c.intern_atom(true,"_NET_WM_SYNC_REQUEST")).atom;
  var wmprotocolsAtom = c.intern_atom_reply(c.intern_atom(true,"WM_PROTOCOLS")).atom;
  I.set_wm_protocols(window,wmprotocolsAtom,atoms);

  c.map_window(window);

  var visual = find_visual(c, screen.root_visual);
  if (visual == null) {
      printf( "Some weird internal error...?!");
//~       c.disconnect(); ???
      return 1;
  }

    var surface = new Cairo.XcbSurface(c, window, visual, 800, 600);
    Cairo.Context cr = new Cairo.Context(surface);
    c.flush();
    var F = FontLoader.load("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf");
    cr.set_font_face(F);
    cr.set_font_size (14);
    string text="HELLO :) Проверка ЁЙ Русский язык اللغة العربية English language اللغة العربية";

    Xcb.GenericEvent event;
    bool finished = false;
    while (( (event = c.wait_for_event()) != null ) && !finished ) {
        switch (event.response_type & ~0x80) {
        case Xcb.EXPOSE:
            /* Avoid extra redraws by checking if this is
             * the last expose event in the sequence
             */
             Xcb.ExposeEvent e = (Xcb.ExposeEvent)event;
            if (e.count != 0)
                break;

            cr.set_source_rgb(0, 1, 0);
            cr.paint();

            cr.set_source_rgb(1, 0, 0);
            cr.move_to(0, 0);
            cr.line_to(150, 0);
            cr.line_to(150, 150);
            cr.close_path();
            cr.fill();

            cr.set_source_rgb(0, 0, 1);
            cr.set_line_width(20);
            cr.move_to(0, 150);
            cr.line_to(150, 0);
            cr.stroke();
            cr.move_to( 2, 150);
            cr.show_text( text);
            surface.flush();
            break;
        case Xcb.CLIENT_MESSAGE:
            Xcb.ClientMessageEvent e = (Xcb.ClientMessageEvent)event;
            if(e.data.data32[0] == deleteWindowAtom){
                printf("done\n");
                finished = true;
            }
            break;
        }//switch
//~         free(event);
        c.flush();
    }
    surface.finish();
    FontLoader.destroy();
//~     surface.destroy();
//~     xcb_disconnect(c);

  return 0;
}
