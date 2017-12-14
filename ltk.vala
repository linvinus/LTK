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
  [SimpleType]
  [CCode (has_type_id = false)]
  public enum ContainerFillPolicy{
    fill_width=1,
    fill_height=2
  }
  [SimpleType]
  [CCode (has_type_id = false)]
  public enum SizePolicy{
    horizontal=1,
    vertical=2
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
  [SimpleType]
  [CCode (has_type_id = false)]
  public struct Allocation{
    uint x;
    uint y;
    uint width;
    uint height;
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
              this.move_resize_req(this.pos_x, this.pos_y, this.width, this.height);
            }else{
              this.resize_req(this.width, this.height);
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
    private uint width;
    private uint height;

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
//~       uint32 position[] = { this.pos_x, this.pos_y, this.width, this.height };
//~       Global.C.configure_window(this.window, (Xcb.ConfigWindow.X | Xcb.ConfigWindow.Y | Xcb.ConfigWindow.WIDTH | Xcb.ConfigWindow.HEIGHT), position);

    }

    public XcbWindow(Ltk.Window window_widget){
      this.window_widget = window_widget;
      this.state = WindowState.unconfigured;
      this.window = Global.C.generate_id();
      this.width = 1;
      this.height = 1;
      uint32 values[2];

      this.create_pixmap(1,1);

      values[0] = this.pixmap;
      values[1] = Xcb.EventMask.EXPOSURE|Xcb.EventMask.VISIBILITY_CHANGE|Xcb.EventMask.STRUCTURE_NOTIFY;

      Global.C.create_window(Xcb.COPY_FROM_PARENT, this.window, Global.screen.root,
                (int16)this.pos_x, (int16)this.pos_y, (uint16)this.width, (uint16)this.height, 0,
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


      this.surface = new Cairo.XcbSurface(Global.C, this.pixmap, Global.visual, (int)this.width, (int)this.height);
      this.cr = new Cairo.Context(this.surface);

      Global.windows.insert(this.window,this);
    }//XcbWindow

    ~XcbWindow(){
      GLib.stderr.printf("~XcbWindow\n");
      this.surface.finish();//When the last call to cairo_surface_destroy() decreases the reference count to zero, cairo will call cairo_surface_finish()
      Global.windows.remove(this.window);
      Global.C.free_gc(this.pixmap_gc);
      Global.C.free_pixmap(this.pixmap);
      Global.C.destroy_window(this.window);
      Global.C.flush();
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
      size_hints.height = (int32)this.height;
      size_hints.width  = (int32)this.width;
      size_hints.base_height = 0;
      size_hints.base_width  = 0;
//~       this.I.set_wm_normal_hints(this.window, size_hints);
//~       this.surface.set_size((int)this.width,(int)this.height);
    }*/

    private void move_resize_req(uint x,uint y,uint width,uint height){
        uint32 position[] = { this.pos_x, this.pos_y, this.width, this.height };
        Global.C.configure_window(this.window, (Xcb.ConfigWindow.X | Xcb.ConfigWindow.Y | Xcb.ConfigWindow.WIDTH | Xcb.ConfigWindow.HEIGHT), position);
    }

    private void resize_req(uint width,uint height){
      this.width = width;
      this.height = height;
      if(this.state == WindowState.visible){
        uint32 position[] = { width, height };
        Global.C.configure_window(this.window, ( Xcb.ConfigWindow.WIDTH | Xcb.ConfigWindow.HEIGHT), position);
      }
    }

    public void resize(uint width,uint height){
      this.width = width;
      this.height = height;
      if(this.state == WindowState.visible){
        this.resize_req(this.width,this.height);
      }
    }

    public void move_resize(uint x,uint y, uint width,uint height){
      this.pos_x = (int)x;
      this.pos_y = (int)y;
      this.width = width;
      this.height = height;
      if(this.state == WindowState.visible){
        this.move_resize_req(this.pos_x, this.pos_y, this.width, this.height);
      }
    }
    public void set_size(uint width,uint height){
        this.resize(width, height);
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
  //~     GLib.stderr.printf( "on_map2 w=%u h=%u \n", this.width,this.height);
      if( (e.width == 1 && e.height == 1) && (this.width != 1 && this.height != 1))
        return;//skip first map

      this.pos_x = e.x;
      this.pos_y = e.y;
      if(this.width != e.width || this.height != e.height){
        this.width  = e.width;
        this.height = e.height;
        this.window_widget.width = this.width;
        this.window_widget.height = this.height;
        this.window_widget.calculate_size_internal();
      }
      /*
       * there is no way to resize X11 pixmap,
       * we can only destroy old and create newone.
       */
        this.create_pixmap((uint16)this.width,(uint16)this.height);
//~         Global.C.flush();
//~         Global.C.create_pixmap(Global.screen.root_depth,this.pixmap,Global.screen.root,(uint16)this.width,(uint16)this.height);
//~       this.pixmap
//~         this.surface.set_size((int)this.width,(int)this.height);

//~         this.surface.set_drawable(this.pixmap,(int)this.width,(int)this.height);
        cairo_xcb_surface_set_drawable(this.surface,this.pixmap,(int)this.width,(int)this.height);
  //~     GLib.stderr.printf( "on_map x,y=%d,%d w,h=%d,%d\n",(int)this.x,(int)this.y,(int)this.width,(int)this.height);

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
                Global.C.copy_area(this.pixmap,this.window,this.pixmap_gc, (int16)0,(int16)0,0,0,(int16)this.width,(int16)this.height);
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
      Global.C.copy_area(this.pixmap,this.window,this.pixmap_gc, (int16)0,(int16)0,0,0,(int16)this.width,(int16)this.height);
      Global.C.flush();
    }//clear_area

  }//calss XcbWindow
  /********************************************************************/
//~   [SimpleType]
//~   [CCode (has_type_id = false)]
  public struct Global{
    public static  Xcb.Connection C;
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
      //~     GLib.stderr.printf( "!!!!!!!!!!!event");
      //~     while (( (event = Global.C.wait_for_event()) != null ) && !finished ) {
          while (( (event = Global.C.poll_for_event()) != null ) /*&& !finished*/ ) {
            switch (event.response_type & ~0x80) {
              case Xcb.EXPOSE:
              case Xcb.CLIENT_MESSAGE:
                 Xcb.ExposeEvent e = (Xcb.ExposeEvent)event;
                 Global.windows.lookup(e.window).process_event(event);
              break;
              case Xcb.CONFIGURE_NOTIFY:
                 Xcb.ConfigureNotifyEvent e = (Xcb.ConfigureNotifyEvent)event;
                 Global.windows.lookup(e.window).process_event(event);
              break;
             }
           Global.C.flush();
          }
          return true;
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
//~     surface.destroy();
//~     xcb_disconnect(c);
    }//run

  }

  /********************************************************************/
  public class Widget : GLib.Object{
    public weak Widget? parent;
    public GLib.List<Widget> childs;
    public uint width;
    public uint height;
    public uint x;
    public uint y;
    public Allocation A;
    private ContainerFillPolicy _fill_mask;
    public  ContainerFillPolicy  fill_mask {
      get{
        return _fill_mask;
      }
      set{
        if(value != this._fill_mask){
          this._fill_mask = value;
          this.size_changed(this);
        }
      }
      default = 0;
    }
    private SizePolicy _size_policy;
    public  SizePolicy  size_policy {
      get{
        return this._size_policy;
      }
      set{
        if(value != this._size_policy){
          this._size_policy = value;
          this.size_changed(this);
        }
      }
      default = SizePolicy.horizontal;
      }
    public signal void size_changed(Widget src);//for parents

    public virtual uint get_prefered_width(){
      return this.width;
    }
    public virtual uint get_prefered_height(){
      return this.height;
    }
    private bool  _visible;
    public  bool visible {
      get{
        return this._visible;
      }
      set{
        if(value != this._visible){
          this._visible = value;
          this.size_changed(this);
        }
      }
      default = false;
      }


    public Widget(Widget? parent = null){
      GLib.Object();
      this.x = this.y = 0;
      if(parent != null)
        this.parent = parent;
    }//create

    ~Widget(){
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
    private GLib.List<weak Widget> _childs_fixed_height;
    private GLib.List<weak Widget> _childs_fixed_width;
    private uint extra_width =0;
    private uint extra_height =0;
    public Container(){
      base();
      this.fill_mask = ContainerFillPolicy.fill_height|ContainerFillPolicy.fill_width;
    }

    private void on_size_changed(Widget src){
        if( (src.fill_mask & Ltk.ContainerFillPolicy.fill_height) == 0 ){
            if(this._childs_fixed_height.find(src) == null)
              this._childs_fixed_height.append(src);
        }else{
            unowned GLib.List<Widget> elm = this._childs_fixed_height.find(src);
            if( elm != null)
              this._childs_fixed_height.remove(src);
        }

        if( (src.fill_mask & Ltk.ContainerFillPolicy.fill_width) == 0 ){
            if( this._childs_fixed_width.find(src) == null)
              this._childs_fixed_width.append(src);
        }else{
            unowned GLib.List<Widget> elm = this._childs_fixed_width.find(src);
            if( elm != null)
              this._childs_fixed_width.remove(src);
        }
    }

    public virtual void size_request(uint new_width, uint new_height){
      bool resize_inside = false;
      if(new_width < (this.width + this.extra_width)  ){
        if( new_height < (this.height + this.extra_height )  ){
          uint oldw = this.width;
          uint oldh = this.height;
          this.calculate_size(ref oldw,ref oldh);
          return;
        }
      }
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
      child.parent = this;
      this.childs.append(child);
      this.on_size_changed(child);
      child.size_changed.connect(this.on_size_changed);
      this.update_childs_sizes();
    }

    public void update_childs_sizes(){
      uint oldw = this.width;
      uint oldh = this.height;
      this.calculate_size(ref oldw,ref oldh);
      this.size_request(oldw, oldh);
    }

    public void remove(Widget child){
      this.childs.remove(child);
      unowned GLib.List<Widget> elm = this._childs_fixed_height.find(child);
      if( elm != null)
        this._childs_fixed_height.remove(child);

      elm = this._childs_fixed_width.find(child);
      if( elm != null)
        this._childs_fixed_width.remove(child);

      this.update_childs_sizes();
    }

    public override uint get_prefered_width(){
      int h = -1;
      uint wmin,wmax;
      this.get_width_for_height(h,out wmin,out wmax);
      return (this.size_policy == SizePolicy.horizontal? wmax : wmin);
    }
    public override uint get_prefered_height(){
      int w = -1;
      uint hmin,hmax;
      this.get_height_for_width(w,out hmin,out hmax);
      return (this.size_policy == SizePolicy.vertical? hmax : hmin);
    }

    public virtual void get_height_for_width(int width,out uint height_min,out uint height_max){
      uint _h;
      foreach(var w in this.childs){
        _h = w.get_prefered_height();
        height_min = uint.max(height_min, _h);
        height_max = (this.size_policy == SizePolicy.vertical ? height_max + _h : height_min);
      }
    }
    public virtual void get_width_for_height(int height,out uint width_min,out uint width_max){
      uint _w;
      foreach(var w in this.childs){
        _w = w.get_prefered_width();
        width_min = uint.max(width_min,_w);
        width_max = (this.size_policy == SizePolicy.horizontal ? width_max + _w : width_min);
      }
    }
    public virtual void calculate_size(ref uint calc_width,ref uint calc_height){
      GLib.stderr.printf( "container calculate_size w=%u h=%u loop=%d childs=%u\n", this.width,this.height,(int)this._calculating_size,this.childs.length());
      if(this._calculating_size)
        return;
      int _w = -1;
      int _h = -1;
      uint hmin,hmax,wmin,wmax;
      this._calculating_size=true;
        this.get_height_for_width(_w,out hmin,out hmax);
        this.get_width_for_height(_h,out wmin,out wmax);

        if(this.size_policy == SizePolicy.horizontal){
          this.width = wmax;
          this.height = hmin;
        }else{
          this.width = wmin;
          this.height = hmax;
        }

        GLib.stderr.printf( "this.fill_mask=%d\n",this.fill_mask );
        GLib.stderr.printf( "calc_width=%u wmax=%u\n",calc_width , wmax );
        GLib.stderr.printf( "calc_height=%u hmax=%u\n",calc_height , hmax );
        if((this.fill_mask & Ltk.ContainerFillPolicy.fill_width) > 0 && calc_width > wmax){
          this.width = calc_width;
        }


        if((this.fill_mask & Ltk.ContainerFillPolicy.fill_height) > 0 && calc_height > hmax){
          this.height = calc_height;
        }

        calc_width=this.width;
        calc_height=this.height;

        if(this.size_policy == SizePolicy.horizontal){
          GLib.stderr.printf("SizePolicy.horizontal w=%u h=%u\n",this.width,this.height);
          //set sizes for childs
          uint _childs_fixed_width_sum = 0;
          foreach(var w in this._childs_fixed_width){
            _childs_fixed_width_sum += w.width;
          }

          this.extra_width = this.width - _childs_fixed_width_sum;
          uint extra_width_delta = 0;

          GLib.stderr.printf("childs.length=%u _childs_fixed_width.length=%u\n",this.childs.length(),this._childs_fixed_width.length());
          if( (this.childs.length() > this._childs_fixed_width.length())){
            extra_width_delta = this.extra_width/(this.childs.length() - this._childs_fixed_width.length());
          }else{
            extra_width_delta = this.extra_width;
          }
          GLib.stderr.printf("w=%u fw=%u extra_width_delta=%u\n",this.width, _childs_fixed_width_sum, extra_width_delta);

          foreach(var w in this.childs){
  //~           w.A.x = 0;
  //~           w.A.y = 0;
            if(this._childs_fixed_width.find(w) == null){
              w.A.width = extra_width_delta;
            }else{
              w.A.width = w.width;
            }
            if(this._childs_fixed_height.find(w) == null){
              w.A.height = this.height;
            }else{
              w.A.height = w.height;
            }
            GLib.stderr.printf("A w=%u h=%u\n",w.A.width,w.A.height);

            if(w is Ltk.Container){
              ((Ltk.Container)w).calculate_size(ref w.A.width,ref w.A.height);
            }

          }//foreach childs
        }else{//SizePolicy.vertical
          GLib.stderr.printf("SizePolicy.vertical w=%u h=%u\n",this.width,this.height);
          //set sizes for childs
          uint _childs_fixed_height_sum = 0;
          foreach(var w in this._childs_fixed_height){
            _childs_fixed_height_sum += w.height;
          }
          this.extra_height = this.height - _childs_fixed_height_sum;
          uint extra_height_delta = 0;


          GLib.stderr.printf("childs.length=%u _childs_fixed_height.length=%u\n",this.childs.length(),this._childs_fixed_height.length());

          if((this.childs.length() > this._childs_fixed_height.length())){
            extra_height_delta = this.extra_height/(this.childs.length() - this._childs_fixed_height.length());
          }else{
            extra_height_delta = this.extra_height;
          }

          GLib.stderr.printf("h=%u fh=%u extra_height_delta=%u\n",this.height, _childs_fixed_height_sum, extra_height_delta);

          foreach(var w in this.childs){
  //~           w.A.x = 0;
  //~           w.A.y = 0;
            if(this._childs_fixed_width.find(w) == null){
              w.A.width = this.width;
            }else{
              w.A.width = w.width;
            }
            if(this._childs_fixed_height.find(w) == null){
              w.A.height = extra_height_delta;
            }else{
              w.A.height = w.height;
            }
            GLib.stderr.printf("A w=%u h=%u\n",w.A.width,w.A.height);

            if(w is Ltk.Container){
              ((Ltk.Container)w).calculate_size(ref w.A.width,ref w.A.height);
            }

          }//foreach childs
        }//SizePolicy.vertical
      this._calculating_size=false;
    }

    public override bool draw(Cairo.Context cr){
        uint len = this.childs.length();
        uint _x = 0, _y = 0, _w = 0, _h = 0;
        cr.save();
        cr.set_line_width(4);
        cr.set_source_rgb(1, 0, 0);
        GLib.stderr.printf( "container x,y=%u,%u w,h=%u,%u childs=%u\n",this.A.x, this.A.y, this.A.width, this.A.height, this.childs.length());
        cr.rectangle (this.A.x, this.A.y, this.A.width, this.A.height);
        cr.stroke ();
        cr.restore();
        foreach(var w in this.childs){
          cr.save();
  //~           GLib.stderr.printf( "childs draw %d\n",(int)w.width);
  //~           cr.move_to ();
            if(this.size_policy == SizePolicy.horizontal){
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
      this.width=this.height=1;

      this.window = new XcbWindow(this);
//~       return base(null);
    }

    ~Window(){
      GLib.stderr.printf("~Window\n");
    }

    public void set_size(uint width,uint height){
        this.window.set_size(width,height);
    }

    public override bool draw(Cairo.Context cr){
      string text="HELLO :) Проверка ЁЙ Русский язык اللغة العربية English language اللغة العربية";
      cr.save();
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
        cr.stroke ();
      cr.restore();
//~       GLib.stderr.printf( "childs draw %d\n",(int)this.childs.length());
      this.A.width = this.width;
      this.A.height = this.height;
      return base.draw(cr);
    }//draw




    public void calculate_size_internal(){
      GLib.stderr.printf( "window calculate_size w=%u h=%u loop=%d\n", this.width,this.height,(int)this._calculating_size);

      if(this._calculating_size)
        return;
      this._calculating_size=true;
      bool force_resize = false;
      uint oldw = this.width;
      uint oldh = this.height;
      uint neww = this.width;
      uint newh = this.height;
      GLib.stderr.printf( "1 w=%u h=%u\n", this.width,this.height);

      this.calculate_size(ref neww,ref newh);

      GLib.stderr.printf( "2 w=%u h=%u\n", this.width,this.height);

      if(this.height > oldh || this.width > oldw){
        force_resize=true;
      }
      this.A.height = this.height = uint.max(this.height, oldh);
      this.A.width = this.width = uint.max(this.width, oldw);
      GLib.stderr.printf( "4 w=%u h=%u\n", this.width,this.height);

      /*if( (this.fill_mask & ContainerFillPolicy.fill_height) >0 && this.childs.length() > 0){
        this.childs.first ().data.height = this.height;
      }

      if( (this.fill_mask & ContainerFillPolicy.fill_width) >0 && this.childs.length() > 0){
        this.childs.first ().data.width = this.width;
      }*/

      if(force_resize){
        GLib.stderr.printf( "3 w=%u h=%u\n", this.width,this.height);
        this.window.resize(this.width,this.height);
      }

      this._calculating_size=false;

    }
//~     public override void calculate_size(ref calc_width,ref calc_height){
//~     }//calculate_size
    public override void size_request(uint new_width, uint new_height){
      uint _w = this.width, _h = this.height;
      if( new_width > _w  )
        _w = new_width;
      if( new_height > _h)
        _h = new_height;
      GLib.stderr.printf( "window size_request=%u,%u\n", _w,_h);
      this.set_size(_w,_h);
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
      this.width = 50;
      this.height = 50;
    }
    public override bool draw(Cairo.Context cr){
      GLib.stderr.printf( "Button draw %s\n",this.get_class().get_name());
      cr.set_source_rgb(0.5, 1, 0.5);
         cr.rectangle (this.A.x, this.A.y,this.A.width/*+border.left+border.right*/, this.A.height/*+border.top+border.bottom*/);
         cr.fill ();
         if(this.label != null){
          cr.set_source_rgb(0.1, 0.1, 0.1);
          cr.move_to(0,this.height/2);
          cr.show_text(this.label);
          }
         cr.stroke ();
      base.draw(cr);
//~       cr.paint();
      return true;//continue
    }//draw
  }
}//namespace Ltk
