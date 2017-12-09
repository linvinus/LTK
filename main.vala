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

    var window = new Ltk.Window();
    window.size_policy = Ltk.SizePolicy.horizontal;
    window.fill_mask |= Ltk.ContainerFillPolicy.fill_height | Ltk.ContainerFillPolicy.fill_width;
    window.set_title("xcb_vala");
    window.set_size(800,600);
    window.load_font_with_size("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",14);
    window.show();

    var container = new Ltk.Container();
    container.size_policy = Ltk.SizePolicy.vertical;
    container.fill_mask |= Ltk.ContainerFillPolicy.fill_height;
    var button = new Ltk.Button("1Vertical :)))");
    button.fill_mask |= Ltk.ContainerFillPolicy.fill_width;
    container.add(button);
    button.width=300;
    button = new Ltk.Button("2Vertical :)))");
    button.fill_mask |= Ltk.ContainerFillPolicy.fill_width;
    container.add(button);
    button.height=200;
    button.width=200;
//~     button = new Ltk.Button("3Vertical :)))");
//~     button.fill_mask |= Ltk.ContainerFillPolicy.fill_width;
//~     container.add(button);

    var container2 = new Ltk.Container();
    container2.size_policy = Ltk.SizePolicy.horizontal;
    container2.fill_mask |= Ltk.ContainerFillPolicy.fill_width;
    button = new Ltk.Button("1horizontal :)))");
    container2.add(button);
    button.width=300;
    container2.add(container);
    button = new Ltk.Button("2horizontal :)))");
    container2.add(button);
    button.height=200;
    button.width=200;
    button = new Ltk.Button("3horizontal :)))");
    container2.add(button);

    window.add(container2);

    window.run();
//~     surface.finish();
    FontLoader.destroy();
//~     surface.destroy();
//~     xcb_disconnect(c);

  return 0;
}
