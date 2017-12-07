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


namespace Ltk{
  [SimpleType]
  [CCode (has_type_id = false)]
  public enum WindowState{
    unconfigured,
    hidden,
    visible
  }
  [SimpleType]
  [CCode (has_type_id = false)]
  public enum ContainerFillPolicy{
    fill_width=1,
    fill_height=2
  }
  [SimpleType]
  [CCode (has_type_id = false)]
  public enum SizePolicy{
    horizontal=1,
    vertical=2
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
  }
  [SimpleType]
  [CCode (has_type_id = false)]
  public struct Allocation{
    uint x;
    uint y;
    uint w;
    uint h;
  }

/*  public struct FColor{
    float a;
    float r;
    float g;
    float b;
  }

  [SimpleType]
  [CCode (has_type_id = false)]
  public enum StyleColor{
    bg_color,
    fg_color,
    text_bg_color,
    text_fg_color,
    border_color
  }
  private FColor[] colors_internal={ {0,1,1,1},
                                     {0,0,0,0},
                                   };

  private static GLib.List<Ltk.StyleColor,> style_colors;
  */
  /********************************************************************/
  public class Widget : GLib.Object{
    public Widget? parent;
    public GLib.List<Widget> childs;
    public uint width;
    public uint height;
    public uint x;
    public uint y;
    public Allocation A;
    public ContainerFillPolicy fill_mask = 0;
    public SizePolicy size_policy = SizePolicy.horizontal;

    public virtual uint get_prefered_width(){
      return this.width;
    }
    public virtual uint get_prefered_height(){
      return this.height;
    }

    public Widget(Widget? parent = null){
      GLib.Object();
      this.x = this.y = 0;
      if(parent != null)
        this.parent = parent;
    }//create

    public virtual bool draw(Cairo.Context cr){
        cr.save();
        cr.set_line_width(2);
        cr.set_source_rgb(0, 0, 0);
        cr.rectangle (this.x, this.y, this.width, this.height);
        cr.stroke ();
        cr.restore();
      return true;//continue
    }//draw
  }
  /********************************************************************/
  public class Container: Widget{
    private bool _calculating_size = false;
    public Container(){
      base();
      this.fill_mask = ContainerFillPolicy.fill_height|ContainerFillPolicy.fill_width;
    }
    public void add(Widget child){
      child.parent = this;
      this.childs.append(child);
      this.calculate_size();
    }

    public void remove(Widget child){
      this.childs.remove(child);
      this.calculate_size();
    }

    public override uint get_prefered_width(){
      int h = -1;
      uint wmin,wmax;
      this.get_width_for_height(h,out wmin,out wmax);
      return (this.size_policy == SizePolicy.horizontal? wmax : wmin);
    }
    public override uint get_prefered_height(){
      int w = -1;
      uint hmin,hmax;
      this.get_height_for_width(w,out hmin,out hmax);
      return (this.size_policy == SizePolicy.vertical? hmax : hmin);
    }

    public virtual void get_height_for_width(int width,out uint height_min,out uint height_max){
      uint _h;
      foreach(var w in this.childs){
        _h = w.get_prefered_height();
        height_max += _h;
        height_min = uint.max(height_min, _h);
      }
    }
    public virtual void get_width_for_height(int height,out uint width_min,out uint width_max){
      uint _w;
      foreach(var w in this.childs){
        _w = w.get_prefered_width();
        width_max += _w;
        width_min = uint.max(width_min,_w);
      }
    }
    public virtual void calculate_size(){
      GLib.stderr.printf( "container calculate_size w=%u h=%u loop=%d\n", this.width,this.height,(int)this._calculating_size);
      if(this._calculating_size)
        return;
      int w = -1;
      int h = -1;
      uint hmin,hmax,wmin,wmax;
      this._calculating_size=true;
        this.get_height_for_width(w,out hmin,out hmax);
        this.get_width_for_height(h,out wmin,out wmax);
        if(this.size_policy == SizePolicy.horizontal){
          this.width = wmax;
          this.height = hmin;
        }else{
          this.width = wmin;
          this.height = hmax;
        }
      this._calculating_size=false;
    }
    public override bool draw(Cairo.Context cr){
        uint len = this.childs.length();
        uint _x = 0, _y = 0, _w = 0, _h = 0;
        cr.save();
        cr.set_line_width(2);
        cr.set_source_rgb(1, 0, 0);
        cr.rectangle (this.x, this.y, this.width, this.height);
        cr.stroke ();
        cr.restore();
        foreach(var w in this.childs){
          cr.save();
  //~           GLib.stderr.printf( "childs draw %d\n",(int)w.width);
  //~           cr.move_to ();
            if(this.size_policy == SizePolicy.horizontal){
              cr.translate (_x,(this.height-w.height)/2);
              _x+=w.width;
            }else{
              cr.translate ((this.width-w.width)/2,_y);
              _y+=w.height;
            }
            cr.rectangle (0, 0,w.width/*+border.left+border.right*/, w.height/*+border.top+border.bottom*/);
            cr.clip ();
            w.draw(cr);
          cr.restore();

        }//foreach
        return base.draw(cr);
      }
  }//class container
  /********************************************************************/
  public class Window: Container{
    private bool _calculating_size = false;
    public  Xcb.Connection C;
    private Xcb.Setup setup;
    private unowned Xcb.Icccm.Icccm I;
    private uint32 window;
    private weak Xcb.Screen screen;
    private Cairo.XcbSurface surface;
    private Cairo.Context cr;
    private HashTable<string, Xcb.AtomT?> atoms;
    private WindowState _wState;
    private WindowState state{
      get { return _wState;}
      set {
        if(_wState != value){
          if(value == WindowState.visible ){
            _wState = value;
            this.show_do();
            this.set_title_do();
//~             this.set_size_do();
            this.configure_window_do();
            this.C.flush();
          }else if(value == WindowState.hidden ){ //WindowState.unconfigured is ignored
            _wState = value;
            //this.hide_do();
          }
        }
      }
    }
    private string? title = null;
    private int pos_x = 0;
    private int pos_y = 0;


    public Window(){

      base();
      this.width=this.height=1;

      this.state = WindowState.unconfigured;
      this.atoms = new HashTable<string, Xcb.AtomT?> (str_hash, str_equal);

      this.C = new Xcb.Connection();


      if (this.C.has_error() != 0) {
//~               printf( "Could not connect to X11 server");
              return ;//null;
      }

      this.I = Xcb.Icccm.new(this.C);

      this.setup = this.C.get_setup();
      var s_iterator = this.setup.roots_iterator();
      this.screen = s_iterator.data;
      this.window = this.C.generate_id();

      uint32 mask[2];
      mask[0] = 1;
      mask[1] = Xcb.EventMask.EXPOSURE|Xcb.EventMask.VISIBILITY_CHANGE|Xcb.EventMask.STRUCTURE_NOTIFY;

      this.C.create_window(Xcb.COPY_FROM_PARENT, this.window, this.screen.root,
                (int16)this.pos_x, (int16)this.pos_y, (uint16)this.width, (uint16)this.height, 0,
                Xcb.WindowClass.INPUT_OUTPUT,
                this.screen.root_visual,
                /*Xcb.CW.OVERRIDE_REDIRECT |*/ Xcb.CW.BACK_PIXEL| Xcb.CW.EVENT_MASK,
                mask);



      var hints =  new Xcb.Icccm.WmHints ();
      Xcb.Icccm.wm_hints_set_normal(ref hints);
      this.I.set_wm_hints(this.window, hints);

//~       Xcb.AtomT tmp_atom;
      if(!this.atoms.contains(atom_names.wm_delete_window))
        this.atoms.insert(atom_names.wm_delete_window,
          this.C.intern_atom_reply(this.C.intern_atom(false,atom_names.wm_delete_window)).atom);

      if(!this.atoms.contains(atom_names.wm_take_focus))
        this.atoms.insert(atom_names.wm_take_focus,
          this.C.intern_atom_reply(this.C.intern_atom(false,atom_names.wm_take_focus)).atom);

      if(!this.atoms.contains(atom_names._net_wm_ping))
        this.atoms.insert(atom_names._net_wm_ping,
          this.C.intern_atom_reply(this.C.intern_atom(false,atom_names._net_wm_ping)).atom);

      if(!this.atoms.contains(atom_names._net_wm_sync_request))
        this.atoms.insert(atom_names._net_wm_sync_request,
          this.C.intern_atom_reply(this.C.intern_atom(false,atom_names._net_wm_sync_request)).atom);

      if(!this.atoms.contains(atom_names.wm_protocols))
        this.atoms.insert(atom_names.wm_protocols,
          this.C.intern_atom_reply(this.C.intern_atom(false,atom_names.wm_protocols)).atom);

      Xcb.AtomT[] tmp_atoms={};
      this.atoms.foreach ((key, val) => {
        if(key != atom_names.wm_protocols)
          tmp_atoms += val;
      });

      I.set_wm_protocols(this.window, this.atoms.lookup(atom_names.wm_protocols), tmp_atoms);

      var visual = find_visual(this.C, this.screen.root_visual);
      if (visual == null) {
//~           printf( "Some weird internal error...?!");
    //~       c.disconnect(); ???
          return;
      }


      this.surface = new Cairo.XcbSurface(this.C, this.window, visual, 10, 10);
      this.cr = new Cairo.Context(this.surface);


//~       return base(null);
    }

    private void show_do(){
      this.C.map_window(this.window);
    }//show_do

    public void show(){
      this.state = WindowState.visible;
    }


    private void set_title_do(){
      if(this.title != null){
        this.C.change_property_uint8  ( Xcb.PropMode.REPLACE,
                             this.window,
                             Xcb.Atom.WM_NAME,
                             Xcb.Atom.STRING,
      //~                        8,
                             this.title.length,
                             this.title );
      }
    }//set_title_do

    public void set_title(string title){
      this.title = title;
      if(this.state == WindowState.visible){
        this.set_title_do();
      }
    }//set_title

 /*   private void set_size_do(){

      var size_hints = new Xcb.Icccm.SizeHints();
      size_hints.flags=(Xcb.Icccm.SizeHint.US_SIZE|Xcb.Icccm.SizeHint.P_SIZE|Xcb.Icccm.SizeHint.BASE_SIZE);
      size_hints.height = (int32)this.height;
      size_hints.width  = (int32)this.width;
      size_hints.base_height = 0;
      size_hints.base_width  = 0;
//~       this.I.set_wm_normal_hints(this.window, size_hints);
//~       this.surface.set_size((int)this.width,(int)this.height);
    }*/

    private void configure_window_do(){
      uint32 position[] = { this.pos_x, this.pos_y, this.width, this.height };
      this.C.configure_window(this.window, (Xcb.ConfigWindow.X | Xcb.ConfigWindow.Y | Xcb.ConfigWindow.WIDTH | Xcb.ConfigWindow.HEIGHT), position);
    }

    public void set_size(uint width,uint height){

      this.width=width;
      this.height=height;
//~       this.calculate_size();
//~       this.configure_window_do();
      if(this.state == WindowState.visible){
        uint32 position[] = { this.width, this.height };
        this.C.configure_window(this.window, ( Xcb.ConfigWindow.WIDTH | Xcb.ConfigWindow.HEIGHT), position);
      }
    }

    public void load_font_with_size(string fpatch,uint size){
      var F = FontLoader.load(fpatch);
      this.cr.set_font_face(F);
      this.cr.set_font_size (size);
    }

    public override bool draw(Cairo.Context cr){
      string text="HELLO :) Проверка ЁЙ Русский язык اللغة العربية English language اللغة العربية";
      cr.save();
        cr.set_source_rgb(0, 1, 0);
        cr.paint();

        cr.set_source_rgb(1, 0, 0);
        cr.move_to(0, 0);
        cr.line_to(this.width, 0);
        cr.line_to(this.width, this.height);
        cr.close_path();
        cr.fill();

        cr.set_source_rgb(0, 0, 1);
        cr.set_line_width(20);
        cr.move_to(0, this.height);
        cr.line_to(this.width, 0);
        cr.stroke();
        cr.move_to( 2, this.height-10);
        cr.show_text( text);
        cr.stroke ();
      cr.restore();
//~       GLib.stderr.printf( "childs draw %d\n",(int)this.childs.length());
      return base.draw(cr);
      surface.flush();
    }//draw

  public void on_configure(Xcb.ConfigureNotifyEvent e){

//~     var geom = this.C.get_geometry_reply(this.C.get_geometry_unchecked(e.window), null);
//~     GLib.stderr.printf( "on_map x,y=%d,%d w,h=%d,%d response_type=%d ew=%d, w=%d\n",
//~                       (int)e.x,
//~                       (int)e.y,
//~                       (int)e.width,
//~                       (int)e.height,
//~                       (int)e.response_type,
//~                       (int)e.event,
//~                       (int)e.window
//~                       );

    if( (e.width == 1 && e.height == 1) && (this.width != 1 && this.height != 1))
      return;//skip first map

    this.pos_x = e.x;
    this.pos_y = e.y;
    if(this.width != e.width || this.height != e.height){
      this.width  = e.width;
      this.height = e.height;
      this.calculate_size();
    }

    this.surface.set_size((int)this.width,(int)this.height);

//~     GLib.stderr.printf( "on_map x,y=%d,%d w,h=%d,%d\n",(int)this.x,(int)this.y,(int)this.width,(int)this.height);

  }

  public void run(){
    Xcb.GenericEvent event;
    bool finished = false;
    Xcb.AtomT deleteWindowAtom = this.atoms.lookup(atom_names.wm_delete_window);
//~     GLib.stderr.printf( "event");
    while (( (event = this.C.wait_for_event()) != null ) && !finished ) {
//~       GLib.stderr.printf( "event=%d expose=%d map=%d\n",(int)event.response_type ,Xcb.EXPOSE,Xcb.CLIENT_MESSAGE);
        switch (event.response_type & ~0x80) {
          case Xcb.EXPOSE:
              /* Avoid extra redraws by checking if this is
               * the last expose event in the sequence
               */
               Xcb.ExposeEvent e = (Xcb.ExposeEvent)event;
              if (e.count != 0)
                  break;

              this.draw(this.cr);
          break;
          case Xcb.CLIENT_MESSAGE:
              Xcb.ClientMessageEvent e = (Xcb.ClientMessageEvent)event;
//~               GLib.stderr.printf( "CLIENT_MESSAGE data32=%d deleteWindowAtom=%d\n", (int)e.data.data32[0],(int)deleteWindowAtom);
              if(e.data.data32[0] == deleteWindowAtom){
  //~                 printf("done\n");
                  finished = true;
              }
          break;
          case Xcb.CONFIGURE_NOTIFY:
              if(event.response_type == Xcb.CONFIGURE_NOTIFY)
                this.on_configure((Xcb.ConfigureNotifyEvent)event);
          break;
        }//switch
//~         free(event);
        this.C.flush();
    }
  }//run

    public override void calculate_size(){
      GLib.stderr.printf( "window calculate_size w=%u h=%u loop=%d\n", this.width,this.height,(int)this._calculating_size);

      if(this._calculating_size)
        return;
      this._calculating_size=true;
      bool force_resize = false;
      uint oldw = this.width;
      uint oldh = this.height;
      GLib.stderr.printf( "1 w=%u h=%u\n", this.width,this.height);
      base.calculate_size();
      GLib.stderr.printf( "2 w=%u h=%u\n", this.width,this.height);

      if(this.height > oldh || this.width > oldw){
        force_resize=true;
      }
      this.height = uint.max(this.height, oldh);
      this.width = uint.max(this.width, oldw);

      if( (this.fill_mask & ContainerFillPolicy.fill_height) >0 && this.childs.length() > 0){
        this.childs.first ().data.height = this.height;
      }

      if( (this.fill_mask & ContainerFillPolicy.fill_width) >0 && this.childs.length() > 0){
        this.childs.first ().data.width = this.width;
      }

      if(force_resize && this.state == WindowState.visible){
        GLib.stderr.printf( "3 w=%u h=%u\n", this.width,this.height);
        this.configure_window_do();
      }

      this._calculating_size=false;
    }//calculate_size

  }//class Window


  /********************************************************************/

  public class Button: Widget{
    public string? label = null;
    public Button(string? label = null){
      base();
      this.label = label;
      this.width = 50;
      this.height = 50;
    }
    public override bool draw(Cairo.Context cr){
      GLib.stderr.printf( "Button draw %s\n",this.get_class().get_name());
      cr.set_source_rgb(0.5, 1, 0.5);
         cr.rectangle (this.x, this.y,this.width/*+border.left+border.right*/, this.height/*+border.top+border.bottom*/);
         cr.fill ();
         if(this.label != null){
          cr.set_source_rgb(1, 1, 0);
          cr.move_to(0,this.height/2);
          cr.show_text(this.label);
          }
         cr.stroke ();
      base.draw(cr);
//~       cr.paint();
      return true;//continue
    }//draw
  }
}//namespace Ltk
