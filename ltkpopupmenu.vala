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
		  this.parent_window = parent;
		  var win = this.get_xcb_window();
		  win.set_type_popup_menu();
		  win.set_transient_for(this.parent_window.get_xcb_window());
		  ltkdebug("PopupMenu grab_pointer=%u win_id=%u",(uint)win.grab_pointer(),win.get_xcb_id());
		  win.on_button_press.connect(this._on_button_press);
		  int16 x=0,
				y=0,
				wx=0,
				wy=0;
		  win.query_pointer(ref x,ref y,ref wx,ref wy);
		  win.move_resize(x,y,this.min_width,this.min_height);
		}
		private void _on_button_press(uint button,uint x, uint y){
			var win = this.get_xcb_window();
			ltkdebug("PopupMenu on_button_press xy=%u,%u",x,y);
			if( !( ( x > win.x  && x < (win.x + win.width) ) &&
						 ( y > win.y  && y < (win.y + win.height) ) ) ){
							 ltkdebug("PopupMenu destroy count=%u",this.ref_count);
	//~                                  win.unref();
							 win.on_button_press.disconnect(_on_button_press);
							 this.unref();
							 
			}
		}
	}//class PopupMenu
	
}//namespace Ltk
