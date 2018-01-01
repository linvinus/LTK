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
    public static const string _net_wm_pid = "_NET_WM_PID";
    public static const string _utf8_string = "UTF8_STRING";
    public static const string _string = "STRING";
    public static const string _net_wm_state = "_NET_WM_STATE";
    public static const string _net_wm_state_modal = "_NET_WM_STATE_MODAL";
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
//~       debug("  ### a=%u > b=%u", a.min_width , b.min_width);
      if(a.min_width < b.min_width){
        return 1;
      }else if(a.min_width > b.min_width){
        return -1;
      }else{
        return 0;
      }
    }


  public class  WidgetList {
    private GLib.List<Widget> _childs;
    private GLib.List<unowned Widget> _fixed_width;
    private GLib.List<unowned Widget> _fixed_height;
    private GLib.List<unowned Widget> _variable_width;
    private GLib.List<unowned Widget> _variable_height;
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

    public WidgetList(){
      this._count = 0;
      this._fixed_width_count = 0;
      this._fixed_height_count = 0;
      this._childs = new GLib.List<Widget>();
      this._fixed_width = new GLib.List<Widget>();
      this._fixed_height = new GLib.List<Widget>();
      this._variable_width = new GLib.List<Widget>();
      this._variable_height = new GLib.List<Widget>();
    }
    public WidgetListIter iterator (){
      return WidgetListIter(this._childs.first());
    }

    public unowned GLib.List<unowned Widget> variable_width(){
      unowned GLib.List r = this._variable_width.first();
      return r;
    }

    public unowned GLib.List<unowned Widget> variable_height(){
      unowned GLib.List r = this._variable_height.first();
      return r;
    }

    public void remove_all(){
//~       this._fixed_width.remove_all();
//~       this.fixed_height.remove_all();
//~       this.childs.remove_all();
    }
    public void append (owned Widget child){
      this._childs.append(child);
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
      this._childs.remove(child);
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
          if( this._variable_height.find(src) != null){
            this._variable_height.remove(src);
          }

      }else{
          if( this._fixed_height.find(src) != null){
            this._fixed_height.remove(src);
            this._fixed_height_count--;
          }
          if( this._variable_height.find(src) == null){
            this._variable_height.append(src);
          }
      }
      this._variable_height.sort((GLib.CompareFunc<weak Ltk.Widget>)CompareWidth);

    }//on_size_changed

//~     public uint length(){
//~       return this._count;
//~     }
    public unowned List<Widget> find (Widget data){
      return this._childs.find(data);
    }

  }//class WidgetList
  /********************************************************************/
  public class XcbWindow{
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
    private Allocation damage_region;
    private uint draw_callback_timer;

    private void create_pixmap(uint16 width, uint16 height){
      uint32 prev_gc = this.pixmap_gc;
      uint32 prev_pixmap = this.pixmap;

      this.pixmap = Global.C.generate_id();
      this.pixmap_gc = Global.C.generate_id();

      Global.C.create_pixmap(Global.screen.root_depth,this.pixmap,Global.screen.root,width,height);
      uint32 values[2];
      values[0] = Global.screen.white_pixel;
      values[1] = Global.screen.white_pixel;
      Global.C.create_gc(this.pixmap_gc, this.pixmap, (Xcb.GC.BACKGROUND|Xcb.GC.FOREGROUND),values);

      if(prev_pixmap != 0){
        //copy previous window image, it will be shown until a new draw event
        Global.C.copy_area(prev_pixmap,
                           this.pixmap,
                           this.pixmap_gc,
                           (int16)0,
                           (int16)0,
                           (int16)0,
                           (int16)0,
                           (int16)width,
                           (int16)height);
        Global.C.free_gc(prev_gc);
        Global.C.free_pixmap(prev_pixmap);
      }

      if(this.window != 0 ){
        values[0] =  this.pixmap ;
        values[1] = 0;
        Global.C.change_window_attributes (this.window, Xcb.CW.BACK_PIXMAP, values);
      }
//~       uint32 position[] = { this.pos_x, this.pos_y, this.min_width, this.min_height };
//~       Global.C.configure_window(this.window, (Xcb.ConfigWindow.X | Xcb.ConfigWindow.Y | Xcb.ConfigWindow.WIDTH | Xcb.ConfigWindow.HEIGHT), position);

    }

    public XcbWindow(){
      this.state = WindowState.unconfigured;
      this.window = Global.C.generate_id();
      this.min_width = 1;
      this.min_height = 1;
      uint32 values[2];

      this.create_pixmap(1,1);

      values[0] = this.pixmap;
      values[1] = Xcb.EventMask.EXPOSURE |
                  Xcb.EventMask.VISIBILITY_CHANGE|
                  Xcb.EventMask.STRUCTURE_NOTIFY|
                  Xcb.EventMask.BUTTON_PRESS|
                  Xcb.EventMask.BUTTON_RELEASE|
                  Xcb.EventMask.POINTER_MOTION|
                  Xcb.EventMask.LEAVE_WINDOW|
                  Xcb.EventMask.ENTER_WINDOW|
                  Xcb.EventMask.KEY_PRESS|
                  Xcb.EventMask.KEY_RELEASE;

      Global.C.create_window(Xcb.COPY_FROM_PARENT, this.window, Global.screen.root,
                (int16)this.pos_x, (int16)this.pos_y, (uint16)this.min_width, (uint16)this.min_height, 0,
                Xcb.WindowClass.INPUT_OUTPUT,
                Global.screen.root_visual,
                /*Xcb.CW.OVERRIDE_REDIRECT |*/ Xcb.CW.BACK_PIXMAP| Xcb.CW.EVENT_MASK,
                values);


      //WM_HINTS
      var hints =  new Xcb.Icccm.WmHints ();
      Xcb.Icccm.wm_hints_set_normal(ref hints);
      Global.I.set_wm_hints(this.window, hints);


      //WM_PROTOCOLS
      Xcb.AtomT[] tmp_atoms={};
      tmp_atoms +=Global.atoms.lookup(atom_names.wm_delete_window);
      tmp_atoms +=Global.atoms.lookup(atom_names.wm_take_focus);
      tmp_atoms +=Global.atoms.lookup(atom_names._net_wm_ping);
      tmp_atoms +=Global.atoms.lookup(atom_names._net_wm_sync_request);
      Global.I.set_wm_protocols(this.window, Global.atoms.lookup(atom_names.wm_protocols), tmp_atoms);

      //_NET_WM_PID
      uint32 tmp_pid = (uint32)Posix.getpid();
      Global.C.change_property_uint32  ( Xcb.PropMode.REPLACE,
                           this.window,
                           Global.atoms.lookup(atom_names._net_wm_pid),
                           Xcb.Atom.CARDINAL,
    //~                        8,
                           1,
                           &tmp_pid);
      //WM_CLIENT_MACHINE
      uint8  machine_name[1024];
      if(Posix.gethostname((char[])machine_name) == 0){
        debug("XcbWindow machine_name=%s length=%d",(string)machine_name,((string)machine_name).length);
//~         Global.I.set_wm_client_machine(this.window,Global.atoms.lookup(atom_names._string),8,((string)machine_name).length,(string)machine_name);
      Global.C.change_property_uint8 ( Xcb.PropMode.REPLACE,
                           this.window,
                           Xcb.Atom.WM_CLIENT_MACHINE,
                           Xcb.Atom.STRING,
    //~                        8,
                           ((string)machine_name).length,
                           (string)machine_name);

      }

      this.surface = new Cairo.XcbSurface(Global.C, this.pixmap, Global.visual, (int)this.min_width, (int)this.min_height);
      this.cr = new Cairo.Context(this.surface);
      Global.windows.insert(this.window,this);
    }//XcbWindow

    ~XcbWindow(){
      debug("~XcbWindow fd=%u",Global.C.get_file_descriptor());
      this.surface.finish();//When the last call to cairo_surface_destroy() decreases the reference count to zero, cairo will call cairo_surface_finish()

      Global.C.free_gc(this.pixmap_gc);
      Global.C.free_pixmap(this.pixmap);
      Global.C.unmap_window(this.window);
      Global.C.destroy_window(this.window);

      if(Global.windows.lookup(this.window)!=null){
        Global.windows.remove(this.window);
        debug("~XcbWindow %u",this.window);
      }

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

    public void resize_and_remember(uint width,uint height){
      this.resize(width,height);
      if(this.state == WindowState.visible){
        this.min_width = width;
        this.min_height = height;
        this.cancel_draw();//new draw event will be on configure event
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
  //~     debug( "on_map x,y=%d,%d w,h=%d,%d response_type=%d ew=%d, w=%d",
  //~                       (int)e.x,
  //~                       (int)e.y,
  //~                       (int)e.width,
  //~                       (int)e.height,
  //~                       (int)e.response_type,
  //~                       (int)e.event,
  //~                       (int)e.window
  //~                       );
      debug( "on_configure w=%u h=%u ", this.min_width,this.min_height);
      if( (e.width == 1 && e.height == 1) && (this.min_width != 1 && this.min_height != 1))
        return;//skip first map

      this.pos_x = e.x;
      this.pos_y = e.y;
      if(this.min_width != e.width || this.min_height != e.height){
        this.min_width  = e.width;
        this.min_height = e.height;
//~         this.window_widget.A.width = this.min_width;
//~         this.window_widget.A.height = this.min_height;
        uint _w = this.min_width;
        uint _h = this.min_height;
        this.size_changed(_w,_h);
      }
      debug( "on_configure2 w=%u h=%u ", this.min_width,this.min_height);

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
  //~     debug( "on_map x,y=%d,%d w,h=%d,%d",(int)this.x,(int)this.y,(int)this.min_width,(int)this.min_height);
      this.queue_draw();
    }

    public bool process_event(Xcb.GenericEvent event){
      bool _continue = true;

  //~     debug( "!!!!!!!!!!!event");
  //~     while (( (event = Global.C.wait_for_event()) != null ) && !finished ) {
//~       while (( (event = Global.C.poll_for_event()) != null ) /*&& !finished*/ ) {
  //~       debug( "event=%d expose=%d map=%d",(int)event.response_type ,Xcb.EXPOSE,Xcb.CLIENT_MESSAGE);
          switch (event.response_type & ~0x80) {
            case Xcb.EXPOSE:
                /* Avoid extra redraws by checking if this is
                 * the last expose event in the sequence
                 */
                 Xcb.ExposeEvent e = (Xcb.ExposeEvent)event;
                if (e.count != 0)
                    break;
//~                 debug( "!!!!!!!!!!!event xy=%u,%u %ux%u count=%u",e.x, e.y, e.width, e.height,e.count);
                this.damage(e.x, e.y, e.width, e.height);
            break;
            case Xcb.CLIENT_MESSAGE:
                Xcb.ClientMessageEvent e = (Xcb.ClientMessageEvent)event;
                debug( "CLIENT_MESSAGE data32=%d name=%s deleteWindowAtom=%d", (int)e.data.data32[0],Global.C.get_atom_name_reply(Global.C.get_atom_name(e.data.data32[0])).name,(int)Global.net_wm_ping_atom);
                if(e.type == Global.atoms.lookup(atom_names.wm_protocols)){
                  if(e.data.data32[0] == Global.atoms.lookup(atom_names.wm_take_focus)){
                      this.on_focus();
                  }else if(e.data.data32[0] == Global.net_wm_ping_atom){
                     debug("Global.net_wm_ping_atom");
                  }else if(e.data.data32[0] == Global.deleteWindowAtom){
                      _continue = this.on_quit();//true to quit, false to continue
                      if(_continue){
                        this.quit();
                        _continue = false;
                      }
                  }
                }
            break;
            case Xcb.CONFIGURE_NOTIFY:
                if(event.response_type == Xcb.CONFIGURE_NOTIFY)
                  this.on_configure((Xcb.ConfigureNotifyEvent)event);
            break;
            case Xcb.MOTION_NOTIFY:
               Xcb.MotionNotifyEvent e = (Xcb.MotionNotifyEvent)event;
               this.on_mouse_move((uint) e.event_x, (uint) e.event_y);
            break;
            case Xcb.ENTER_NOTIFY:
               Xcb.EnterNotifyEvent e = (Xcb.EnterNotifyEvent)event;
               this.on_mouse_enter((uint) e.event_x, (uint) e.event_y);
            break;
            case Xcb.LEAVE_NOTIFY:
               Xcb.LeaveNotifyEvent e = (Xcb.LeaveNotifyEvent)event;
               this.on_mouse_leave((uint) e.event_x, (uint) e.event_y);
            break;
            case Xcb.KEY_PRESS:
               Xcb.KeyPressEvent e = (Xcb.KeyPressEvent)event;
               this.on_key_press((uint) e.detail, (uint) e.state);
            break;
            case Xcb.KEY_RELEASE:
               Xcb.KeyReleaseEvent e = (Xcb.KeyReleaseEvent)event;
               this.on_key_release((uint) e.detail, (uint) e.state);
            break;
            case Xcb.BUTTON_PRESS:
               Xcb.ButtonPressEvent e = (Xcb.ButtonPressEvent)event;
               this.on_button_press((uint)e.detail, (uint) e.event_x, (uint) e.event_y);
            break;
            case Xcb.BUTTON_RELEASE:
               Xcb.ButtonReleaseEvent e = (Xcb.ButtonReleaseEvent)event;
               this.on_button_release((uint)e.detail, (uint) e.event_x, (uint) e.event_y);
            break;
          }//switch
  //~         free(event);
//~           Global.C.flush();
//~       }
      return _continue;
    }//process_event

    public void draw_area(uint x,uint y,uint width,uint height){
      if(x > this.min_width ) x = this.min_width;
      if(y > this.min_height ) y = this.min_height;
      if((x + width) > this.min_width ) width = this.min_width - x;
      if((y + height) > this.min_height ) height = this.min_height - y;
      debug( "XCB **** draw_area xy=%u,%u wh=%u,%u",x, y, width, height);
      cr.save();
      cr.rectangle (x, y, width, height);
      cr.clip ();
      this.draw(cr);
      cr.restore();
      this.surface.flush();
      Global.C.copy_area(this.pixmap,
                         this.window,
                         this.pixmap_gc,
                         (int16)x,
                         (int16)y,
                         (int16)x,
                         (int16)y,
                         (int16)width,
                         (int16)height);
      Global.C.flush();
      debug( "XCB **** end");
    }//clear_area

    public void damage(uint x,uint y,uint width,uint height){
      debug( "XCB **** damage");
      this.damage_region.x = uint.min(this.damage_region.x, x);
      this.damage_region.y = uint.min(this.damage_region.y, y);
      this.damage_region.width = uint.max(this.damage_region.width, x+width);//x2
      this.damage_region.height = uint.max(this.damage_region.height, y+height);//y2
      debug( "XCB **** damage xy=%u,%u wh=%u,%u",
      this.damage_region.x,
      this.damage_region.y,
      this.damage_region.width,
      this.damage_region.height);
      this.queue_draw();
    }

    private bool on_draw(){
      this.draw_area(this.damage_region.x,
                     this.damage_region.y,
                     this.damage_region.width-this.damage_region.x,
                     this.damage_region.height-this.damage_region.y );
      this.draw_callback_timer = this.damage_region.width = this.damage_region.height = 0;
      this.damage_region.x = this.damage_region.y = (uint32)0xFFFFFFFF;
      return GLib.Source.REMOVE;//done
    }

    public void queue_draw(){
      if(this.draw_callback_timer == 0){
//~         GLib.Source.remove(draw_callback_timer);
        this.draw_callback_timer = GLib.Timeout.add((1000/30),on_draw);
      }
    }

    public void cancel_draw(){
      if(this.draw_callback_timer != 0){
        GLib.Source.remove(draw_callback_timer);
        draw_callback_timer=0;
      }
    }

    public void quit(){
      this.cancel_draw();
    }
    
    public uint32 get_xcb_id(){
      return this.window;
    }
    
    public void set_modal(bool mode){
        uint32 modal = (uint32)Global.atoms.lookup(atom_names._net_wm_state_modal);
        if(mode){
          Global.C.change_property_uint32  ( Xcb.PropMode.APPEND,
                               this.window,
                               Global.atoms.lookup(atom_names._net_wm_state),
                               Xcb.Atom.ATOM,
                               1,
                               &modal);
        }
    }

    public void set_transient_for(uint32 xcb_widow_id){
//~         uint32 modal = (uint32)Global.atoms.lookup(atom_names._net_wm_state_modal);
          Global.C.change_property_uint32  ( Xcb.PropMode.APPEND,
                               this.window,
                               Xcb.Atom.WM_TRANSIENT_FOR,
                               Xcb.Atom.WINDOW,
                               1,
                               &xcb_widow_id);
    }

    public signal void size_changed(uint width,uint height);//for parents
    public signal bool draw(Cairo.Context cr);
    public signal void on_mouse_move(uint x, uint y);
    public signal void on_mouse_enter(uint x, uint y);
    public signal void on_mouse_leave(uint x, uint y);
    public signal void on_button_press(uint button,uint x, uint y);
    public signal void on_button_release(uint detail,uint x, uint y);
    public signal void on_key_press(uint keycode, uint state);
    public signal void on_key_release(uint keycode, uint state);
    [Signal (run="last",detailed=false)]
    public virtual signal bool on_quit(){
      debug("Xcbwindow.on_quit");
      //https://mail.gnome.org/archives/vala-list/2011-October/msg00103.html
      return true;//default is to quit if no other handlers connected with connect_after;
    }
    public signal bool on_focus();
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
    private static Xcb.AtomT net_wm_ping_atom;
    private static MainLoop loop;
    public static GLib.HashTable<Xcb.Window,unowned XcbWindow> windows;
    private static uint xcb_source;

    private static void null_handler(string? domain, LogLevelFlags flags, string message) {
          }

    private static void print_handler(string? domain, LogLevelFlags flags, string message) {
        if(domain!= null){
          GLib.stderr.printf("%s %s\n",domain,message);
        }else{
          GLib.stderr.printf("%s\n",message);
        }
        GLib.stderr.flush();
          }


    public  static void Init(bool debug_enable){
        if(debug_enable) {
          Log.set_handler(null,
            LogLevelFlags.LEVEL_MASK &
            (LogLevelFlags.LEVEL_DEBUG |
            LogLevelFlags.LEVEL_MESSAGE |
            LogLevelFlags.LEVEL_WARNING |
            LogLevelFlags.LEVEL_INFO |
            LogLevelFlags.LEVEL_CRITICAL), print_handler);

        }else
          Log.set_handler(null, LogLevelFlags.LEVEL_MASK & ~LogLevelFlags.LEVEL_ERROR, null_handler);

      Global.atoms = new GLib.HashTable<string, Xcb.AtomT?> (str_hash, str_equal);
      Global.windows = new GLib.HashTable<Xcb.Window,XcbWindow> (direct_hash, direct_equal);
//~       ((GLib.HashTable)Global.windows).ref();
      Global.C = new Xcb.Connection();


      if (Global.C.has_error() != 0) {
              debug( "Could not connect to X11 server");
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

      if(!Global.atoms.contains(atom_names._net_wm_pid))
        Global.atoms.insert(atom_names._net_wm_pid,
          Global.C.intern_atom_reply(Global.C.intern_atom(false,atom_names._net_wm_pid)).atom);

      if(!Global.atoms.contains(atom_names._utf8_string))
        Global.atoms.insert(atom_names._utf8_string,
          Global.C.intern_atom_reply(Global.C.intern_atom(false,atom_names._utf8_string)).atom);

      if(!Global.atoms.contains(atom_names._string))
        Global.atoms.insert(atom_names._string,
          Global.C.intern_atom_reply(Global.C.intern_atom(false,atom_names._string)).atom);

      if(!Global.atoms.contains(atom_names._net_wm_state))
        Global.atoms.insert(atom_names._net_wm_state,
          Global.C.intern_atom_reply(Global.C.intern_atom(false,atom_names._net_wm_state)).atom);

      if(!Global.atoms.contains(atom_names._net_wm_state_modal))
        Global.atoms.insert(atom_names._net_wm_state_modal,
          Global.C.intern_atom_reply(Global.C.intern_atom(false,atom_names._net_wm_state_modal)).atom);

      Global.deleteWindowAtom = Global.atoms.lookup(atom_names.wm_delete_window);
      Global.net_wm_ping_atom = Global.atoms.lookup(atom_names._net_wm_ping);

      Global.visual = find_visual(Global.C, Global.screen.root_visual);
      if (Global.visual == null) {
//~           printf( "Some weird internal error...?!");
    //~       c.disconnect(); ???
          return;
      }

      Global.loop = new MainLoop ();

      var channel = new IOChannel.unix_new(Global.C.get_file_descriptor());
      Global.xcb_source = channel.add_watch(IOCondition.IN,  (source, condition) => {
          if (condition == IOCondition.HUP) {
          debug ("The connection has been broken.");
          Global.loop.quit();
          return false;
          }
          return xcb_pool_for_event();
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
      debug ("atoms.remove_all");
      Global.atoms.foreach((k,v)=>{ free((void*)v); });
      Global.atoms.remove_all();
//~       debug ("windows.remove_all");
//~       Global.windows.foreach((k,v)=>{ v.window_widget.unref(); });
//~       Global.windows.remove_all();
      //~     surface.finish();
    FontLoader.destroy();

//~     debug ("Global.C.unref");
//~     GLib.Source.remove(Global.xcb_source);

//~     surface.destroy();
//~     xcb_disconnect(c);
    }//run
    
    public static bool xcb_pool_for_event(MainLoop loop = Global.loop,uint32 onlywindow = 0){
         Xcb.GenericEvent event;
         bool _return = true;

//~           debug( "!!!!!!!!!!!event");
          /**
           * @brief Bit mask to find event type regardless of event source.
           *
           * Each event in the X11 protocol contains an 8-bit type code.
           * The most-significant bit in this code is set if the event was
           * generated from a SendEvent request. This mask can be used to
           * determine the type of event regardless of how the event was
           * generated. See the X11R6 protocol specification for details.
           */
          /*#define XCB_EVENT_RESPONSE_TYPE_MASK (0x7f)
          #define XCB_EVENT_RESPONSE_TYPE(e)   (e->response_type &  XCB_EVENT_RESPONSE_TYPE_MASK)
          #define XCB_EVENT_SENT(e)            (e->response_type & ~XCB_EVENT_RESPONSE_TYPE_MASK)*/

          while (( (event = Global.C.poll_for_event()) != null ) && _return ) {
//~             debug( "!!!!!!!!!!!event=%u",(uint)event.response_type);
            switch (event.response_type & ~0x80) {
              case Xcb.EXPOSE:
              case Xcb.CLIENT_MESSAGE:
                 Xcb.ExposeEvent e = (Xcb.ExposeEvent)event;
                 if((onlywindow != 0 && onlywindow == e.window)||
                     onlywindow == 0){
                 _return = Global.windows.lookup(e.window).process_event(event);
                   if(!_return){
                     loop.quit ();
                     }
                 }
              break;
              case Xcb.CONFIGURE_NOTIFY:
                 Xcb.ConfigureNotifyEvent e = (Xcb.ConfigureNotifyEvent)event;
                 if((onlywindow != 0 && onlywindow == e.window)||
                     onlywindow == 0){
                  _return = Global.windows.lookup(e.window).process_event(event);
                }
              break;
              case Xcb.MOTION_NOTIFY:
                 Xcb.MotionNotifyEvent e = (Xcb.MotionNotifyEvent)event;
                 if((onlywindow != 0 && onlywindow == e.event)||
                     onlywindow == 0){
                  _return = Global.windows.lookup(e.event).process_event(event);
                 }
              break;
              case Xcb.ENTER_NOTIFY:
                 Xcb.EnterNotifyEvent e = (Xcb.EnterNotifyEvent)event;
                 if((onlywindow != 0 && onlywindow == e.event)||
                     onlywindow == 0){
                 _return = Global.windows.lookup(e.event).process_event(event);
                 }
              break;
              case Xcb.LEAVE_NOTIFY:
                 Xcb.LeaveNotifyEvent e = (Xcb.LeaveNotifyEvent)event;
                 if((onlywindow != 0 && onlywindow == e.event)||
                     onlywindow == 0){
                  _return = Global.windows.lookup(e.event).process_event(event);
                 }
              break;
              case Xcb.KEY_PRESS:
                 Xcb.KeyPressEvent e = (Xcb.KeyPressEvent)event;
                 if((onlywindow != 0 && onlywindow == e.event)||
                     onlywindow == 0){
                  _return = Global.windows.lookup(e.event).process_event(event);
                 }
              break;
              case Xcb.KEY_RELEASE:
                 Xcb.KeyReleaseEvent e = (Xcb.KeyReleaseEvent)event;
                 if((onlywindow != 0 && onlywindow == e.event)||
                     onlywindow == 0){
                  _return = Global.windows.lookup(e.event).process_event(event);
                 }
              break;
              case Xcb.BUTTON_PRESS:
                 Xcb.ButtonPressEvent e = (Xcb.ButtonPressEvent)event;
                 if((onlywindow != 0 && onlywindow == e.event)||
                     onlywindow == 0){
                  _return = Global.windows.lookup(e.event).process_event(event);
                 }
              break;
              case Xcb.BUTTON_RELEASE:
                 Xcb.ButtonReleaseEvent e = (Xcb.ButtonReleaseEvent)event;
                 if((onlywindow != 0 && onlywindow == e.event)||
                     onlywindow == 0){
                  _return = Global.windows.lookup(e.event).process_event(event);
                 }
              break;
             }
           Global.C.flush();
           free(event);
          }
      return _return;
    }//xcb_pool_for_event

  }

  /********************************************************************/
  public class Widget : GLib.Object{
    public weak Container? parent = null;
    public WidgetList childs;
    private uint _min_width;
    public uint min_width{
      get{ return  this._min_width;}
      set{
        if(value != this._min_width){
          debug("Widget min_width_old=%u new=%u",(uint)this._min_width,value);
          this._min_width = value;
          if(this.A.width < this._min_width)
            this.damaged = true;
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
          if(this.A.height < this._min_height)
            this.damaged = true;
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
          this.damaged = true;
        }else if( value == ((A.options & SOptions.visible) > 0) ){
          this.A.options &= ~(SOptions.visible);
          this.damaged = true;
        }
        this.size_changed(this,prev);
      }
      default = true;
    }
    private bool _damaged;
    public bool damaged{
      get {return _damaged;}
      set {
        _damaged = value;
        if(_damaged){
          this.send_damage();
        }
        debug("--- Widget damaged=%u width=%u height=%u childs=%u",(uint)_damaged,this.A.width,this.A.height, this.childs.count);
        }
      default = true;
    }

    public Ltk.ThemeEngine engine;
    public WidgetState state;

    public Widget(Container? parent = null){
      GLib.Object();
      this.childs = new WidgetList();
//~       this.x = this.y = 0;
      if(parent != null)
        this.parent = parent;
      this.engine = new ThemeEngine("");

      this.engine.map.bg[DrawStyle.normal].r = this.engine.map.bg[DrawStyle.normal].g = this.engine.map.bg[DrawStyle.normal].b = 0.5;
      this.engine.map.br[DrawStyle.normal].r = this.engine.map.br[DrawStyle.normal].g = this.engine.map.br[DrawStyle.normal].b = 0.3;
      this.engine.map.bg[DrawStyle.normal].r=0.5;
    }//create

    ~Widget(){
      this.childs.remove_all();
      debug("~Widget");
    }

    public virtual bool draw(Cairo.Context cr){
        this.engine.begin(this.state,this.A.width,this.A.height);
        if(this.damaged){
          this.engine.draw_box(cr);
          this.engine.translate2box(cr);
//~           this.engine.draw_border(cr,this.A.width, this.A.height, this.A.height / 20.0, 50);
          this.damaged=false;
        }

      return true;//continue
    }//draw

    public virtual void show(){
      this.visible = true;
    }
    public virtual void hide(){
      this.visible = false;
    }
    public weak Window? get_top_window(){
      unowned Container? w = this.parent;
      while( w != null && w.parent !=null){
        w = w.parent;
      }
      if(w is Window){
        return (Window)w;
      }else{
        return null;
      }
    }
    public void send_damage(Widget w = this,uint sx = this.A.x,uint sy = this.A.y,uint swidth = this.A.width,uint sheight = this.A.height){
//~        debug("Widget send_damage");
       var win = get_top_window();
//~        debug("Widget send_damage %u",(uint)win);
       if(win != null){
          win.damage(w,sx,sy,swidth,sheight);
        }
//~       GLib.Signal.emit_by_name(((Widget)this),"damage2",null,this.A.x,this.A.y,this.A.width,this.A.height);
    }

    //set input focus
    public virtual bool set_focus(bool focus){
      return false;
    }//set_focus

    //is widget focused?
    public virtual bool get_focus(){
      return false;
    }//get_focus

    public signal void size_changed(Widget src,Allocation old);//for parents
//~     [Signal (action=true, detailed=true, run=true, no_recurse=true, no_hooks=true)]
//~     [Signal (run="first")]

    [Signal (run="first")]
    public virtual signal void on_mouse_move(uint x, uint y){}
    [Signal (run="first")]
    public virtual signal void on_mouse_enter(uint x, uint y){ this.state |= WidgetState.hover; }
    [Signal (run="first")]
    public virtual signal void on_mouse_leave(uint x, uint y){ this.state &= ~WidgetState.hover; }
    [Signal (run="first")]
    public virtual signal void on_key_press(uint keycode, uint state){}
    [Signal (run="first")]
    public virtual signal void on_key_release(uint keycode, uint state){}
    [Signal (run="first")]
    public virtual signal void on_button_press(uint button,uint x, uint y){}
    [Signal (run="first")]
    public virtual signal void on_button_release(uint button,uint x, uint y){}

  }//class Widget
  /********************************************************************/
  public class Container: Widget{
    private bool _calculating_size = false;
    public uint size_changed_serial = 0;//public for window class
    private uint size_update_width_serial = 0;
    private uint size_update_height_serial = 0;
    private uint size_update_childs = 0;
    private uint8 color=28;
    public Container(){
      base();
      this.fill_mask = Ltk.SOptions.fill_vertical | Ltk.SOptions.fill_horizontal;
    }

    private void on_child_size_changed(Widget src, Allocation prev){

        if(this._calculating_size)  return;
        this.size_changed_serial++;

        int diff_width = ((int)src.min_width - (int)src.A.width);
        int diff_height = ((int)src.min_height - (int)src.A.height);

        //important, set default size for fixed widget
        if( (src.fill_mask & Ltk.SOptions.fill_horizontal) == 0){
          src.A.width = src.min_width;
        }
        if( (src.fill_mask & Ltk.SOptions.fill_vertical) == 0){
          src.A.height = src.min_height;
        }

        debug("diff_width=%d diff_height=%d",diff_width,diff_height);

        if(diff_height != 0 || diff_width != 0){
            this.update_childs_sizes();
        }
    }

    public void add(Widget child){
      if(this.childs.find(child) == null && child.parent == null){
        child.parent = this;
        this.childs.append(child);
        this.on_child_size_changed(child,child.A);
        child.size_changed.connect(this.on_child_size_changed);
        this.update_childs_sizes();
      }
    }//add

    public void remove(Widget child){
      if(this.childs.find(child) != null){
        this.childs.remove(child);
        child.parent = null;
        this.size_changed_serial++;
        this.update_childs_sizes();
      }
    }//remove

    private void update_childs_sizes(){
      uint oldw = this.A.width;
      uint oldh = this.A.height;
      this.calculate_size(ref oldw,ref oldh,this);
      this.update_childs_position();
    }//update_childs_sizes

    public void update_childs_position(){
      debug("@@@ update_childs_position xy=%u,%u count=%u",this.A.x,this.A.y, this.childs.count);

      //calculate position
      uint _x = this.A.x, _y = this.A.y, _w = 0, _h = 0;

      foreach(var w in this.childs){
            bool do_damage=false;
            if(this.place_policy == SOptions.place_horizontal){
              _y = this.A.y + ((this.A.height-w.A.height)/2);
              if( _x != w.A.x || _y != w.A.y || this.damaged){//redraw all childs if container was damaged
                do_damage=true;
              }
              w.A.x = _x;
              w.A.y = _y;
              if(w.damaged && w is Ltk.Container){
                ((Ltk.Container)w).update_childs_position();
              }
              _x+=w.A.width;
            }else{
              _x = this.A.x + (this.A.width - w.A.width)/2;
              if( _x != w.A.x || _y != w.A.y || this.damaged){//redraw all childs if container was damaged
                do_damage=true;
              }
              w.A.x = _x;
              w.A.y = _y;
              if(w.damaged && w is Ltk.Container){
                ((Ltk.Container)w).update_childs_position();
              }
              _y+=w.A.height;
            }
            if(do_damage && !(w is Ltk.Container)){
              w.damaged=true;
              if(w.parent != null){
                var P = w.parent;
                uint Px = ( P.place_policy == SOptions.place_horizontal ? w.A.x    : P.A.x ),
                     Py = ( P.place_policy == SOptions.place_horizontal ? P.A.y : w.A.y ),
                     Pw = ( P.place_policy == SOptions.place_horizontal ? w.A.width     : P.A.width ),
                     Ph = ( P.place_policy == SOptions.place_horizontal ? P.A.height : w.A.height   );
                    P.send_damage(P,Px,Py,Pw,Ph);
                 }

            }
      }
    }//update_childs_position


    public override uint get_prefered_width(){
      int h = -1;
      uint wmin,wmax;
      this.get_width_for_height(h,out wmin,out wmax);
      this.min_width = (this.place_policy == SOptions.place_horizontal? wmax : wmin);
      return this.min_width;
    }//get_prefered_width

    public override uint get_prefered_height(){
      int w = -1;
      uint hmin,hmax;
      this.get_height_for_width(w,out hmin,out hmax);
      this.min_height = (this.place_policy == SOptions.place_vertical? hmax : hmin);
      return this.min_height;
    }//get_prefered_height

    public virtual void get_height_for_width(int width,out uint height_min,out uint height_max){
      uint _h;
      if(this.size_update_height_serial != this.size_changed_serial){
        foreach(var w in this.childs){
          _h = w.get_prefered_height();
          height_min = uint.max(height_min, _h);
          height_max = (this.place_policy == SOptions.place_vertical ? height_max + _h : height_min);
          debug( "get_height_for_width1 min=%u max=%u %s",_h,height_max, ( (w is Button ) ? "label="+((Button)w).label: "") );
        }
        this.size_update_height_serial = this.size_changed_serial;
      }else{
        height_min = this.min_height;
        height_max = height_min;//uint.max(this.A.height,height_min);
        debug( "get_height_for_width2 min=%u max=%u ",height_min,height_max );
      }
    }//get_height_for_width

    public virtual void get_width_for_height(int height,out uint width_min,out uint width_max){
      uint _w;
      if(this.size_update_width_serial != this.size_changed_serial){
        foreach(var w in this.childs){
          _w = w.get_prefered_width();
          width_min = uint.max( width_min, _w );
          width_max = (this.place_policy == SOptions.place_horizontal ? width_max + _w : width_min);
          debug( "get_width_for_height1 min=%u max=%u %s",_w,width_max, ( (w is Button ) ? "label="+((Button)w).label: "") );
        }
        this.size_update_width_serial = this.size_changed_serial;
      }else{
        width_min = this.min_width;
        width_max = width_min;//uint.max(this.A.width,width_min);
      }
      debug( "get_width_for_height2 min=%u max=%u",width_min,width_max);
    }//get_width_for_height

    public virtual void calculate_size(ref uint calc_width,ref uint calc_height, Widget calc_initiator){
      debug( "container calculate_size min=%u,%u A=%u,%u  CALC=%u,%u loop=%d childs=%u", this.min_width,this.min_height,this.A.width,this.A.height,calc_width,calc_height,(int)this._calculating_size,this.childs.count);

      if(this._calculating_size)
        return;


      this.get_prefered_width();
      this.get_prefered_height();

      if( (this.size_changed_serial == this.size_update_childs && calc_initiator == this) &&
         this.A.width >= this.min_width &&
         this.A.height >= this.min_height ){
            this._calculating_size=false;
            debug( "container quick end. calculate_size w=%u h=%u loop=%d childs=%u", this.min_width,this.min_height,(int)this._calculating_size,this.childs.count);
            return;
      }
      this._calculating_size=true;

      this.size_update_childs = this.size_changed_serial;

        debug( "container this.fill_mask=%d",this.fill_mask );
        debug( "container calc_width=%u wmax=%u",calc_width , this.min_width );
        debug( "container calc_height=%u hmax=%u",calc_height , this.min_height );

        //just to be shure
        if(calc_width < this.min_width)  { calc_width  = this.min_width; }
        if(calc_height < this.min_height){ calc_height = this.min_height;}

          if( calc_width != this.A.width || calc_height != this.A.height ){
            this.damaged=true;
          }
          debug("container damaged=%u calc=%u,%u A=%u,%u",(uint)this.damaged,calc_width,calc_height,this.A.width,this.A.height);

          this.A.width = calc_width;//apply new allocation
          this.A.height = calc_height;

        if(this.place_policy == Ltk.SOptions.place_horizontal){
          debug("container SOptions.place_horizontal min=%u,%u A=%u,%u",this.min_width,this.min_height,this.A.width,this.A.height);
          //set sizes for childs

          uint extra_width_delta = this.A.width;

          debug("container childs.length=%u ",this.childs.count);

          if(extra_width_delta > this.min_width){
            extra_width_delta -= this.childs.fixed_width;
            extra_width_delta = extra_width_delta/(this.childs.count-this.childs.fixed_width_count);
          }else{
            extra_width_delta = 0;
          }

          debug("container w=%u extra_width_delta=%u",this.A.width, extra_width_delta);

          //_variable_width is sorted,first bigger then smaller
          foreach(var w in this.childs.variable_width()){

  //~           w.A.x = 0;
  //~           w.A.y = 0;
            uint new_width = 0;
            uint new_height = 0;

            if( (w.fill_mask & Ltk.SOptions.fill_horizontal) > 0 ){
              if( extra_width_delta >= w.min_width){
                new_width = extra_width_delta;
              }else{
                new_width = w.min_width;
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
                new_width = w.min_width;
            }
            if((w.fill_mask & Ltk.SOptions.fill_vertical) > 0){
              new_height = this.A.height;
            }else{
              new_height = w.min_height;
            }
            debug("container A w=%u h=%u",new_width,new_height);
            if( new_width != w.A.width || new_height != w.A.height ){
              w.damaged=true;
            }

            if(w is Ltk.Container){
              ((Ltk.Container)w).calculate_size(ref new_width,ref new_height, this);
            }else{
              w.A.width = new_width;
              w.A.height = new_height;
            }

            w.A.options ^= w.A.options;
            w.A.options |= w.place_policy;
            w.A.options |= w.fill_mask;

          }//foreach childs
        }else{//SOptions.place_vertical
          debug("container SOptions.place_vertical min=%u,%u A=%u,%u",this.min_width,this.min_height,this.A.width,this.A.height);
          //set sizes for childs
          uint extra_height_delta = this.A.height;

          debug("container childs.length=%u ",this.childs.count);

          if(extra_height_delta > this.min_height){
            extra_height_delta -= this.childs.fixed_height;
            extra_height_delta = extra_height_delta/(this.childs.count-this.childs.fixed_height_count);
          }else{
            extra_height_delta = 0;
          }

          debug("container h=%u extra_height_delta=%u",this.A.height, extra_height_delta);


          //_variable_height is sorted,first bigger then smaller
          foreach(var w in this.childs.variable_height()){

  //~           w.A.x = 0;
  //~           w.A.y = 0;
            uint new_width = 0;
            uint new_height = 0;

            if( (w.fill_mask & Ltk.SOptions.fill_vertical) > 0 ){
              if( extra_height_delta >= w.min_height){
                new_height = extra_height_delta;
              }else{
                new_height = w.min_height;
                //100 | 100
                //x   | 150
                if(extra_height_delta > 0){
                  uint dela_minus = (w.min_height-extra_height_delta);
                  if(extra_height_delta > dela_minus){
                    extra_height_delta -= dela_minus;
                  }else{
                    extra_height_delta = 0;//hmm, something wrong
                  }
                }
              }
            }else{
                new_height = w.min_height;
            }

            if((w.fill_mask & Ltk.SOptions.fill_horizontal) > 0){
              new_width = this.A.width;
            }else{
              new_width = w.get_prefered_width();
            }

            debug("container A w=%u h=%u",w.A.width,w.A.height);

            if( new_width != w.A.width || new_height != w.A.height ){
              w.damaged=true;
            }

            if(w is Ltk.Container){
              ((Ltk.Container)w).calculate_size(ref new_width,ref new_height, this);
            }else{
              w.A.width = new_width;
              w.A.height = new_height;
            }
            w.A.options ^= w.A.options;
            w.A.options |= w.place_policy;
            w.A.options |= w.fill_mask;
          }//foreach childs
        }//SOptions.place_vertical
      debug( "container end calculate_size w=%u h=%u loop=%d childs=%u damage=%u", this.min_width,this.min_height,(int)this._calculating_size,this.childs.count,(uint)this.damaged);
      this._calculating_size=false;
    }//calculate_size

    public override bool draw(Cairo.Context cr){
        var _ret = base.draw(cr);//widget
        debug( "container x,y=%u,%u w,h=%u,%u childs=%u",this.A.x, this.A.y, this.A.width, this.A.height, this.childs.count);

        double dx=0,dy=0;

        foreach(var w in this.childs){
          cr.save();

            if(w.damaged || w is Ltk.Container){//always propagate draw for container childs
              if(!(w is Ltk.Container)){//container will draw it own background
                uint _x = ( this.place_policy == SOptions.place_horizontal ? w.A.x    : this.A.x ),
                     _y = ( this.place_policy == SOptions.place_horizontal ? this.A.y : w.A.y ),
                     _w = ( this.place_policy == SOptions.place_horizontal ? w.A.width     : this.A.width ),
                     _h = ( this.place_policy == SOptions.place_horizontal ? this.A.height : w.A.height   );
                    dx = _x;
                    dy = _y;
                    cr.device_to_user(ref dx,ref dy);
                    cr.translate (dx, dy);
                    this.engine.begin(this.state,_w,_h);//repaint container background under widget, recover background if widget become smaller
                    this.engine.draw_box(cr);
                    //this.send_damage(this,_x,_y,_w,_h); don't send damage from draw
              }

              dx=w.A.x;
              dy=w.A.y;
              cr.device_to_user(ref dx,ref dy);
//~               debug( "+++ childs draw %d [%f,%f]",(int)w.A.width,dx,dy);
              cr.translate (dx, dy);
              cr.rectangle (0, 0, w.A.width , w.A.height );
              cr.clip ();
              w.draw(cr);
            }

//~             cr.pop_group ();
          cr.restore();
          }//foreach
        return _ret;
      }//draw

  }//class container
  /********************************************************************/
  public class Window: Container{
    private XcbWindow window;
    private bool _calculating_size = false;
    private string? title = null;
    string text="HELLO :) Проверка ЁЙ Русский язык اللغة العربية English language اللغة العربية";
    private weak Widget? previous_widget_under_mouse = null;
    private weak Widget? focused_widget = null;
    private weak Widget? button_press_widget[25];//man4/mousedrv.4. default value is 3. The maximum number is 24

    public Window(){

      base();
      this.min_width=this.min_height=1;

      this.window = new XcbWindow();
      this.window.size_changed.connect(on_xcb_window_size_change);
      this.window.draw.connect(this.draw);
      //someone can subscribe to this signals
      this.window.on_mouse_move.connect((x,y)=>{this.on_mouse_move(x,y);});
      this.window.on_mouse_enter.connect((x,y)=>{this.on_mouse_enter(x,y);});
      this.window.on_mouse_leave.connect((x,y)=>{this.on_mouse_leave(x,y);});
      //generate on_mouse_enter,on_mouse_leave events for childs
      this.window.on_mouse_move.connect(this._on_mouse_move);
      this.window.on_mouse_enter.connect(this._on_mouse_move);
      this.window.on_mouse_leave.connect(this._on_mouse_move);

      //firstly send to child, so child can cancel event
      this.window.on_key_press.connect((keycode, state) => {
        if(focused_widget!=null){
          focused_widget.on_key_press(keycode, state);
          }
      });
      this.window.on_key_press.connect((keycode, state) => {this.on_key_press(keycode, state);});

      //firstly send to child, so child can cancel event
      this.window.on_key_release.connect((keycode, state) => {
        if(focused_widget!=null){
          this.focused_widget.on_key_release(keycode, state);
          }
      });
      this.window.on_key_release.connect((keycode, state) => {this.on_key_press(keycode, state);});

      //firstly send to child, so child can cancel event
      this.window.on_button_press.connect((button, x, y)=>{
          Widget? w = this.find_mouse_child(this,x,y);
          debug("window on_button_press2 %u xy=%u,%u w=%p",button, x, y,w);
          if(w != null){
            this.button_press_widget[button % 25] = w;//remember latest widget
            w.on_button_press(button, x, y);
          }
        });
      this.window.on_button_press.connect(_on_button_press);

      //firstly send to child, so child can cancel event
      this.window.on_button_release.connect((button, x, y)=>{
          Widget? w = this.button_press_widget[button];//release event could be outside our window, so use remembered widget
          debug("window on_button_release2 %u xy=%u,%u w=%p",button, x, y,w);
          if(w != null){
            w.on_button_release(button, x, y);
            this.button_press_widget[button % 25] = null;//done
          }
      });

//~       this.damage.connect((widget,x,y,w,h)=>{});

//~       GLib.Signal.connect_swapped(w,"damage2",(GLib.Callback)this.on_damage222,this);

//~       this.window.on_quit.connect(()=>{
//~         GLib.Signal.stop_emission_by_name(this.window,"on-quit");
//~         debug("Window window.on_quit");
//~         return false;
//~         });
//~       return base(null);
    }

    ~Window(){
      debug("~Window");
    }


    public override bool draw(Cairo.Context cr){
      debug( "window draw w=%u h=%u childs=%u damage=%u", this.min_width,this.min_height,this.childs.count,(uint)this.damaged);
      var _ret = base.draw(cr);//Container
      return _ret;
    }//draw

    private void on_xcb_window_size_change(uint width,uint height){
        this.size_changed_serial++;
        this.calculate_size(ref width,ref height,this);
        this.update_childs_position();
//~         this.damaged=true;
    }

    public void damage_all(Container P){
      foreach(var w in P.childs){
        if(w is Container){
          this.damage_all((Container) w);
        }else
          w.damaged=true;
      }
    }

    public override void calculate_size(ref uint calc_width,ref uint calc_height,Widget calc_initiator){
      debug( "window calculate_size1 min=%u,%u A=%u,%u  CALC=%u,%u loop=%d", this.min_width,this.min_height,this.A.width,this.A.height,calc_width,calc_height,(int)this._calculating_size);
      this._calculating_size=true;
      uint oldw = uint32.min(this.A.width,calc_width);
      uint oldh = uint32.min(this.A.height,calc_height);
      base.calculate_size(ref calc_width,ref calc_height, calc_initiator);
      debug( "window calculate_size2 min=%u,%u A=%u,%u  CALC=%u,%u loop=%d", this.min_width,this.min_height,this.A.width,this.A.height,calc_width,calc_height,(int)this._calculating_size);
      if(calc_width != oldw||
         calc_height != oldh){
           this.window.resize_and_remember(calc_width,calc_height);
           this.A.width = calc_width;
           this.A.height = calc_height;
           this.damage_all(this);//redraw whole window
      }
      this._calculating_size=false;
    }


    public void size_request(uint new_width, uint new_height){
      debug( "window size_request=%u,%u", new_width,new_height);
      if(this.A.width != new_width || this.A.height != new_height){
        this.window.resize(new_width,new_height);
      }
    }

    public void set_title(string title){
      this.window.set_title(title);
    }
    public void load_font_with_size(string fpatch,uint size){
      this.window.load_font_with_size(fpatch, size);
    }

    public override void show(){
      base.show();
      this.window.show();
    }

    private weak Widget? find_mouse_child(Container cont, uint x, uint y){
      foreach(Widget w in cont.childs){
//~           debug( "> %u < %u < %u ,  %u < %u < %u  ",w.A.x,x,(w.A.x+w.A.width), w.A.y,y,(w.A.y + w.A.height) );

        if( ( x > w.A.x  && x < (w.A.x + w.A.width) ) &&
            ( y > w.A.y  && y < (w.A.y + w.A.height) ) ){
          if(w is Container){
            return this.find_mouse_child((Container)w,x,y);
          }else{
            weak Widget tmp = w;
            return tmp;
          }
        }
      }
      return null;
    }//find_mouse_child

    private weak Widget? find_mouse_child_up(Container cont, uint x, uint y){
      Widget? w = this.find_mouse_child(cont,x,y);
      if(w == null && cont.parent != null){
        return this.find_mouse_child_up(cont.parent,x,y);
      }
      weak Widget tmp = w;
      return tmp;
    }//find_mouse_child_up

    private void _on_mouse_move(uint x, uint y){
//~       debug("window on_mouse_move=%u,%u",x,y);
      if(this.previous_widget_under_mouse == null){
        this.previous_widget_under_mouse = this.find_mouse_child(this,x,y);
         if(this.previous_widget_under_mouse != null){
           Widget w = this.previous_widget_under_mouse;//take owner
           w.on_mouse_enter(x,y);
           return;
         }
      }else{
        Widget w = this.previous_widget_under_mouse;
        if( !( ( x > w.A.x  && x < (w.A.x + w.A.width) ) &&
               ( y > w.A.y  && y < (w.A.y + w.A.height) ) ) ){
                 w.on_mouse_leave(x,y);
                 this.previous_widget_under_mouse = this.find_mouse_child_up(w.parent,x,y);
                 if(this.previous_widget_under_mouse != null){
                   w = this.previous_widget_under_mouse;//take owner
                   w.on_mouse_enter(x,y);
                   return;
                 }
        }
      }
      if(this.previous_widget_under_mouse != null){
        Widget w = this.previous_widget_under_mouse;//take owner
        w.on_mouse_move(x,y);
//~         debug( "window child under mouse is wh=%u,%u",
//~             this.previous_widget_under_mouse.A.width,
//~             this.previous_widget_under_mouse.A.height);
      }
    }//_on_mouse_move

    public virtual signal void damage(Widget? src,uint x,uint y,uint width,uint height){
      this.window.damage(x,y,width,height);
    }
    /*public virtual bool on_mouse_move(uint x, uint y){return true;}
    public virtual bool on_mouse_enter(uint x, uint y){return true;}
    public virtual bool on_mouse_leave(uint x, uint y){return true;}
    public virtual bool on_key_press(uint keycode, uint state){return true;}
    public virtual bool on_key_release(uint keycode, uint state){return true;}*/
//~     public override signal void on_key_press(uint keycode, uint state){}
//~     public override signal void on_key_release(uint keycode, uint state){}
//~     public override void on_button_press(uint detail,uint x, uint y){

    //set focus for child widget
    private void _on_button_press(uint button,uint x, uint y){
        debug("window on_button_press %u xy=%u,%u",button, x, y);
          Widget? w = this.focused_widget;
          if( w == null ||
             (w != null &&
              !( ( x > w.A.x  && x < (w.A.x + w.A.width) ) &&
                 ( y > w.A.y  && y < (w.A.y + w.A.height) ) ) )
          ){
               w = this.find_mouse_child(this,x,y);
          }

         if(this.focused_widget != w){
           if(this.focused_widget != null && this.focused_widget is Widget){
             this.focused_widget.set_focus(false);
             this.focused_widget = null;
           }
           if(w != null && w.set_focus(true)){
             this.focused_widget = w;
           }else{
             this.focused_widget = null;
           }
           debug("window on_button_press widget=%p",this.focused_widget);
        }
    }//on_button_press
    
    public uint32 get_xcb_id(){
      return this.window.get_xcb_id();
    }
    
    public void set_modal(bool mode){
      this.window.set_modal(mode);
    }

    public void set_transient_for(uint32 xcb_widow_id){
      this.window.set_transient_for(xcb_widow_id);
    }

  }//class Window


  /********************************************************************/

  public class Button: Widget{
    public string? label = null;
    private uint8 color=128;
    private bool _focused = false;
    public Button(string? label = null){
      base();
      this.label = label;
      this.min_width = 50;
      this.min_height = 50;
      engine.map.bg[DrawStyle.normal].r = 0.0;
      engine.map.bg[DrawStyle.normal].g = 0.5;
      engine.map.bg[DrawStyle.normal].b = 0.0;

      engine.map.bg[DrawStyle.focused].r = 0.0;
      engine.map.bg[DrawStyle.focused].g = 0.9;
      engine.map.bg[DrawStyle.focused].b = 0.0;
      engine.map.br[DrawStyle.focused].r = 0.5;
      engine.map.br[DrawStyle.focused].g = 0.0;
      engine.map.br[DrawStyle.focused].b = 0.0;

      engine.map.bg[DrawStyle.active].r = 0.5;
      engine.map.bg[DrawStyle.active].g = 0.0;
      engine.map.bg[DrawStyle.active].b = 0.9;
      engine.map.br[DrawStyle.active].r = 0.5;
      engine.map.br[DrawStyle.active].g = 0.0;
      engine.map.br[DrawStyle.active].b = 0.0;

      engine.map.bg[DrawStyle.hover].r = 0.0;
      engine.map.bg[DrawStyle.hover].g = 0.5;
      engine.map.bg[DrawStyle.hover].b = 0.0;
      engine.map.br[DrawStyle.hover].r = 0.5;
      engine.map.br[DrawStyle.hover].g = 0.0;
      engine.map.br[DrawStyle.hover].b = 0.5;

      engine.border.left = 3;
      engine.border.right = 3;
      engine.border.top = 3;
      engine.border.bottom = 3;

      engine.padding.top = 0;
      engine.padding.bottom = 0;
      engine.padding.left = 0;
      engine.padding.right = 0;
      this.on_mouse_enter.connect(this.damage_on_mouse_event);
      this.on_mouse_leave.connect(this.damage_on_mouse_event);
    }
    public override bool draw(Cairo.Context cr){
      debug( "Button draw %s",this.get_class().get_name());
        this.engine.begin(this.state,this.A.width,this.A.height);
        if(this.damaged){
         this.engine.draw_box(cr,this.engine.height / 10.0);
         this.engine.translate2box(cr);//main part where we can draw

         cr.translate (0,(double)(this.A.height/2));
         if(this.label != null){
          cr.set_font_size (14.0);
          cr.set_source_rgb(engine.map.text[this.engine.style].r,
                            engine.map.text[this.engine.style].g,
                            engine.map.text[this.engine.style].b);
          cr.show_text(this.label);
          }
         cr.stroke ();
         this.damaged=false;
      }
      this.color+=50;
//~       engine.map.bg[this.engine.style].g = (double)this.color/255.0;
//~       cr.paint();
      return true;//continue
    }//draw
    public override void on_button_press(uint button,uint x, uint y){
      this.state |= WidgetState.activated;
      this.damaged = true;//redraw button with new state
    }
    public override void on_button_release(uint button,uint x, uint y){
      this.state &= ~WidgetState.activated;
      this.damaged = true;//redraw button with new state
      this.on_click();
    }
    private void damage_on_mouse_event(uint x,uint y){
      this.damaged = true;//redraw button with new state
    }

    //set input focus
    public override bool set_focus(bool focus){
      this._focused = focus;
      if(!focus && (this.state & WidgetState.focused) >0 ){
        this.state  &= ~WidgetState.focused;
        this.damaged = true;
      }else if(focus && (this.state & WidgetState.focused) == 0 ){
        this.state  |= WidgetState.focused;
        this.damaged = true;
      }
      return this._focused;
    }//set_focus

    //is widget focused?
    public override bool get_focus(){
      return this._focused;
    }//get_focus
    public signal void on_click();
  }//Button

  public class Dialog: Window{
    private weak Window parent_window;
    public Dialog(Window parent){
      this.parent_window = parent;
    }

    public void run(){
      this.set_modal(true);
      this.set_transient_for(this.parent_window.get_xcb_id());
      this.show();
      var loop = new MainLoop ();
      var channel = new IOChannel.unix_new(Global.C.get_file_descriptor());
      channel.add_watch(IOCondition.IN,  (source, condition) => {
          if (condition == IOCondition.HUP) {
          debug ("The connection has been broken.");
          Global.loop.quit();
          return false;
          }
          return Global.xcb_pool_for_event(loop,this.get_xcb_id());
        });

      loop.run();
      debug ("Dialog was quit");
    }
  }//class Dialog

  [SimpleType]
  [CCode (has_type_id = false)]
  public struct ColorRGB{
    double r;
    double g;
    double b;
  }

//~   [SimpleType]
[Compact]
[CCode (has_type_id = false)]
  public class ColorMap{
    public ColorRGB bg[5];
    public ColorRGB fg[5];
    public ColorRGB br[5];
    public ColorRGB text[5];
  }

  [SimpleType]
  [CCode (has_type_id = false)]
  public enum WidgetState{
    disabled  = 1<<1,
    hover     = 1<<2,
    focused   = 1<<3,
    activated = 1<<4  /*button pressed,selected menu or check box*/
  }
  [SimpleType]
  [CCode (has_type_id = false)]
  public enum DrawStyle{
    normal   = 0,
    active   = 1,
    hover    = 2,
    focused  = 3,
    disabled = 4
  }
  [SimpleType]
  [CCode (has_type_id = false)]
  public struct Borders{
    double top;
    double bottom;
    double left;
    double right;
  }
  [Compact]
  [CCode (has_type_id = false)]
  public class ThemeEngine{
    public string widget_path;
    public ColorMap map;
//~     public GLib.HashTable<int,Cairo.Pattern> patterns;
    public DrawStyle style;
    public Borders border;
    public Borders border_radius;
    public Borders margin;
    public Borders padding;
    public double width;
    public double height;

    public ThemeEngine(string widget_path){
      this.widget_path = widget_path;
//~       this.patterns = new GLib.HashTable<int,Cairo.Pattern> (int_hash, int_equal);
      this.map = new ColorMap();
    }
//~     public void generate_patterns(){
//~       this.patterns.insert(WidgetState.disabled,new Cairo.Pattern.rgb(map.bg.r, map.bg.g, map.bg.b));
//~     }
//~     public void set_color_map(ColorMap* map){
//~       this.map = *map;
//~     }
    public void begin(WidgetState state,double width,double height){
      this.width = width;
      this.height = height;

      if((state & WidgetState.disabled)>0){
        this.style = DrawStyle.disabled;
      }else if((state & WidgetState.activated)>0){
        this.style = DrawStyle.active;
      }else if((state & WidgetState.hover)>0){
        this.style = DrawStyle.hover;
      }else if((state & WidgetState.focused)>0){
        this.style = DrawStyle.focused;
      }else{
        this.style = DrawStyle.normal;
      }
    }//begin

    public void translate2box(Cairo.Context cr){
       double x = border.left + padding.left;
       double y = border.top + padding.top;
       double w = width
                - (/*border.left +*/ border.right)
                - (padding.left  + padding.right);
       double h = height
                - (/*border.top +*/ border.bottom)
                - (padding.top + padding.bottom);
      cr.rectangle (x, y, w, h);
      cr.clip ();
      cr.translate (x,y);
    }

    public void draw_box(Cairo.Context cr,double corner_radius = 0){
      if(corner_radius == 0){
        cr.save();
        cr.set_source_rgb(map.bg[this.style].r, map.bg[this.style].g, map.bg[this.style].b);
        cr.rectangle (0, 0, width, height);
        cr.fill_preserve ();
          cr.set_source_rgb(map.br[this.style].r, map.br[this.style].g, map.br[this.style].b);
          cr.set_line_width(2);
          cr.set_source_rgb(0, 0, 0);
          cr.rectangle (0, 0, width, height);
//~           cr.stroke ();
//~           cr.restore();
        cr.stroke ();
        cr.restore();
      }else{
        double aspect = 1.0;
        double radius = corner_radius / aspect;
        double degrees = Math.PI / 180.0;
        double x = 0;
        double y = 0;
        cr.save();
        cr.translate (border.left,border.top);
        width -= (border.left + border.right);
        height -= (border.top + border.bottom);
        cr.new_sub_path ();
        cr.arc ( x + width - radius, y + radius, radius, -90 * degrees, 0 * degrees);
        cr.arc ( x + width - radius, y + height - radius, radius, 0 * degrees, 90 * degrees);
        cr.arc ( x + radius, y + height - radius, radius, 90 * degrees, 180 * degrees);
        cr.arc ( x + radius, y + radius, radius, 180 * degrees, 270 * degrees);
        cr.close_path ();

        cr.set_source_rgb(map.bg[this.style].r, map.bg[this.style].g, map.bg[this.style].b);
        cr.fill_preserve ();
        cr.set_source_rgb ( map.br[this.style].r, map.br[this.style].g, map.br[this.style].b);
        cr.set_line_width (border.left);
        cr.stroke ();
        cr.restore();
      }

    }
  }//ThemeEngine


}//namespace Ltk
