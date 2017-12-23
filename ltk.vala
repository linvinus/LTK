/*
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 *
 */


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
        }
    }

    return null;
}

[CCode (cname = "cairo_xcb_surface_set_drawable")]
extern void cairo_xcb_surface_set_drawable(Cairo.XcbSurface s,uint32 d,int width,int height);


namespace Ltk{
  [SimpleType]
  [CCode (has_type_id = false)]
  public enum WindowState{
    unconfigured,
    hidden,
    visible
  }

  //uint32
  [SimpleType]
  //[IntegerType (rank = 9)]
  [CCode (has_type_id = false)]
  public enum SOptions{
    fill_horizontal  =1<<0,
    fill_vertical    =1<<1,
    place_horizontal =1<<2,
    place_vertical   =1<<3,
    visible          =1<<4
  }

  /*[SimpleType]*/
  [CCode (has_type_id = false)]
  struct atom_names{
    private static int linvinus = 1;
    public static const string wm_delete_window = "WM_DELETE_WINDOW";
    public static const string wm_take_focus = "WM_TAKE_FOCUS";
    public static const string wm_protocols = "WM_PROTOCOLS";
    public static const string _net_wm_ping = "_NET_WM_PING";
    public static const string _net_wm_sync_request = "_NET_WM_SYNC_REQUEST";
  }

//~   [SimpleType]
  [CCode (has_type_id = false)]
  public struct Allocation{
    uint32 x;
    uint32 y;
    uint32 width;
    uint32 height;
    SOptions options;
  }

/*  public struct FColor{
    float a;
    float r;
    float g;
    float b;
  }

  [SimpleType]
  [CCode (has_type_id = false)]
  public enum StyleColor{
    bg_color,
    fg_color,
    text_bg_color,
    text_fg_color,
    border_color
  }
  private FColor[] colors_internal={ {0,1,1,1},
                                     {0,0,0,0},
                                   };

  private static GLib.List<Ltk.StyleColor,> style_colors;
  */

  /********************************************************************/
 	public struct WidgetListIter {
    unowned GLib.List<Widget> list;
    public WidgetListIter(GLib.List<Widget> l){
      this.list = l;
    }
		public unowned Widget? next_value () {
      unowned Widget? ret = null;
      if(list != null){
        ret = list.data;
        this.list = list.next;
      }
			return ret;
		}
		public void remove (){
    }
	}

  /********************************************************************/

    private int CompareWidth (Widget? a, Widget? b){
      if(a == null || b == null)
        return 0;
      GLib.stderr.printf("  ### a=%u > b=%u\n", a.min_width , b.min_width);
      if(a.min_width < b.min_width){
        return 1;
      }else if(a.min_width > b.min_width){
        return -1;
      }else{
        return 0;
      }
    }


  public class  WidgetList {
    private GLib.List<Widget> childs;
    private GLib.List<unowned Widget> _fixed_width;
    private GLib.List<unowned Widget> _fixed_height;
    public GLib.List<unowned Widget> _variable_width;
    private uint _count;
    private uint _fixed_width_count;
    private uint _fixed_height_count;
    public uint count{
      get { return _count;}
    }
    public uint fixed_width_count{
      get { return _fixed_width_count;}
    }
    public uint fixed_height_count{
      get {return _fixed_height_count;}
    }
    public uint fixed_width{
      get{
        uint w_sum = 0;
        foreach(var w in this._fixed_width){
          w_sum += w.min_width;
        }
        return w_sum;
      }
    }
    public uint fixed_height{
      get{
        uint h_sum = 0;
        foreach(var w in this._fixed_height){
          h_sum += w.min_height;
        }
        return h_sum;
      }
    }

    public uint allocated_width{
      get{
        uint w_sum = 0;
        foreach(var w in this.childs){
          w_sum += w.A.width;
        }
        return w_sum;
      }
    }

    public uint min_width_sum{
      get{
        uint w_sum = 0;
        foreach(var w in this.childs){
          w_sum += w.min_width;
        }
        return w_sum;
      }
    }

    public WidgetList(){
      this._count = 0;
      this._fixed_width_count = 0;
      this._fixed_height_count = 0;
      this.childs = new GLib.List<Widget>();
      this._fixed_width = new GLib.List<Widget>();
      this._fixed_height = new GLib.List<Widget>();
      this._variable_width = new GLib.List<Widget>();
    }
    public WidgetListIter iterator (){
      return WidgetListIter(this.childs.first());
    }

    public void remove_all(){
//~       this._fixed_width.remove_all();
//~       this.fixed_height.remove_all();
//~       this.childs.remove_all();
    }
    public void append (owned Widget child){
      this.childs.append(child);
      this._count++;
      var a = new Allocation();
      this.on_size_changed(child,a);
      child.size_changed.connect(this.on_size_changed);
    }
    public void remove (Widget child){
      if( this._fixed_width.find(child) != null){
        this._fixed_width.remove(child);
        this._fixed_width_count--;
      }
      if( this._fixed_height.find(child) != null){
        this._fixed_height.remove(child);
        this._fixed_height_count--;
      }
      this.childs.remove(child);
      this._count--;
    }


    private void on_size_changed(Widget src, Allocation prev){
      if( (src.fill_mask & Ltk.SOptions.fill_horizontal) == 0/*WTF? || src.min_width >= src.A.width*/){
          if(this._fixed_width.find(src) == null){
            this._fixed_width.append(src);
            this._fixed_width_count++;
          }
          if( this._variable_width.find(src) != null){
            this._variable_width.remove(src);
          }
      }else{
          if( this._fixed_width.find(src) != null){
            this._fixed_width.remove(src);
            this._fixed_width_count--;
          }
          if( this._variable_width.find(src) == null){
            this._variable_width.append(src);
          }
      }
      this._variable_width.sort((GLib.CompareFunc<weak Ltk.Widget>)CompareWidth);

      if( (src.fill_mask & Ltk.SOptions.fill_vertical) == 0){
          if(this._fixed_height.find(src) == null){
            this._fixed_height.append(src);
            this._fixed_height_count++;
          }
      }else{
          if( this._fixed_height.find(src) != null){
            this._fixed_height.remove(src);
            this._fixed_height_count--;
          }
      }

    }//on_size_changed

//~     public uint length(){
//~       return this._count;
//~     }
    public unowned List<Widget> find (Widget data){
      return this.childs.find(data);
    }

  }//class WidgetList
  /********************************************************************/
  public class XcbWindow{
    public weak Ltk.Window window_widget;
    private uint32 window = 0;
    private uint32 pixmap = 0;
    private uint32 pixmap_gc = 0;
    private Cairo.XcbSurface surface;
    private Cairo.Context cr;
    private WindowState _wState;
    private WindowState state{
      get { return _wState;}
      set {
        if(_wState != value){
          if(value == WindowState.visible ){
            _wState = value;
            this.show_do();
//~             this.set_title_do();
//~             this.set_size_do();
            if(this.pos_x != -1 && this.pos_y != -1){
              this.move_resize_req(this.pos_x, this.pos_y, this.min_width, this.min_height);
            }else{
              this.resize_req(this.min_width, this.min_height);
            }
            Global.C.flush();
          }else if(value == WindowState.hidden ){ //WindowState.unconfigured is ignored
            _wState = value;
            //this.hide_do();
          }
        }
      }
    }
    private int pos_x = -1;
    private int pos_y = -1;
    private uint min_width;
    private uint min_height;

    private void create_pixmap(uint16 width, uint16 height){
      if(this.pixmap != 0){
        Global.C.free_gc(this.pixmap_gc);
        Global.C.free_pixmap(this.pixmap);
      }
      this.pixmap = Global.C.generate_id();
      this.pixmap_gc = Global.C.generate_id();

      Global.C.create_pixmap(Global.screen.root_depth,this.pixmap,Global.screen.root,width,height);
      uint32 values[2];
      values[0] = Global.screen.white_pixel;
      values[1] = Global.screen.white_pixel;
      Global.C.create_gc(this.pixmap_gc, this.pixmap, (Xcb.GC.BACKGROUND|Xcb.GC.FOREGROUND),values);

      if(this.window != 0 ){
        values[0] =  this.pixmap ;
        values[1] = 0;
        Global.C.change_window_attributes (this.window, Xcb.CW.BACK_PIXMAP, values);
      }
//~       uint32 position[] = { this.pos_x, this.pos_y, this.min_width, this.min_height };
//~       Global.C.configure_window(this.window, (Xcb.ConfigWindow.X | Xcb.ConfigWindow.Y | Xcb.ConfigWindow.WIDTH | Xcb.ConfigWindow.HEIGHT), position);

    }

    public XcbWindow(Ltk.Window window_widget){
      this.window_widget = window_widget;
      this.state = WindowState.unconfigured;
      this.window = Global.C.generate_id();
      this.min_width = 1;
      this.min_height = 1;
      uint32 values[2];

      this.create_pixmap(1,1);

      values[0] = this.pixmap;
      values[1] = Xcb.EventMask.EXPOSURE|Xcb.EventMask.VISIBILITY_CHANGE|Xcb.EventMask.STRUCTURE_NOTIFY;

      Global.C.create_window(Xcb.COPY_FROM_PARENT, this.window, Global.screen.root,
                (int16)this.pos_x, (int16)this.pos_y, (uint16)this.min_width, (uint16)this.min_height, 0,
                Xcb.WindowClass.INPUT_OUTPUT,
                Global.screen.root_visual,
                /*Xcb.CW.OVERRIDE_REDIRECT |*/ Xcb.CW.BACK_PIXMAP| Xcb.CW.EVENT_MASK,
                values);



      var hints =  new Xcb.Icccm.WmHints ();
      Xcb.Icccm.wm_hints_set_normal(ref hints);
      Global.I.set_wm_hints(this.window, hints);



      Xcb.AtomT[] tmp_atoms={};
      Global.atoms.foreach ((key, val) => {
        if(key != atom_names.wm_protocols)
          tmp_atoms += val;
      });

      Global.I.set_wm_protocols(this.window, Global.atoms.lookup(atom_names.wm_protocols), tmp_atoms);


      this.surface = new Cairo.XcbSurface(Global.C, this.pixmap, Global.visual, (int)this.min_width, (int)this.min_height);
      this.cr = new Cairo.Context(this.surface);

      Global.windows.insert(this.window,this);
    }//XcbWindow

    ~XcbWindow(){
      GLib.stderr.printf("~XcbWindow fd=%u\n",Global.C.get_file_descriptor());
      this.surface.finish();//When the last call to cairo_surface_destroy() decreases the reference count to zero, cairo will call cairo_surface_finish()
      if(Global.windows.lookup(this.window)!=null){
        Global.windows.remove(this.window);
        GLib.stderr.printf("~XcbWindow %u\n",this.window);
      }
      Global.C.free_gc(this.pixmap_gc);
      Global.C.free_pixmap(this.pixmap);
      Global.C.unmap_window(this.window);
      Global.C.destroy_window(this.window);
      do{
        Global.C.flush();
      }while (  Global.C.poll_for_event() != null  );

    }//~XcbWindow

    private void show_do(){
      Global.C.map_window(this.window);
    }//show_do

    public void show(){
      this.state = WindowState.visible;
    }


    public void set_title(string title){
      if(title != null){
        Global.C.change_property_uint8  ( Xcb.PropMode.REPLACE,
                             this.window,
                             Xcb.Atom.WM_NAME,
                             Xcb.Atom.STRING,
      //~                        8,
                             title.length,
                             title );
      }
    }//set_title_do

 /*   private void set_size_do(){

      var size_hints = new Xcb.Icccm.SizeHints();
      size_hints.flags=(Xcb.Icccm.SizeHint.US_SIZE|Xcb.Icccm.SizeHint.P_SIZE|Xcb.Icccm.SizeHint.BASE_SIZE);
      size_hints.height = (int32)this.min_height;
      size_hints.width  = (int32)this.min_width;
      size_hints.base_height = 0;
      size_hints.base_width  = 0;
//~       this.I.set_wm_normal_hints(this.window, size_hints);
//~       this.surface.set_size((int)this.min_width,(int)this.min_height);
    }*/

    private void move_resize_req(uint x,uint y,uint width,uint height){
        uint32 position[] = { this.pos_x, this.pos_y, this.min_width, this.min_height };
        Global.C.configure_window(this.window, (Xcb.ConfigWindow.X | Xcb.ConfigWindow.Y | Xcb.ConfigWindow.WIDTH | Xcb.ConfigWindow.HEIGHT), position);
    }

    private void resize_req(uint width,uint height){
//~       this.min_width = width;
//~       this.min_height = height;
      if(this.state == WindowState.visible){
        uint32 position[] = { width, height };
        Global.C.configure_window(this.window, ( Xcb.ConfigWindow.WIDTH | Xcb.ConfigWindow.HEIGHT), position);
      }
    }

    public void resize(uint width,uint height){
      if(this.state == WindowState.visible){
        this.resize_req(width,height);
        Global.C.flush();
      }else{
        this.min_width = width;
        this.min_height = height;
      }
    }

    public void move_resize(uint x,uint y, uint width,uint height){
      if(this.state == WindowState.visible){
        this.move_resize_req(x, y, width, height);
        Global.C.flush();
      }else{
        this.pos_x = (int)x;
        this.pos_y = (int)y;
        this.min_width = width;
        this.min_height = height;
      }
    }

    public void load_font_with_size(string fpatch,uint size){
      var F = FontLoader.load(fpatch);
      this.cr.set_font_face(F);
      this.cr.set_font_size (size);
    }


    public void on_configure(Xcb.ConfigureNotifyEvent e){

  //~     var geom = Global.C.get_geometry_reply(Global.C.get_geometry_unchecked(e.window), null);
  //~     GLib.stderr.printf( "on_map x,y=%d,%d w,h=%d,%d response_type=%d ew=%d, w=%d\n",
  //~                       (int)e.x,
  //~                       (int)e.y,
  //~                       (int)e.width,
  //~                       (int)e.height,
  //~                       (int)e.response_type,
  //~                       (int)e.event,
  //~                       (int)e.window
  //~                       );
      GLib.stderr.printf( "on_configure w=%u h=%u \n", this.min_width,this.min_height);
      if( (e.width == 1 && e.height == 1) && (this.min_width != 1 && this.min_height != 1))
        return;//skip first map

      this.pos_x = e.x;
      this.pos_y = e.y;
      if(this.min_width != e.width || this.min_height != e.height){
        this.min_width  = e.width;
        this.min_height = e.height;
        this.window_widget.A.width = this.min_width;
        this.window_widget.A.height = this.min_height;
        this.window_widget.calculate_size_internal();
      }
      GLib.stderr.printf( "on_configure2 w=%u h=%u \n", this.min_width,this.min_height);

      /*
       * there is no way to resize X11 pixmap,
       * we can only destroy old and create newone.
       */
        this.create_pixmap((uint16)this.min_width,(uint16)this.min_height);
//~         Global.C.flush();
//~         Global.C.create_pixmap(Global.screen.root_depth,this.pixmap,Global.screen.root,(uint16)this.min_width,(uint16)this.min_height);
//~       this.pixmap
//~         this.surface.set_size((int)this.min_width,(int)this.min_height);

//~         this.surface.set_drawable(this.pixmap,(int)this.min_width,(int)this.min_height);
        cairo_xcb_surface_set_drawable(this.surface,this.pixmap,(int)this.min_width,(int)this.min_height);
  //~     GLib.stderr.printf( "on_map x,y=%d,%d w,h=%d,%d\n",(int)this.x,(int)this.y,(int)this.min_width,(int)this.min_height);

    }

    public bool process_event(Xcb.GenericEvent event){
      bool _continue = true;

  //~     GLib.stderr.printf( "!!!!!!!!!!!event");
  //~     while (( (event = Global.C.wait_for_event()) != null ) && !finished ) {
//~       while (( (event = Global.C.poll_for_event()) != null ) /*&& !finished*/ ) {
  //~       GLib.stderr.printf( "event=%d expose=%d map=%d\n",(int)event.response_type ,Xcb.EXPOSE,Xcb.CLIENT_MESSAGE);
          switch (event.response_type & ~0x80) {
            case Xcb.EXPOSE:
                /* Avoid extra redraws by checking if this is
                 * the last expose event in the sequence
                 */
                 Xcb.ExposeEvent e = (Xcb.ExposeEvent)event;
                if (e.count != 0)
                    break;

                this.window_widget.draw(this.cr);
                this.surface.flush();
//~                 Global.C.flush();
                Global.C.copy_area(this.pixmap,this.window,this.pixmap_gc, (int16)0,(int16)0,0,0,(int16)this.min_width,(int16)this.min_height);
//~                 Global.C.clear_area(1,this.window, (int16)0,(int16)0,(int16)e.width,(int16)e.height);
            break;
            case Xcb.CLIENT_MESSAGE:
                Xcb.ClientMessageEvent e = (Xcb.ClientMessageEvent)event;
  //~               GLib.stderr.printf( "CLIENT_MESSAGE data32=%d deleteWindowAtom=%d\n", (int)e.data.data32[0],(int)deleteWindowAtom);
                if(e.data.data32[0] == Global.deleteWindowAtom){
    //~                 printf("done\n");
                    _continue = false;
                    Global.loop.quit ();
                }
            break;
            case Xcb.CONFIGURE_NOTIFY:
                if(event.response_type == Xcb.CONFIGURE_NOTIFY)
                  this.on_configure((Xcb.ConfigureNotifyEvent)event);
            break;
          }//switch
  //~         free(event);
//~           Global.C.flush();
//~       }
      return _continue;
    }//process_event

    public void clear_area(uint x,uint y,uint width,uint height){
//~       Global.C.clear_area(1,this.window, (int16)x,(int16)y,(int16)width,(int16)height);
      this.window_widget.draw(this.cr);
      this.surface.flush();
//~       Global.C.clear_area(1,this.window, (int16)0,(int16)0,(int16)width,(int16)height);
      Global.C.copy_area(this.pixmap,this.window,this.pixmap_gc, (int16)0,(int16)0,0,0,(int16)this.min_width,(int16)this.min_height);
      Global.C.flush();
    }//clear_area

  }//calss XcbWindow
  /********************************************************************/
//~   [SimpleType]
//~   [CCode (has_type_id = false)]
  public struct Global{
    public static Xcb.Connection? C;
    private static Xcb.Setup setup;
    private static unowned Xcb.Icccm.Icccm I;
    public static weak Xcb.Screen screen;
    public static Xcb.VisualType? visual;
    public static HashTable<string, Xcb.AtomT?> atoms;
    private static Xcb.AtomT deleteWindowAtom;
    private static MainLoop loop;
    public static GLib.HashTable<Xcb.Window,XcbWindow> windows;

    public  static void Init(){
      Global.atoms = new GLib.HashTable<string, Xcb.AtomT?> (str_hash, str_equal);
      Global.windows = new GLib.HashTable<Xcb.Window,XcbWindow> (direct_hash, direct_equal);
//~       ((GLib.HashTable)Global.windows).ref();
      Global.C = new Xcb.Connection();


      if (Global.C.has_error() != 0) {
              GLib.stderr.printf( "Could not connect to X11 server");
              GLib.Process.exit(1) ;
      }

      Global.I = Xcb.Icccm.new(Global.C);

      Global.setup = Global.C.get_setup();
      var s_iterator = Global.setup.roots_iterator();
      Global.screen = s_iterator.data;

//~       Xcb.AtomT tmp_atom;
      if(!Global.atoms.contains(atom_names.wm_delete_window))
        Global.atoms.insert(atom_names.wm_delete_window,
          Global.C.intern_atom_reply(Global.C.intern_atom(false,atom_names.wm_delete_window)).atom);

      if(!Global.atoms.contains(atom_names.wm_take_focus))
        Global.atoms.insert(atom_names.wm_take_focus,
          Global.C.intern_atom_reply(Global.C.intern_atom(false,atom_names.wm_take_focus)).atom);

      if(!Global.atoms.contains(atom_names._net_wm_ping))
        Global.atoms.insert(atom_names._net_wm_ping,
          Global.C.intern_atom_reply(Global.C.intern_atom(false,atom_names._net_wm_ping)).atom);

      if(!Global.atoms.contains(atom_names._net_wm_sync_request))
        Global.atoms.insert(atom_names._net_wm_sync_request,
          Global.C.intern_atom_reply(Global.C.intern_atom(false,atom_names._net_wm_sync_request)).atom);

      if(!Global.atoms.contains(atom_names.wm_protocols))
        Global.atoms.insert(atom_names.wm_protocols,
          Global.C.intern_atom_reply(Global.C.intern_atom(false,atom_names.wm_protocols)).atom);

      Global.deleteWindowAtom = Global.atoms.lookup(atom_names.wm_delete_window);

      Global.visual = find_visual(Global.C, Global.screen.root_visual);
      if (Global.visual == null) {
//~           printf( "Some weird internal error...?!");
    //~       c.disconnect(); ???
          return;
      }

      Global.loop = new MainLoop ();

      var channel = new IOChannel.unix_new(Global.C.get_file_descriptor());
      channel.add_watch(IOCondition.IN,  (source, condition) => {
          if (condition == IOCondition.HUP) {
          GLib.stderr.printf ("The connection has been broken.\n");
          Global.loop.quit();
          return false;
          }
         Xcb.GenericEvent event;
         bool _return = true;
//~           GLib.stderr.printf( "!!!!!!!!!!!event");
      //~     while (( (event = Global.C.wait_for_event()) != null ) && !finished ) {
          while (( (event = Global.C.poll_for_event()) != null ) /*&& !finished*/ ) {
            switch (event.response_type & ~0x80) {
              case Xcb.EXPOSE:
              case Xcb.CLIENT_MESSAGE:
                 Xcb.ExposeEvent e = (Xcb.ExposeEvent)event;
                 _return = Global.windows.lookup(e.window).process_event(event);
              break;
              case Xcb.CONFIGURE_NOTIFY:
                 Xcb.ConfigureNotifyEvent e = (Xcb.ConfigureNotifyEvent)event;
                 _return = Global.windows.lookup(e.window).process_event(event);
              break;
             }
           Global.C.flush();
          }
          return _return;
        });
  //~     var xcb_source = new GLib.Source();
  //~     xcb_source.set_name("Ltk XCB event source");
  //~     xcb_source.set_callback(run_xcb);
  //~     xcb_source.add_unix_fd(,GLib.IOCondition.IN);
  //~     xcb_source.set_can_recurse(true);
  //~     xcb_source.attach(loop.get_context ());


    }//constructor

    [CCode (cname = "g_main_loop_unref")]
    extern static void loop_unref(GLib.MainLoop loop);

    public static void run(){
      Global.loop.run ();
      GLib.stderr.printf ("atoms.remove_all\n");
      Global.atoms.foreach((k,v)=>{ free((void*)v); });
      Global.atoms.remove_all();
      GLib.stderr.printf ("windows.remove_all\n");
//~       Global.windows.foreach((k,v)=>{ v.window_widget.unref(); });
      Global.windows.remove_all();
      //~     surface.finish();
    FontLoader.destroy();

    GLib.stderr.printf ("Global.C.unref\n");
//~     surface.destroy();
//~     xcb_disconnect(c);
    }//run

  }

  /********************************************************************/
  public class Widget : GLib.Object{
    public weak Widget? parent = null;
    public WidgetList childs;
    private uint _min_width;
    public uint min_width{
      get{ return  this._min_width;}
      set{
        if(value != this._min_width){
          this._min_width = value;
          this.size_changed(this,this.A);
        }
        }
    }
    private uint _min_height;
    public uint min_height{
      get{ return  this._min_height;}
      set{
        if(value != this._min_height){
          this._min_height = value;
          this.size_changed(this,this.A);
        }
        }

    }
//~     public uint x;
//~     public uint y;
    public Allocation A;

    private  SOptions  _fill_mask;
    public  SOptions  fill_mask {
      get{
        return ((SOptions)_fill_mask & (SOptions.fill_horizontal | SOptions.fill_vertical));
      }
      set{
        var tmp = value & (SOptions.fill_horizontal | SOptions.fill_vertical) ;
        if(tmp != (_fill_mask & (SOptions.fill_horizontal | SOptions.fill_vertical))){
          var prev  = this.A;
          _fill_mask &= ~(SOptions.fill_horizontal | SOptions.fill_vertical);
          _fill_mask |= tmp;
          this.size_changed(this,prev);
        }
      }
      default = 0;//do not fill
    }

    private  SOptions  _place_policy;
    public  SOptions  place_policy {
      get{
        return ((SOptions)_place_policy & (SOptions.place_horizontal | SOptions.place_vertical));
      }
      set{
        var tmp = value & (SOptions.place_horizontal | SOptions.place_vertical) ;
        if(tmp != (_place_policy & (SOptions.place_horizontal | SOptions.place_vertical))){
          var prev  = this.A;
          _place_policy &= ~(SOptions.place_horizontal | SOptions.place_vertical);
          _place_policy |= tmp;
          this.size_changed(this,prev);
        }
      }
      default = SOptions.place_horizontal;
    }

    public signal void size_changed(Widget src,Allocation old);//for parents

    public virtual uint get_prefered_width(){
      return this.min_width;
    }
    public virtual uint get_prefered_height(){
      return this.min_height;
    }

    public  bool visible {
      get{
        return ((A.options & SOptions.visible) > 0);
      }
      set{
        var prev  = this.A;
        if( value != ((A.options & SOptions.visible) > 0) ){
          this.A.options |= SOptions.visible;
        }else{
          this.A.options &= ~(SOptions.visible);
        }
        this.size_changed(this,prev);

      }
      default = true;
    }

    public Widget(Widget? parent = null){
      GLib.Object();
      this.childs = new WidgetList();
//~       this.x = this.y = 0;
      if(parent != null)
        this.parent = parent;
    }//create

    ~Widget(){
      this.childs.remove_all();
      GLib.stderr.printf("~Widget\n");
    }

    public virtual bool draw(Cairo.Context cr){
        cr.save();
        cr.set_line_width(2);
        cr.set_source_rgb(0, 0, 0);
        cr.rectangle (this.A.x, this.A.y, this.A.width, this.A.height);
        cr.stroke ();
        cr.restore();
      return true;//continue
    }//draw

    public virtual void show(){
      this.visible = true;
    }
    public virtual void hide(){
      this.visible = false;
    }
  }
  /********************************************************************/
  public class Container: Widget{
    private bool _calculating_size = false;
//~     private uint extra_width  =0;
//~     private uint extra_height =0;
    private uint size_changed_serial = 0;
    private uint size_update_width_serial = 0;
    private uint size_update_height_serial = 0;
    public Container(){
      base();
      this.fill_mask = Ltk.SOptions.fill_vertical | Ltk.SOptions.fill_horizontal;
    }

    private void on_size_changed(Widget src, Allocation prev){

        if(this._calculating_size)  return;
        this.size_changed_serial++;

        int diff_width = ((int)src.min_width - (int)src.A.width);
        int diff_height = ((int)src.min_height - (int)src.A.height);

//~         if( diff_width < 0 && (this.fill_mask & Ltk.SOptions.fill_horizontal)>0){
//~           diff_width = 0;//ignore if size lowering
//~         }
//~         if( diff_height < 0 && (this.fill_mask & Ltk.SOptions.fill_vertical)>0){
//~           diff_height = 0;//ignore if size lowering
//~         }
//~         if(src.min_width < src.A.width){
//~           if(this.extra_width > diff_width){
//~             diff_width = 0; //don't request width;
//~           }
//~         }

//~         if(src.min_height > src.A.height){
//~           if(this.extra_height > diff_height){
//~             diff_height = 0; //don't request height;
//~           }
//~         }
        GLib.stderr.printf("diff_width=%d diff_height=%d\n",diff_width,diff_height);

        if(diff_height != 0 || diff_width != 0){
            this.update_childs_sizes();

//~           this.size_request(((int)this.min_width + diff_width),((int)this.min_height + diff_height));
//~           Ltk.Widget? widget = this.parent;
//~           while( widget != null){
//~             if( widget is Ltk.Container ){
//~               ((Ltk.Container)widget).
//~               break;
//~             }else{
//~               widget = this.parent;
//~             }
//~           }
        }
    }

    public virtual void size_request(uint new_width, uint new_height){
      bool resize_inside = false;
      GLib.stderr.printf("size_request new=%u,%u min=%u,%u A=%u,%u childs=%u\n",new_width, new_height,this.min_width,this.min_height,this.A.width,this.A.height,this.childs.count);
      if( /*new_width >= this.min_width &&*/ (new_width <= this.A.width)   ){
        if( /*new_height >= this.min_height &&*/ (new_height <= this.A.height)  ){
          uint oldw = this.A.width;
          uint oldh = this.A.height;
          this.calculate_size(ref oldw,ref oldh);
          return;
        }
      }
      GLib.stderr.printf("size_request from parent\n");
      Ltk.Widget? widget = this.parent;
      while( widget != null){
        if( widget is Ltk.Container ){
          ((Ltk.Container)widget).size_request(new_width, new_height);
          break;
        }else{
          widget = this.parent;
        }
      }
    }//size_request

    public void add(Widget child){
      if(this.childs.find(child) == null && child.parent == null){
        child.parent = this;
        this.childs.append(child);
        this.on_size_changed(child,child.A);
        child.size_changed.connect(this.on_size_changed);
        this.update_childs_sizes();
      }
    }

    public virtual void update_childs_sizes(){

      uint oldw = this.A.width;
      uint oldh = this.A.height;
      this.calculate_size(ref oldw,ref oldh);
//~       this.A.width = oldw;
//~       this.A.height = oldh;
//~       this.size_request(oldw, oldh);
    }

    public void remove(Widget child){
      if(this.childs.find(child) != null){
        this.childs.remove(child);
        child.parent = null;
        this.update_childs_sizes();
      }
    }

    public override uint get_prefered_width(){
      int h = -1;
      uint wmin,wmax;
      this.get_width_for_height(h,out wmin,out wmax);
      this.min_width = (this.place_policy == SOptions.place_horizontal? wmax : wmin);
      return this.min_width;
    }
    public override uint get_prefered_height(){
      int w = -1;
      uint hmin,hmax;
      this.get_height_for_width(w,out hmin,out hmax);
      this.min_height = (this.place_policy == SOptions.place_vertical? hmax : hmin);
      return this.min_height;
    }

    public virtual void get_height_for_width(int width,out uint height_min,out uint height_max){
      uint _h;
      if(this.size_update_height_serial != this.size_changed_serial){
        foreach(var w in this.childs){
          _h = w.get_prefered_height();
          height_min = uint.max(height_min, _h);
          height_max = (this.place_policy == SOptions.place_vertical ? height_max + _h : height_min);
        }
        this.size_update_height_serial = this.size_changed_serial;
      }else{
        height_min = this.min_height;
        height_max = height_min;//uint.max(this.A.height,height_min);
      }
    }
    public virtual void get_width_for_height(int height,out uint width_min,out uint width_max){
      uint _w;
      if(this.size_update_width_serial != this.size_changed_serial){
        foreach(var w in this.childs){
          _w = w.get_prefered_width();
          width_min = uint.max( width_min, _w );
          width_max = (this.place_policy == SOptions.place_horizontal ? width_max + _w : width_min);
          GLib.stderr.printf( "get_width_for_height1 min=%u max=%u label=%s\n",_w,width_max, ( (w is Button ) ? ((Button)w).label: "") );
        }
        this.size_update_width_serial = this.size_changed_serial;
      }else{
        width_min = this.min_width;
        width_max = width_min;//uint.max(this.A.width,width_min);
      }
      GLib.stderr.printf( "get_width_for_height2 min=%u max=%u\n",width_min,width_max);
    }
    public virtual void calculate_size(ref uint calc_width,ref uint calc_height){
      GLib.stderr.printf( "container calculate_size w=%u h=%u loop=%d childs=%u\n", this.min_width,this.min_height,(int)this._calculating_size,this.childs.count);
      if(this._calculating_size)
        return;
      int _w = -1;
      int _h = -1;
      uint hmin,hmax,wmin,wmax;

      this._calculating_size=true;

      this.get_prefered_height();
      this.get_prefered_width();

      if(this.A.width >= this.min_width &&
         this.A.height >= this.min_height &&
         this.A.width == calc_width &&
         this.A.height == calc_height){
            this._calculating_size=false;
            GLib.stderr.printf( "container quick end. calculate_size w=%u h=%u loop=%d childs=%u\n", this.min_width,this.min_height,(int)this._calculating_size,this.childs.count);
            return;
      }
//~         this.get_height_for_width(_w,out hmin,out hmax);
//~         this.get_width_for_height(_h,out wmin,out wmax);

        /*if(this.place_policy == SOptions.place_horizontal){
          this.min_width = wmax;
          this.min_height = hmin;
        }else{
          this.min_width = wmin;
          this.min_height = hmax;
        }*/

        GLib.stderr.printf( "this.fill_mask=%d\n",this.fill_mask );
        GLib.stderr.printf( "calc_width=%u wmax=%u\n",calc_width , this.min_width );
        GLib.stderr.printf( "calc_height=%u hmax=%u\n",calc_height , this.min_height );
//~         if((this.fill_mask & Ltk.SOptions.fill_horizontal) > 0 && calc_width > this.min_width){
//~           this.min_width = calc_width;
//~         }


//~         if((this.fill_mask & Ltk.SOptions.fill_vertical) > 0 && calc_height > this.min_height){
//~           this.min_height = calc_height;
//~         }
        if(calc_width < this.min_width)
          calc_width = this.min_width;
        if(calc_height < this.min_height)
          calc_height = this.min_height;

        if(this.A.width == 0)
          this.A.width = calc_width;//= this.min_width;
        if(this.A.height == 0)
          this.A.height = calc_height;//= this.min_height;

        if(this.place_policy == Ltk.SOptions.place_horizontal){
          GLib.stderr.printf("SOptions.place_horizontal min=%u,%u A=%u,%u\n",this.min_width,this.min_height,this.A.width,this.A.height);
          //set sizes for childs

          uint extra_width_delta = this.A.width;

          GLib.stderr.printf("childs.length=%u \n",this.childs.count);
//~           if( this.childs.count > this.childs.fixed_width_count &&
//~               this.A.width > this.childs.fixed_width ){
//~             GLib.stderr.printf("A.w=%u fixed_width=%u count=%u fixed_width_count=%u\n",this.A.width,this.childs.fixed_width, this.childs.count,this.childs.fixed_width_count);
//~             extra_width_delta = (this.A.width - this.childs.fixed_width)/(this.childs.count-this.childs.fixed_width_count);
//~           }
          if(extra_width_delta > this.childs.min_width_sum){
            extra_width_delta -= this.childs.fixed_width;
            extra_width_delta = extra_width_delta/(this.childs.count-this.childs.fixed_width_count);


          }else{
            extra_width_delta = 0;
          }

          GLib.stderr.printf("w=%u extra_width_delta=%u\n",this.A.width, extra_width_delta);

          foreach(var w in this.childs){
              w.A.width = w.min_width;
              w.A.height = w.min_height;
          }
          //_variable_width is sorted,first bigger then smallier
          foreach(var w in this.childs._variable_width){

  //~           w.A.x = 0;
  //~           w.A.y = 0;

            if( (w.fill_mask & Ltk.SOptions.fill_horizontal) > 0 ){
              if( extra_width_delta >= w.min_width){
                w.A.width = extra_width_delta;
              }else{
                w.A.width = w.min_width;
                //100 | 100
                //x   | 150
                if(extra_width_delta > 0){
                  uint dela_minus = (w.min_width-extra_width_delta);
                  if(extra_width_delta > dela_minus){
                    extra_width_delta -= dela_minus;
                  }else{
                    extra_width_delta = 0;//hmm, something wrong
                  }
                }
              }
            }else{
                w.A.width = w.min_width;
            }
            if((w.fill_mask & Ltk.SOptions.fill_vertical) > 0){
              w.A.height = this.min_height;
            }else{
              w.A.height = w.min_height;
            }
            GLib.stderr.printf("A w=%u h=%u\n",w.A.width,w.A.height);

            if(w is Ltk.Container){
              ((Ltk.Container)w).calculate_size(ref w.A.width,ref w.A.height);
            }

            w.A.options ^= w.A.options;
            w.A.options |= w.place_policy;
            w.A.options |= w.fill_mask;

          }//foreach childs
        }else{//SOptions.place_vertical
          GLib.stderr.printf("SOptions.place_vertical min=%u,%u A=%u,%u\n",this.min_width,this.min_height,this.A.width,this.A.height);
          //set sizes for childs
          uint extra_height_delta = 0;

          GLib.stderr.printf("childs.length=%u \n",this.childs.count);
          extra_height_delta = (this.A.height - this.min_height)/this.childs.count;
          GLib.stderr.printf("h=%u extra_height_delta=%u\n",this.A.height, extra_height_delta);


          foreach(var w in this.childs){
  //~           w.A.x = 0;
  //~           w.A.y = 0;

            if((w.fill_mask & Ltk.SOptions.fill_horizontal) > 0){
              w.A.width = this.min_width;
            }else{
              w.A.width = w.get_prefered_width();
            }
            if((w.fill_mask & Ltk.SOptions.fill_vertical) > 0 ){
              w.A.height = w.min_height + extra_height_delta;
            }else{
              w.A.height = w.min_height;
            }
            GLib.stderr.printf("A w=%u h=%u\n",w.A.width,w.A.height);

            if(w is Ltk.Container){
              ((Ltk.Container)w).calculate_size(ref w.A.width,ref w.A.height);
            }
            w.A.options ^= w.A.options;
            w.A.options |= w.place_policy;
            w.A.options |= w.fill_mask;
          }//foreach childs
        }//SOptions.place_vertical
      GLib.stderr.printf( "container end calculate_size w=%u h=%u loop=%d childs=%u\n", this.min_width,this.min_height,(int)this._calculating_size,this.childs.count);

      this._calculating_size=false;
    }

    public override bool draw(Cairo.Context cr){
        uint len = this.childs.count;
        uint _x = 0, _y = 0, _w = 0, _h = 0;
        cr.save();
        cr.set_line_width(4);
        cr.set_source_rgb(1, 0, 0);
        GLib.stderr.printf( "container x,y=%u,%u w,h=%u,%u childs=%u\n",this.A.x, this.A.y, this.A.width, this.A.height, this.childs.count);
        cr.rectangle (this.A.x, this.A.y, this.A.width, this.A.height);
        cr.stroke ();
        cr.restore();
        foreach(var w in this.childs){
          cr.save();
            GLib.stderr.printf( "childs draw %d\n",(int)w.A.width);
  //~           cr.move_to ();
            if(this.place_policy == SOptions.place_horizontal){
              cr.translate (_x,(this.A.height-w.A.height)/2);
              _x+=w.A.width;
            }else{
              cr.translate ((this.A.width-w.A.width)/2,_y);
              _y+=w.A.height;
            }
            cr.rectangle (0, 0,w.A.width/*+border.left+border.right*/, w.A.height/*+border.top+border.bottom*/);
            cr.clip ();
            w.draw(cr);
          cr.restore();

        }//foreach
        return base.draw(cr);
      }
  }//class container
  /********************************************************************/
  public class Window: Container{
    private XcbWindow window;
    private bool _calculating_size = false;
    private string? title = null;

    public Window(){

      base();
      this.min_width=this.min_height=1;

      this.window = new XcbWindow(this);
//~       return base(null);
    }

    ~Window(){
      GLib.stderr.printf("~Window\n");
    }

    public void set_size(uint width,uint height){
        this.window.resize(width,height);
    }

    public override bool draw(Cairo.Context cr){
      string text="HELLO :) Проверка ЁЙ Русский язык اللغة العربية English language اللغة العربية";
      cr.save();
        cr.set_source_rgb(0, 1, 0);
        cr.paint();

        cr.set_source_rgb(1, 0, 0);
        cr.move_to(0, 0);
        cr.line_to(this.A.width, 0);
        cr.line_to(this.A.width, this.A.height);
        cr.close_path();
        cr.fill();

        cr.set_source_rgb(0, 0, 1);
        cr.set_line_width(20);
        cr.move_to(0, this.A.height);
        cr.line_to(this.A.width, 0);
        cr.stroke();
        cr.move_to( 2, this.A.height-10);
        cr.show_text( text);
        cr.stroke ();
      cr.restore();
//~       GLib.stderr.printf( "childs draw %d\n",(int)this.childs.length());
//~       this.A.width = this.min_width;
//~       this.A.height = this.min_height;
      return base.draw(cr);
    }//draw


    public override void calculate_size(ref uint calc_width,ref uint calc_height){
      GLib.stderr.printf( "window calculate_size\n");
      base.calculate_size(ref calc_width,ref calc_height);
      if(calc_width >this.A.width||
         calc_height >this.A.height){
           this.window.resize(calc_width,calc_height);
      }
    }

    public void calculate_size_internal(){
      GLib.stderr.printf( "window calculate_size min=%u,%u A=%u,%u loop=%d\n", this.min_width,this.min_height,this.A.width,this.A.height,(int)this._calculating_size);

      if(this._calculating_size)
        return;
      this._calculating_size=true;
      bool force_resize = false;
      uint oldw = this.A.width;
      uint oldh = this.A.height;
      uint neww = oldw;
      uint newh = oldh;
      GLib.stderr.printf( "1 w=%u h=%u\n", this.min_width,this.min_height);

      this.calculate_size(ref neww,ref newh);

      GLib.stderr.printf( "2 w=%u h=%u\n", this.min_width,this.min_height);

      if(this.min_height > oldh || this.min_width > oldw){
        force_resize=true;
      }
      //this.A.height =
      this.min_height = uint.max(this.min_height, oldh);
      //this.A.width =
      this.min_width = uint.max(this.min_width, oldw);
      GLib.stderr.printf( "4 w=%u h=%u\n", this.min_width,this.min_height);

      /*if( (this.fill_mask & ContainerFillPolicy.fill_height) >0 && this.childs.length() > 0){
        this.childs.first ().data.height = this.min_height;
      }

      if( (this.fill_mask & ContainerFillPolicy.fill_width) >0 && this.childs.length() > 0){
        this.childs.first ().data.width = this.min_width;
      }*/

      if(force_resize){
        GLib.stderr.printf( "3 w=%u h=%u\n", this.min_width,this.min_height);
        this.window.resize(this.min_width,this.min_height);
      }

      this._calculating_size=false;

    }
//~     public override void calculate_size(ref calc_width,ref calc_height){
//~     }//calculate_size
    public override void size_request(uint new_width, uint new_height){

//~       if(this.A.width != new_width || this.A.height != new_height){
        uint _w = this.min_width, _h = this.min_height;
  //~       if( new_width > _w  )
          _w = new_width;
  //~       if( new_height > _h)
          _h = new_height;
        GLib.stderr.printf( "window size_request=%u,%u\n", _w,_h);
        this.set_size(_w,_h);
//~       }
    }

    public override void update_childs_sizes(){
      base.update_childs_sizes();
      this.size_request(this.A.width, this.A.height);
    }


    public void set_title(string title){
      this.window.set_title(title);
    }
    public void load_font_with_size(string fpatch,uint size){
      this.window.load_font_with_size(fpatch, size);
    }
    public void clear_area(uint x,uint y,uint width,uint height){
      this.window.clear_area(x, y, width, height);
    }

    public override void show(){
      base.show();
      this.window.show();
    }


  }//class Window


  /********************************************************************/

  public class Button: Widget{
    public string? label = null;
    public Button(string? label = null){
      base();
      this.label = label;
      this.min_width = 50;
      this.min_height = 50;
    }
    public override bool draw(Cairo.Context cr){
      GLib.stderr.printf( "Button draw %s\n",this.get_class().get_name());
      cr.set_source_rgb(0.5, 1, 0.5);
         cr.rectangle (this.A.x, this.A.y,this.A.width/*+border.left+border.right*/, this.A.height/*+border.top+border.bottom*/);
         cr.fill ();
         if(this.label != null){
          cr.set_source_rgb(0.1, 0.1, 0.1);
          cr.move_to(0,this.min_height/2);
          cr.show_text(this.label);
          }
         cr.stroke ();
      base.draw(cr);
//~       cr.paint();
      return true;//continue
    }//draw
  }
}//namespace Ltk
