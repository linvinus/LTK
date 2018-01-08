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
    public static const string _net_wm_window_type = "_NET_WM_WINDOW_TYPE";
    public static const string _net_wm_window_type_popup_menu = "_NET_WM_WINDOW_TYPE_POPUP_MENU";
  }	
	
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
    private static unowned XcbWindow grab_pointer_author;
    private static Xcb.Window grab_window_remap[2];
    public static Cairo.FontFace Font;
    public static Xcb.KeySymbols? syms = null;

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


    public  static void Init(bool debug_enable,string fpath){
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

	  try{
		Global.Font = FontLoader.load(fpath);//default application font
	  }catch(FileError e){
		  critical(e.message);
	  }

      Global.atoms = new GLib.HashTable<string, Xcb.AtomT?> (str_hash, str_equal);
      Global.windows = new GLib.HashTable<Xcb.Window,unowned XcbWindow> (direct_hash, direct_equal);
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

      Global.syms = Global.C.key_symbols_alloc();

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

      if(!Global.atoms.contains(atom_names._net_wm_window_type))
        Global.atoms.insert(atom_names._net_wm_window_type,
          Global.C.intern_atom_reply(Global.C.intern_atom(false,atom_names._net_wm_window_type)).atom);

      if(!Global.atoms.contains(atom_names._net_wm_window_type_popup_menu))
        Global.atoms.insert(atom_names._net_wm_window_type_popup_menu,
          Global.C.intern_atom_reply(Global.C.intern_atom(false,atom_names._net_wm_window_type_popup_menu)).atom);

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
            unowned XcbWindow?  win = null;
            switch (event.response_type & ~0x80) {
              case Xcb.EXPOSE:
              case Xcb.CLIENT_MESSAGE:
                 Xcb.ExposeEvent e = (Xcb.ExposeEvent)event;
                 var xcbwin = e.window;
                 if(Global.grab_window_remap[0] == xcbwin){
                   xcbwin = Global.grab_window_remap[1];
                 }
                 if( ( (onlywindow != 0 && onlywindow == xcbwin)||
                     onlywindow == 0 ) && ( win = Global.windows.lookup(xcbwin)) != null){
                 _return = win.process_event(event);
                   if(!_return){
                     loop.quit ();
                     }
                 }
              break;
              case Xcb.CONFIGURE_NOTIFY:
                 Xcb.ConfigureNotifyEvent e = (Xcb.ConfigureNotifyEvent)event;
                 var xcbwin = e.window;
                 if(Global.grab_window_remap[0] == xcbwin){
                   xcbwin = Global.grab_window_remap[1];
                 }
                 if( ( (onlywindow != 0 && onlywindow == xcbwin)||
                     onlywindow == 0 ) && ( win = Global.windows.lookup(xcbwin)) != null){
                  _return = win.process_event(event);
                }
              break;
              case Xcb.MOTION_NOTIFY:
              case Xcb.ENTER_NOTIFY:
              case Xcb.LEAVE_NOTIFY:
              case Xcb.KEY_PRESS:
              case Xcb.KEY_RELEASE:
              case Xcb.BUTTON_PRESS:
              case Xcb.BUTTON_RELEASE:
                 Xcb.MotionNotifyEvent e = (Xcb.MotionNotifyEvent)event;
                 debug("BUTTON_PRESS window=%u child=%u root=%u",e.event,e.child,e.root);
                 var xcbwin = e.event;
                 if(Global.grab_window_remap[0] == xcbwin){
                   xcbwin = Global.grab_window_remap[1];
                 }
                 if( ( (onlywindow != 0 && onlywindow == xcbwin)||
                     onlywindow == 0 ) && ( win = Global.windows.lookup(xcbwin)) != null){
                  _return = win.process_event(event);
                 }
              break;
              case Xcb.MAPPING_NOTIFY:
				  Xcb.MappingNotifyEvent e = (Xcb.MappingNotifyEvent)event;
				  Xcb.refresh_keyboard_mapping(Global.syms, e);
              break;
             }
           Global.C.flush();
           free(event);
          }
      return _return;
    }//xcb_pool_for_event

    public static Xcb.GrabStatus xcb_grab_pointer (
    Ltk.XcbWindow author,
    bool owner_events,
    Xcb.Window grab_window,
    uint16 event_mask,
    Xcb.GrabMode pointer_mode,
    Xcb.GrabMode keyboard_mode,
    Xcb.Window confine_to,
    Xcb.Cursor cursor,
    Xcb.Timestamp time){
        if(Global.grab_pointer_author == null ){
            var reply = Global.C.grab_pointer_reply(Global.C.grab_pointer(
                owner_events,
                grab_window,
                event_mask,
                pointer_mode,
                keyboard_mode,
                confine_to,
                cursor,
                time
            ));

            if(reply.status == Xcb.GrabStatus.SUCCESS){
                Global.grab_pointer_author = author;
                Global.grab_window_remap[0]=grab_window;//event destination
                Global.grab_window_remap[1]=author.get_xcb_id();//remap to
            }
            return reply.status;
        }else{
            return Xcb.GrabStatus.FROZEN;//error
        }
    }//xcb_grab_pointer

    public static bool xcb_ungrab_pointer (Ltk.XcbWindow author){
      if(Global.grab_pointer_author == author){
        Global.C.ungrab_pointer(0);
        Global.grab_pointer_author = null;
        Global.grab_window_remap[0]=Global.grab_window_remap[1]=0;
        return true;
      }
      return false;
    }//xcb_ungrab_pointer
    
    public static void quit(){
		loop.quit ();
	}
  }//struct Global
}//namespace Ltk
