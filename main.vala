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
    window.show();
    window.set_title("xcb_vala");
    window.set_size(800,600);
    window.load_font_with_size("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",14);

    var button = new Ltk.Button("Проверка :)))");
    window.add(button);
    
    window.run();

//~     surface.finish();
    FontLoader.destroy();
//~     surface.destroy();
//~     xcb_disconnect(c);

  return 0;
}
