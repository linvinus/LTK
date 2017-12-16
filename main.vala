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

    Ltk.Global.Init();

    var window = new Ltk.Window();
    window.place_policy = Ltk.SOptions.place_horizontal;
    window.fill_mask = Ltk.SOptions.fill_vertical | Ltk.SOptions.fill_horizontal;
    window.set_title("xcb_vala");
//~     window.set_size(800,600);
    window.load_font_with_size("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",14);
//~     window.show();

    var container = new Ltk.Container();
    container.place_policy = Ltk.SOptions.place_vertical;
    container.fill_mask |= Ltk.SOptions.fill_vertical;
    var button = new Ltk.Button("1Vertical :)))");
    button.fill_mask |= Ltk.SOptions.fill_horizontal;
    container.add(button);
//~     button.width=300;
    button = new Ltk.Button("2Vertical :)))");
//~     button.fill_mask |= Ltk.SOptions.fill_width;
    container.add(button);
//~     button.height=200;
//~     button.width=200;
//~     button = new Ltk.Button("3Vertical :)))");
//~     button.fill_mask |= Ltk.SOptions.fill_width | Ltk.ContainerFillPolicy.fill_height;
//~     container.add(button);
    bool tick = false;
    GLib.SourceFunc ontime = ()=>{
      GLib.stderr.printf("GLib.Timeout\n");
//~       button.label += ""
      if(!tick){
        button.min_width += 100;
      }else{
        button.min_width -= 100;
      }
      Ltk.Container c = (Ltk.Container)button.parent;
//~       uint oldw = c.width;
//~       uint oldh = c.height;
//~       c.calculate_size(ref oldw,ref oldh);
//~       c.size_request(oldw, oldh);
      window.update_childs_sizes();
      window.clear_area(0,0,window.min_width,window.min_height);

      tick = !tick;
      return GLib.Source.CONTINUE;
      };
    GLib.Timeout.add(1000,ontime);

    var container2 = new Ltk.Container();
    container2.place_policy = Ltk.SOptions.place_horizontal;
    container2.fill_mask |= Ltk.SOptions.fill_horizontal;
    button = new Ltk.Button("1horizontal :)))");
    button.fill_mask |= Ltk.SOptions.fill_horizontal;
    container2.add(button);
//~     button.width=300;
    container2.add(container);
    button = new Ltk.Button("2horizontal :)))");
    container2.add(button);
//~     button.height=200;
//~     button.width=200;
    button = new Ltk.Button("3horizontal :)))");
    container2.add(button);

    window.add(container2);

    window.show();

    Ltk.Global.run();


  return 0;
}
