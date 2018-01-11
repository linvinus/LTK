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

	public class PopupMenu: Window{
		private weak Window parent_window;
		public PopupMenu(Window parent){
      this.place_policy = Ltk.SOptions.place_horizontal;
      this.fill_mask = Ltk.SOptions.fill_vertical | Ltk.SOptions.fill_horizontal;
		  this.parent_window = parent;
      this.parent_window.get_xcb_window().on_mouse_leave(0,0);//emulate mouse leave event
		  var win = this.get_xcb_window();
		  win.on_button_press.connect(this._on_button_press);
		  win.set_type_popup_menu();
		  win.set_transient_for(this.parent_window.get_xcb_window().get_xcb_id());
		}
    public void popup(){
		  int16 x=0,
				y=0,
				wx=0,
				wy=0;
      var win = this.get_xcb_window();

      

		  if(Global.query_pointer(ref x,ref y,ref wx,ref wy)){
        ltkdebug("PopupMenu query_pointer x,y=%u,%u",x,y);
        win.move_resize(x,y,this.A.width,this.A.height);
      }else{
        ltkdebug("PopupMenu query_pointer error");
      }

      this.show();
		  ltkdebug("PopupMenu grab_pointer=%u win_id=%u",(uint)win.grab_pointer(),win.get_xcb_id());
    }
		private void _on_button_press(uint button,uint state,uint x, uint y){
      if(button == 1 || button == 3){
        var win = this.get_xcb_window();
        ltkdebug("PopupMenu on_button_press xy=%u,%u win xy=%u,%u wh=%u,%u",x,y,win.x,win.y,win.width,win.height);
        if( !( ( x > win.x  && x < (win.x + win.width) ) &&
               ( y > win.y  && y < (win.y + win.height) ) ) ){
                 ltkdebug("PopupMenu destroy count=%u",this.ref_count);
    //~                                  win.unref();
                 win.on_button_press.disconnect(_on_button_press);
                 this.unref();
        }
      }
		}
	}//class PopupMenu
	
}//namespace Ltk
