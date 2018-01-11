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


using Posix;


int main (string[] argv) {

    Ltk.Global.Init(true,"/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf");

    var window = new Ltk.Window();
    window.place_policy = Ltk.SOptions.place_horizontal;
    window.fill_mask = Ltk.SOptions.fill_vertical | Ltk.SOptions.fill_horizontal;
    window.set_title("xcb_vala");
//~     window.set_size(800,600);
//~     window.show();

    var container = new Ltk.Container();
    container.place_policy = Ltk.SOptions.place_vertical;
    container.fill_mask |= Ltk.SOptions.fill_vertical;
    var button = new Ltk.Button("1Vertical :)))");
//~     button.fill_mask |= Ltk.SOptions.fill_horizontal;
    button.min_width = 51;
    container.add(button);
//~     button.width=300;
    var button2 = new Ltk.Button("2Vertical :)))");
//~     button.fill_mask |= Ltk.SOptions.fill_horizontal;
    container.add(button2);
//~     button.height=200;
//~     button.width=200;
    button = new Ltk.Button("3Vertical :)))");
    button.fill_mask |= Ltk.SOptions.fill_vertical | Ltk.SOptions.fill_horizontal;
    container.add(button);
    bool tick = false;
    GLib.SourceFunc ontime = ()=>{
      ltkdebug("GLib.Timeout\n");
//~       button.label += ""
      if(!tick){
        button2.min_width += 100;
      }else{
        button2.min_width -= 100;
      }
      ltkdebug("***    fill_mask=%u place_policy=%u A.options=%u label=%s\n", button2.fill_mask, button2.place_policy, button2.A.options, button2.label);
      Ltk.Container c = (Ltk.Container)button.parent;
//~       uint oldw = c.width;
//~       uint oldh = c.height;
//~       c.calculate_size(ref oldw,ref oldh);
//~       c.size_request(oldw, oldh);
//~       window.update_childs_sizes();
      ltkdebug("***    fill_mask=%u place_policy=%u A.options=%u label=%s\n", button2.fill_mask, button2.place_policy, button2.A.options, button2.label);
//~       window.damage(0,0,window.A.width,window.A.height);

      tick = !tick;
      return GLib.Source.CONTINUE;
      };
    GLib.Timeout.add(500000,ontime);

    var container2 = new Ltk.Container();
    container2.place_policy = Ltk.SOptions.place_horizontal;
    container2.fill_mask |= Ltk.SOptions.fill_horizontal;
    button = new Ltk.Button("1horizontal :)))");
    button.fill_mask |= Ltk.SOptions.fill_horizontal;
    container2.add(button);
//~     button.width=300;
    container2.add(container);
	weak Ltk.Window win_parent = window;
    var button4 = new Ltk.Button("2horizontal :)))");
    container2.add(button4);
//~     button.height=200;
//~     button.width=200;
    button4.on_click.connect(()=>{
			ltkdebug("__________ button4.on_click");
		    var dialog = new Ltk.Dialog(win_parent);
			dialog.place_policy = Ltk.SOptions.place_horizontal;
			dialog.fill_mask = Ltk.SOptions.fill_vertical | Ltk.SOptions.fill_horizontal;
			dialog.set_title("xcb_vala_dialog");

			var butt = new Ltk.Button("Hello from dialog!");
			dialog.add(butt);
			dialog.show();
			dialog.run();

		});

    var button3 = new Ltk.Button("3horizontal :)))");
    container2.add(button3);
    
    button3.on_click.connect(()=>{
      ltkdebug("__________ button3.on_click");
//~ 		    var dialog = new Ltk.Dialog(win_parent);
      var menu = new Ltk.PopupMenu(win_parent);
      var butt = new Ltk.Button("Hello from dialog!");
      menu.add(butt);
      menu.ref();
      menu.popup();
//~ 			dialog.run();

		});

    window.add(container2);

    window.show();

    Ltk.Global.run();


  return 0;
}
