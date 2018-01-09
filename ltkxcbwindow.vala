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

namespace Ltk{
	
  public class XcbWindow : GLib.Object{
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
    public int x {
			get {return (int)this.pos_x;}
		}
    public int y {
			get {return (int)this.pos_y;}
		}
    public uint width {
			get {return this.min_width;}
		}
    public uint height {
			get {return this.min_height;}
		}
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
      Global.xcb_ungrab_pointer(this);
      
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
                     e.window = Global.screen.root;
                     Global.C.send_event(false,0,0,e);//PONG, XCB_SEND_EVENT_DEST_POINTER_WINDOW == 0
                  }else if(e.data.data32[0] == Global.deleteWindowAtom){
                      _continue = this.on_quit();//true to quit, false to continue
                      if(_continue){
                        this.quit();
                        _continue = false;
                      }else{
                        _continue = true;
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
               uint32 k = Global.key_getkeysym(e.detail, e.state);
               this.on_key_press(k, (uint) e.state);
            break;
            case Xcb.KEY_RELEASE:
               Xcb.KeyReleaseEvent e = (Xcb.KeyReleaseEvent)event;
               uint32 k = Global.key_getkeysym(e.detail, e.state);
               this.on_key_release(k, (uint) e.state);
            break;
            case Xcb.BUTTON_PRESS:
               Xcb.ButtonPressEvent e = (Xcb.ButtonPressEvent)event;
               this.on_button_press((uint)e.detail,e.state, (uint) e.event_x, (uint) e.event_y);
            break;
            case Xcb.BUTTON_RELEASE:
               Xcb.ButtonReleaseEvent e = (Xcb.ButtonReleaseEvent)event;
               this.on_button_release((uint)e.detail,e.state, (uint) e.event_x, (uint) e.event_y);
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
      cr.set_font_face(Global.Font);//use default font,avoid call cairo_scaled_font_create,and using libfontconfig, reduce RSS my 1MB
      cr.set_font_size (12);        //default size
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
    
    public void set_type_modal(bool mode){
        uint32 modal = (uint32)Global.atoms.lookup(atom_names._net_wm_state_modal);
        if(mode){
          Global.C.change_property_uint32  ( Xcb.PropMode.APPEND,
                               this.window,
                               Global.atoms.lookup(atom_names._net_wm_state),
                               Xcb.Atom.ATOM,
                               1,
                               &modal);
        }else{
          Global.C.change_property_uint32  ( Xcb.PropMode.REPLACE,
                               this.window,
                               Global.atoms.lookup(atom_names._net_wm_state),
                               Xcb.Atom.ATOM,
                               0,
                               &modal);
        }

    }
    public void set_type_popup_menu(){
        uint32 popupA = (uint32)Global.atoms.lookup(atom_names._net_wm_window_type_popup_menu);
          Global.C.change_property_uint32  ( Xcb.PropMode.REPLACE,
                               this.window,
                               Global.atoms.lookup(atom_names._net_wm_window_type),
                               Xcb.Atom.ATOM,
                               1,
                               &popupA);
        uint32 values[1];
        values[0] = 1;
        Global.C.change_window_attributes (this.window, Xcb.CW.OVERRIDE_REDIRECT, values);
    }

    public void set_transient_for(XcbWindow parent){
//~         uint32 modal = (uint32)Global.atoms.lookup(atom_names._net_wm_state_modal);
          Global.C.change_property_uint32  ( Xcb.PropMode.APPEND,
                               this.window,
                               Xcb.Atom.WM_TRANSIENT_FOR,
                               Xcb.Atom.WINDOW,
                               1,
                               &parent.window);
    }

    public bool grab_pointer(){
      uint16 grab_mask = Xcb.EventMask.BUTTON_PRESS|
                  Xcb.EventMask.BUTTON_RELEASE|
                  /*Xcb.EventMask.POINTER_MOTION|*/
                  Xcb.EventMask.LEAVE_WINDOW|
                  Xcb.EventMask.ENTER_WINDOW;

            var reply = Global.xcb_grab_pointer(
                this,
                true,               /* get all pointer events specified by the following mask */
                /*this.window*/Global.screen.root,        /* grab the root window */
                /*XCB_NONE*/ grab_mask,            /* which events to let through */
                Xcb.GrabMode.ASYNC, /* pointer events should continue as normal */
                Xcb.GrabMode.ASYNC, /* keyboard mode */
                /*XCB_NONE*/ 0,            /* confine_to = in which window should the cursor stay */
                /*cursor*/0,              /* we change the cursor to whatever the user wanted */
                /*XCB_CURRENT_TIME*/ 0
            );

        if (reply == Xcb.GrabStatus.SUCCESS){
            return true;
        }
        return false;
    }//grab_pointer

    public bool ungrab_pointer(){
      return Global.xcb_ungrab_pointer(this);
    }
    
    public void query_pointer(
    /*ref uint8 same_screen,
		ref Xcb.Window root,
		ref Xcb.Window child,*/
		ref int16 root_x,
		ref int16 root_y,
		ref int16 win_x,
		ref int16 win_y
    ){
      var reply = Global.C.query_pointer_reply(Global.C.query_pointer(this.window));
      root_x = reply.root_x;
      root_y = reply.root_y;
      win_x = reply.win_x;
      win_y = reply.win_y;
    }

    public signal void size_changed(uint width,uint height);//for parents
    public signal bool draw(Cairo.Context cr);
    public signal void on_mouse_move(uint x, uint y);
    public signal void on_mouse_enter(uint x, uint y);
    public signal void on_mouse_leave(uint x, uint y);
    public signal void on_button_press(uint button, uint state, uint x, uint y);
    public signal void on_button_release(uint detail, uint state, uint x, uint y);
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
}//namespace Ltk
