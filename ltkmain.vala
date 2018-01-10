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

  public delegate bool ProcessEventFunc(Xcb.GenericEvent event, MainLoop loop);

  public struct  KeyMasks {
    uint16 numlock;
    uint16 shiftlock;
    uint16 capslock;
    uint16 modeswitch;
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
    public static const string _net_wm_window_type = "_NET_WM_WINDOW_TYPE";
    public static const string _net_wm_window_type_popup_menu = "_NET_WM_WINDOW_TYPE_POPUP_MENU";
    public static const string primary = "PRIMARY";
    public static const string clipboard = "CLIPBOARD";
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
    public static Xcb.KeySymbols? keysyms = null;
    public static KeyMasks key_masks;

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
              ltkdebug( "Could not connect to X11 server");
              GLib.Process.exit(1) ;
      }

      Global.I = Xcb.Icccm.new(Global.C);

      Global.setup = Global.C.get_setup();
      var s_iterator = Global.setup.roots_iterator();
      Global.screen = s_iterator.data;

      Global.keysyms = Global.C.key_symbols_alloc();
      Global.keymap_init();

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

      if(!Global.atoms.contains(atom_names.primary))
        Global.atoms.insert(atom_names.primary,
          Global.C.intern_atom_reply(Global.C.intern_atom(false,atom_names.primary)).atom);

      if(!Global.atoms.contains(atom_names.clipboard))
        Global.atoms.insert(atom_names.clipboard,
          Global.C.intern_atom_reply(Global.C.intern_atom(false,atom_names.clipboard)).atom);

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
          ltkdebug("The connection has been broken.");
          Global.loop.quit();
          return false;
          }
          return xcb_pool_for_event(Global.xcb_main_process_event,Global.loop);
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
      ltkdebug("atoms.remove_all");
      Global.atoms.remove_all();
//~       ltkdebug("windows.remove_all");
//~       Global.windows.foreach((k,v)=>{ v.window_widget.unref(); });
//~       Global.windows.remove_all();
      //~     surface.finish();
    FontLoader.destroy();

//~     ltkdebug("Global.C.unref");
//~     GLib.Source.remove(Global.xcb_source);

//~     surface.destroy();
//~     xcb_disconnect(c);
    }//run
    
    public static Xcb.Window get_xcbwindowid_from_event(Xcb.GenericEvent event){
            switch (event.response_type & ~0x80) {
              case Xcb.EXPOSE:
              case Xcb.CLIENT_MESSAGE:
              case Xcb.CONFIGURE_NOTIFY:
              case Xcb.MAP_NOTIFY:
              case Xcb.DESTROY_NOTIFY:
              case Xcb.UNMAP_NOTIFY:
              case Xcb.VISIBILITY_NOTIFY:
                 Xcb.ExposeEvent e = (Xcb.ExposeEvent)event;
                 return e.window;
              break;
              case Xcb.MOTION_NOTIFY:
              case Xcb.ENTER_NOTIFY:
              case Xcb.LEAVE_NOTIFY:
              case Xcb.KEY_PRESS:
              case Xcb.KEY_RELEASE:
              case Xcb.BUTTON_PRESS:
              case Xcb.BUTTON_RELEASE:
                 Xcb.MotionNotifyEvent e = (Xcb.MotionNotifyEvent)event;
                 return e.event;
              break;
              case Xcb.NO_EXPOSURE:
                 Xcb.NoExposureEvent e = (Xcb.NoExposureEvent)event;
                 return e.drawable;
              break;
              case 0: //don't know what is it??
              case Xcb.REPARENT_NOTIFY:
              case Xcb.PROPERTY_NOTIFY: //just ignore
              break;
              default:
                critical("Error unknown XCB event=%u",event.response_type & ~0x80);
              break;
            }
      return (Xcb.Window)0;
    }//get_xcbwindowid_from_event

    public static bool xcb_main_process_event(Xcb.GenericEvent event, MainLoop loop){
          unowned XcbWindow?  win = null;
          bool _return = true;
          uint8 response_type = (event.response_type & ~0x80);
          ltkdebug( "!!!!!!!!!!!event=%u",response_type);
          switch (response_type) {
            case Xcb.MAPPING_NOTIFY:
              Xcb.MappingNotifyEvent e = (Xcb.MappingNotifyEvent)event;
              Xcb.refresh_keyboard_mapping(Global.keysyms, e);
            break;
            case Xcb.REPARENT_NOTIFY:
            case Xcb.PROPERTY_NOTIFY:
              return _return;
            break;
            case Xcb.SELECTION_NOTIFY:
              Xcb.SelectionNotifyEvent e = (Xcb.SelectionNotifyEvent)event;
               var xcbwin = e.requestor;
               if(Global.grab_window_remap[0] == xcbwin){
                 xcbwin = Global.grab_window_remap[1];
               }
               if( (win = Global.windows.lookup(xcbwin)) != null){
                _return = win.process_event(event);
               }
            break;
            default:
               var xcbwin = Global.get_xcbwindowid_from_event(event);
               if(xcbwin != 0){
                 if(Global.grab_window_remap[1] != 0/* == xcbwin*/){
                   xcbwin = Global.grab_window_remap[1];
                 }
                 if( (win = Global.windows.lookup(xcbwin)) != null){
                  _return = win.process_event(event);
                 }
              }
            break;
          }//switch
          Global.C.flush();
          if(!_return){
            loop.quit ();
          }
      return _return;
    }//xcb_main_process_event

    public static bool xcb_pool_for_event(ProcessEventFunc process_event_func, MainLoop loop){
         Xcb.GenericEvent event = null;
         bool _return = true;

//~           ltkdebug( "!!!!!!!!!!!event");
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

          while ( _return && ( (event = Global.C.poll_for_event()) != null ) ) {
            _return = process_event_func(event,loop);
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
    public static GLib.MainContext loop_get_context(){
		return loop.get_context ();
	}

  private static uint16 _xcb_keymap_mask_get(Xcb.GetModifierMappingReply reply, Xcb.KeySym   sym){
   uint16 mask = 0;
   const Xcb.ModMask masks[8] =
   {
      Xcb.ModMask.SHIFT, Xcb.ModMask.LOCK, Xcb.ModMask.CONTROL,
      Xcb.ModMask.@1, Xcb.ModMask.@2, Xcb.ModMask.@3, Xcb.ModMask.@4,
      Xcb.ModMask.@5
   };

   if ((reply != null) && (reply.keycodes_per_modifier > 0))
     {
        int i = 0;
        unowned Xcb.Keycode[] modmap;
        Xcb.KeySym   sym2 = 0;

        modmap = Xcb.get_modifier_mapping_keycodes(reply);
        for (i = 0; i < (8 * reply.keycodes_per_modifier); i++)
          {
             int j = 0;

             for (j = 0; j < 8; j++)
               {
                  sym2 =
                    Xcb.key_symbols_get_keysym(Global.keysyms,
                                               modmap[i], j);
                  if (sym2 != 0) break;
               }
             if (sym2 == sym)
               {
                  mask = masks[i / reply.keycodes_per_modifier];
                  break;
               }
          }
     }

   return mask;
  }

  public static void keymap_init(){
    var reply = Global.C.get_modifier_mapping_reply(Global.C.get_modifier_mapping_unchecked());
    if(reply != null){
       Global.key_masks.modeswitch = _xcb_keymap_mask_get(reply, Xkb.Key.Mode_switch);
       Global.key_masks.shiftlock = _xcb_keymap_mask_get(reply, Xkb.Key.Shift_Lock);
       Global.key_masks.capslock = _xcb_keymap_mask_get(reply, Xkb.Key.Caps_Lock);
       Global.key_masks.numlock = _xcb_keymap_mask_get(reply, Xkb.Key.Num_Lock);
    }
  }

  public static Xcb.KeySym	key_getkeysym(Xcb.Keycode detail, uint16 state){
      Xcb.KeySym k0, k1;

      /* 'col'  (third  parameter)  is  used  to  get  the  proper  KeySym
       * according  to  modifier (XCB  doesn't  provide  an equivalent  to
       * XLookupString()).
       *
       * If Mode_Switch is ON we look into second group.
       */
      if( (state & Global.key_masks.modeswitch) > 0)
      {
        k0 = Xcb.key_symbols_get_keysym(Global.keysyms, detail, 2);
        k1 = Xcb.key_symbols_get_keysym(Global.keysyms, detail, 3);
      }
      else
      {
        k0 = Xcb.key_symbols_get_keysym(Global.keysyms, detail, 0);
        k1 = Xcb.key_symbols_get_keysym(Global.keysyms, detail, 1);
      }

      /* If the second column does not exists use the first one. */
      if(k1 == Xcb.NO_SYMBOL)
        k1 = k0;

      if ((state & Global.key_masks.numlock)>0 &&
         ((Xcb.is_keypad_key(k1)) || (Xcb.is_private_keypad_key(k1))))
       {
          if ((state & Xcb.ModMask.SHIFT)>0 ||
              ((state & Xcb.ModMask.LOCK)>0 && (state & Global.key_masks.shiftlock)>0))
            return k0;
          else
            return k1;
       }
      else if ((state & Xcb.ModMask.SHIFT)==0 && (state & Xcb.ModMask.LOCK)==0)
       return k0;
      else if ((state & Xcb.ModMask.SHIFT)==0 &&
              ((state & Xcb.ModMask.LOCK)>0 && (state & Global.key_masks.capslock)>0))
       return k1;
      else if ((state & Xcb.ModMask.SHIFT)>0 &&
              (state & Xcb.ModMask.LOCK)>0 && (state & Global.key_masks.capslock)>0)
       return k0;
      else if ((state & Xcb.ModMask.SHIFT)>0 ||
              ((state & Xcb.ModMask.LOCK)>0 && (state & Global.key_masks.shiftlock)>0))
       return k1;

      return Xcb.NO_SYMBOL;
      /* The  numlock modifier is  on and  the second  KeySym is  a keypad
       * KeySym */
      if( ((state & Global.key_masks.numlock)> 0) && Xcb.is_keypad_key(k1))
      {
        ltkdebug("state=%u numlock=%u",state , Global.key_masks.numlock);
        /* The Shift modifier  is on, or if the Lock  modifier is on and
         * is interpreted as ShiftLock, use the first KeySym */
        if((state & Xcb.ModMask.SHIFT)>0 ||
          ((state & Xcb.ModMask.LOCK)>0 &&
          ((state & Global.key_masks.shiftlock)>0) )){
          return k0;
        }else{
          return k1;
        }
      }

      /* The Shift and Lock modifers are both off, use the first KeySym */
      else if( ((state & Xcb.ModMask.SHIFT) == 0) && ((state & Xcb.ModMask.LOCK) == 0))
      return k0;

      /* The Shift  modifier is  off and  the Lock modifier  is on  and is
       * interpreted as CapsLock */
      else if( ((state & Xcb.ModMask.SHIFT) == 0) &&
        ( ((state & Xcb.ModMask.LOCK) >0) && ((state & Global.key_masks.capslock)) >0 ))
      /* The  first Keysym  is  used  but if  that  KeySym is  lowercase
       * alphabetic,  then the  corresponding uppercase  KeySym  is used
       * instead */
      return k1;

      /* The Shift modifier is on, and the Lock modifier is on and is
       * interpreted as CapsLock */
      else if( ((state & Xcb.ModMask.SHIFT) >0) &&
        ( ( (state & Xcb.ModMask.LOCK) > 0) && ((state & Global.key_masks.capslock)>0) ) )
      /* The  second Keysym  is used  but  if that  KeySym is  lowercase
       * alphabetic,  then the  corresponding uppercase  KeySym  is used
       * instead */
      return k1;

      /* The  Shift modifer  is on,  or  the Lock  modifier is  on and  is
       * interpreted as ShiftLock, or both */
      else if( ( (state & Xcb.ModMask.SHIFT) > 0) ||
        ( ((state & Xcb.ModMask.LOCK)>0) && ((state & Global.key_masks.shiftlock) >0 ) ))
      return k1;

      return Xcb.NO_SYMBOL;
    }//key_getkeysym
    
    public static void get_clipboard(){
//~ 		atom_names.primary
	}

  }//struct Global
}//namespace Ltk
