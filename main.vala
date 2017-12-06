using Posix;


int main (string[] argv) {

    var window = new Ltk.Window();
    window.set_title("xcb_vala");
    window.set_size(800,600);
    window.show();
    window.load_font_with_size("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",14);

    window.run();

//~     surface.finish();
    FontLoader.destroy();
//~     surface.destroy();
//~     xcb_disconnect(c);

  return 0;
}
