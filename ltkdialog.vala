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
	
  public class Dialog: Window{
    private weak Window parent_window;
    public Dialog(Window parent){
      this.parent_window = parent;
      var xcbwin = this.get_xcb_window();
      xcbwin.set_type_modal(true);
      xcbwin.set_transient_for(this.parent_window.get_xcb_window().get_xcb_id());
    }

    //process events for dialog only
    private bool dialog_event_func(Xcb.GenericEvent event, MainLoop loop){
      var xid = Global.get_xcbwindowid_from_event(event);
      if(xid != 0 && xid == this.get_xcb_window().get_xcb_id() )
        return Global.xcb_main_process_event(event,loop);
      else
        return true;//skip event and continue
    }

    public void run(){
      this.show();
      var loop = new MainLoop ();
      var channel = new IOChannel.unix_new(Global.C.get_file_descriptor());
      channel.add_watch(IOCondition.IN,  (source, condition) => {
          if (condition == IOCondition.HUP) {
            ltkdebug("The connection has been broken.");
            loop.quit();
            return false;
          }
          return Global.xcb_pool_for_event(this.dialog_event_func,loop);
        });

      loop.run();
      ltkdebug("Dialog was quit");
    }
  }//class Dialog
  
}//namespace Ltk
