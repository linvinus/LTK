
private static Xcb.VisualType? find_visual(Xcb.Connection c, Xcb.VisualID visual)
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


namespace Ltk{
  public enum WindowState{
    unconfigured,
    hidden,
    visible
  }
  struct atom_names{
    private static int linvinus = 1;
    public static const string wm_delete_window = "WM_DELETE_WINDOW";
    public static const string wm_take_focus = "WM_TAKE_FOCUS";
    public static const string wm_protocols = "WM_PROTOCOLS";
    public static const string _net_wm_ping = "_NET_WM_PING";
    public static const string _net_wm_sync_request = "_NET_WM_SYNC_REQUEST";
  }
  /********************************************************************/
  public class Widget : GLib.Object{
    public Widget? parent;
    public GLib.List<Widget> childs;
    public uint width;
    public uint height;
    public uint x;
    public uint y;

    public Widget(Widget? parent = null){
      GLib.Object();
      this.x = this.y = 0;
      if(parent != null)
        this.parent = parent;
    }//create

    public void add(Widget child){
      child.parent = this;
      this.childs.append(child);
    }

    public void remove(Widget child){
      this.childs.remove(child);
    }

    public bool draw(Cairo.Context cr){
      return true;//continue
    }//draw
  }
  /********************************************************************/
  public class Window: Widget{
    public  Xcb.Connection C;
    private Xcb.Setup setup;
    private unowned Xcb.Icccm.Icccm I;
    private uint32 window;
    private weak Xcb.Screen screen;
    private Cairo.XcbSurface surface;
    private Cairo.Context cr;
    private HashTable<string, Xcb.AtomT?> atoms;
    private WindowState _wState;
    private WindowState state{
      get { return _wState;}
      set {
        if(_wState != value)
          if(value == WindowState.visible ){
            _wState = value;
            this.show_do();
            this.set_title_do();
//~             this.set_size_do();
            this.configure_window_do();
          }else if(value == WindowState.hidden ){ //WindowState.unconfigured is ignored
            _wState = value;
            //this.hide_do();
          }
      }
    }
    private string title;


    public Window(){

      base();

      uint32 mask[2];
      this.state = WindowState.unconfigured;
      this.atoms = new HashTable<string, Xcb.AtomT?> (str_hash, str_equal);

      this.C = new Xcb.Connection();


      if (this.C.has_error() != 0) {
//~               printf( "Could not connect to X11 server");
              return ;//null;
      }

      this.I = Xcb.Icccm.new(this.C);

      mask[0] = 1;
      mask[1] = Xcb.EventMask.EXPOSURE|Xcb.EventMask.VISIBILITY_CHANGE|Xcb.EventMask.STRUCTURE_NOTIFY;

      this.setup = this.C.get_setup();
      var s_iterator = this.setup.roots_iterator();
      this.screen = s_iterator.data;
      this.window = this.C.generate_id();

      this.C.create_window(Xcb.COPY_FROM_PARENT, this.window, this.screen.root,
                20, 20, 10, 10, 0,
                Xcb.WindowClass.INPUT_OUTPUT,
                this.screen.root_visual,
                /*Xcb.CW.OVERRIDE_REDIRECT |*/ Xcb.CW.BACK_PIXEL| Xcb.CW.EVENT_MASK,
                mask);

      var hints =  new Xcb.Icccm.WmHints ();
      Xcb.Icccm.wm_hints_set_normal(ref hints);
      this.I.set_wm_hints(this.window, hints);

//~       Xcb.AtomT tmp_atom;
      if(!this.atoms.contains(atom_names.wm_delete_window))
        this.atoms.insert(atom_names.wm_delete_window,
          this.C.intern_atom_reply(this.C.intern_atom(false,atom_names.wm_delete_window)).atom);

      if(!this.atoms.contains(atom_names.wm_take_focus))
        this.atoms.insert(atom_names.wm_take_focus,
          this.C.intern_atom_reply(this.C.intern_atom(false,atom_names.wm_take_focus)).atom);

      if(!this.atoms.contains(atom_names._net_wm_ping))
        this.atoms.insert(atom_names._net_wm_ping,
          this.C.intern_atom_reply(this.C.intern_atom(false,atom_names._net_wm_ping)).atom);

      if(!this.atoms.contains(atom_names._net_wm_sync_request))
        this.atoms.insert(atom_names._net_wm_sync_request,
          this.C.intern_atom_reply(this.C.intern_atom(false,atom_names._net_wm_sync_request)).atom);

      if(!this.atoms.contains(atom_names.wm_protocols))
        this.atoms.insert(atom_names.wm_protocols,
          this.C.intern_atom_reply(this.C.intern_atom(false,atom_names.wm_protocols)).atom);

      Xcb.AtomT[] tmp_atoms={};
      this.atoms.foreach ((key, val) => {
        if(key != atom_names.wm_protocols)
          tmp_atoms += val;
      });

      I.set_wm_protocols(this.window, this.atoms.lookup(atom_names.wm_protocols), tmp_atoms);

      var visual = find_visual(this.C, this.screen.root_visual);
      if (visual == null) {
//~           printf( "Some weird internal error...?!");
    //~       c.disconnect(); ???
          return;
      }

      this.surface = new Cairo.XcbSurface(this.C, this.window, visual, 10, 10);
      this.cr = new Cairo.Context(this.surface);

//~       return base(null);
    }

    private void show_do(){
      this.C.map_window(this.window);
      this.C.flush();
    }//show_do

    public void show(){
      this.state = WindowState.visible;
    }


    private void set_title_do(){
      this.C.change_property_uint8  ( Xcb.PropMode.REPLACE,
                           this.window,
                           Xcb.Atom.WM_NAME,
                           Xcb.Atom.STRING,
    //~                        8,
                           this.title.length,
                           this.title );
    }//set_title_do

    public void set_title(string title){
      this.title = title;
      if(this.state == WindowState.visible){
        this.set_title_do();
      }
    }//set_title

 /*   private void set_size_do(){

      var size_hints = new Xcb.Icccm.SizeHints();
      size_hints.flags=(Xcb.Icccm.SizeHint.US_SIZE|Xcb.Icccm.SizeHint.P_SIZE|Xcb.Icccm.SizeHint.BASE_SIZE);
      size_hints.height = (int32)this.height;
      size_hints.width  = (int32)this.width;
      size_hints.base_height = 0;
      size_hints.base_width  = 0;
//~       this.I.set_wm_normal_hints(this.window, size_hints);
//~       this.surface.set_size((int)this.width,(int)this.height);
    }*/

    private void configure_window_do(){
      uint32 position[] = { this.x, this.y, this.width, this.height };
      this.C.configure_window(this.window, (Xcb.ConfigWindow.X | Xcb.ConfigWindow.Y | Xcb.ConfigWindow.WIDTH | Xcb.ConfigWindow.HEIGHT), position);
    }
    
    public void set_size(uint width,uint height){

      this.width=width;
      this.height=height;
//~       if(this.state == WindowState.visible){
//~         this.surface.set_size((int)this.width,(int)this.height);
//~       }
    }

    public void load_font_with_size(string fpatch,uint size){
      var F = FontLoader.load(fpatch);
      this.cr.set_font_face(F);
      this.cr.set_font_size (size);
    }

    public bool draw(Cairo.Context cr){
      string text="HELLO :) Проверка ЁЙ Русский язык اللغة العربية English language اللغة العربية";

      cr.set_source_rgb(0, 1, 0);
      cr.paint();

      cr.set_source_rgb(1, 0, 0);
      cr.move_to(0, 0);
      cr.line_to(this.width, 0);
      cr.line_to(this.width, this.height);
      cr.close_path();
      cr.fill();

      cr.set_source_rgb(0, 0, 1);
      cr.set_line_width(20);
      cr.move_to(0, this.height);
      cr.line_to(this.width, 0);
      cr.stroke();
      cr.move_to( 2, this.height-10);
      cr.show_text( text);
      surface.flush();
      return base.draw(cr);
    }//draw

  public void on_configure(Xcb.ConfigureNotifyEvent e){
    
//~     var geom = this.C.get_geometry_reply(this.C.get_geometry_unchecked(e.window), null);
//~     GLib.stderr.printf( "on_map x,y=%d,%d w,h=%d,%d response_type=%d ew=%d, w=%d\n",
//~                       (int)e.x,
//~                       (int)e.y,
//~                       (int)e.width,
//~                       (int)e.height,
//~                       (int)e.response_type,
//~                       (int)e.event,
//~                       (int)e.window
//~                       );
    
    this.x = e.x;
    this.y = e.y;
    this.width = e.width;
    this.height = e.height;
//~     GLib.stderr.printf( "on_map x,y=%d,%d w,h=%d,%d\n",(int)this.x,(int)this.y,(int)this.width,(int)this.height);
    this.surface.set_size((int)this.width,(int)this.height);
  }
  
  public void run(){
    Xcb.GenericEvent event;
    bool finished = false;
    Xcb.AtomT deleteWindowAtom = this.atoms.lookup(atom_names.wm_delete_window);
//~     GLib.stderr.printf( "event");
    while (( (event = this.C.wait_for_event()) != null ) && !finished ) {
//~       GLib.stderr.printf( "event=%d expose=%d map=%d\n",(int)event.response_type ,Xcb.EXPOSE,Xcb.CLIENT_MESSAGE);
        switch (event.response_type & ~0x80) {
          case Xcb.EXPOSE:
              /* Avoid extra redraws by checking if this is
               * the last expose event in the sequence
               */
               Xcb.ExposeEvent e = (Xcb.ExposeEvent)event;
              if (e.count != 0)
                  break;

              this.draw(this.cr);
          break;
          case Xcb.CLIENT_MESSAGE:
              Xcb.ClientMessageEvent e = (Xcb.ClientMessageEvent)event;
//~               GLib.stderr.printf( "CLIENT_MESSAGE data32=%d deleteWindowAtom=%d\n", (int)e.data.data32[0],(int)deleteWindowAtom);
              if(e.data.data32[0] == deleteWindowAtom){
  //~                 printf("done\n");
                  finished = true;
              }
          break;
          case Xcb.CONFIGURE_NOTIFY:
              if(event.response_type == Xcb.CONFIGURE_NOTIFY)
                this.on_configure((Xcb.ConfigureNotifyEvent)event);
          break;
        }//switch
//~         free(event);
        this.C.flush();
    }

  }//run

  }//class Window


  /********************************************************************/
}//namespace Ltk
