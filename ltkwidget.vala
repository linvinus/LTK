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
  [SimpleType]
  [CCode (has_type_id = false)]
  public enum WindowState{
    unconfigured,
    hidden,
    visible
  }

  //uint32
  [SimpleType]
  //[IntegerType (rank = 9)]
  [CCode (has_type_id = false)]
  public enum SOptions{
    fill_horizontal  =1<<0,
    fill_vertical    =1<<1,
    place_horizontal =1<<2,
    place_vertical   =1<<3,
    visible          =1<<4
  }



//~   [SimpleType]
  [CCode (has_type_id = false)]
  public struct Allocation{
    uint32 x;
    uint32 y;
    uint32 width;
    uint32 height;
    SOptions options;
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
 	public struct WidgetListIter {
    unowned GLib.List<Widget> list;
    public WidgetListIter(GLib.List<Widget> l){
      this.list = l;
    }
		public unowned Widget? next_value () {
      unowned Widget? ret = null;
      if(list != null){
        ret = list.data;
        this.list = list.next;
      }
			return ret;
		}
		public void remove (){
    }
	}

  /********************************************************************/

    private int CompareWidth (Widget? a, Widget? b){
      if(a == null || b == null)
        return 0;
//~       debug("  ### a=%u > b=%u", a.min_width , b.min_width);
      if(a.min_width < b.min_width){
        return 1;
      }else if(a.min_width > b.min_width){
        return -1;
      }else{
        return 0;
      }
    }


  public class  WidgetList {
    private GLib.List<Widget> _childs;
    private GLib.List<unowned Widget> _fixed_width;
    private GLib.List<unowned Widget> _fixed_height;
    private GLib.List<unowned Widget> _variable_width;
    private GLib.List<unowned Widget> _variable_height;
    private uint _count;
    private uint _fixed_width_count;
    private uint _fixed_height_count;

    public uint count{
      get { return _count;}
    }
    public uint fixed_width_count{
      get { return _fixed_width_count;}
    }
    public uint fixed_height_count{
      get {return _fixed_height_count;}
    }
    public uint fixed_width{
      get{
        uint w_sum = 0;
        foreach(var w in this._fixed_width){
          w_sum += w.min_width;
        }
        return w_sum;
      }
    }
    public uint fixed_height{
      get{
        uint h_sum = 0;
        foreach(var w in this._fixed_height){
          h_sum += w.min_height;
        }
        return h_sum;
      }
    }

    public WidgetList(){
      this._count = 0;
      this._fixed_width_count = 0;
      this._fixed_height_count = 0;
      this._childs = new GLib.List<Widget>();
      this._fixed_width = new GLib.List<Widget>();
      this._fixed_height = new GLib.List<Widget>();
      this._variable_width = new GLib.List<Widget>();
      this._variable_height = new GLib.List<Widget>();
    }
    public WidgetListIter iterator (){
      return WidgetListIter(this._childs.first());
    }

    public unowned GLib.List<unowned Widget> variable_width(){
      unowned GLib.List r = this._variable_width.first();
      return r;
    }

    public unowned GLib.List<unowned Widget> variable_height(){
      unowned GLib.List r = this._variable_height.first();
      return r;
    }

    public void remove_all(){
//~       this._fixed_width.remove_all();
//~       this.fixed_height.remove_all();
//~       this.childs.remove_all();
    }
    public void append (owned Widget child){
      this._childs.append(child);
      this._count++;
      var a = new Allocation();
      this.on_size_changed(child,a);
      child.size_changed.connect(this.on_size_changed);
    }
    public void remove (Widget child){
      if( this._fixed_width.find(child) != null){
        this._fixed_width.remove(child);
        this._fixed_width_count--;
      }
      if( this._fixed_height.find(child) != null){
        this._fixed_height.remove(child);
        this._fixed_height_count--;
      }
      this._childs.remove(child);
      this._count--;
    }


    private void on_size_changed(Widget src, Allocation prev){
      if( (src.fill_mask & Ltk.SOptions.fill_horizontal) == 0/*WTF? || src.min_width >= src.A.width*/){
          if(this._fixed_width.find(src) == null){
            this._fixed_width.append(src);
            this._fixed_width_count++;
          }
          if( this._variable_width.find(src) != null){
            this._variable_width.remove(src);
          }
      }else{
          if( this._fixed_width.find(src) != null){
            this._fixed_width.remove(src);
            this._fixed_width_count--;
          }
          if( this._variable_width.find(src) == null){
            this._variable_width.append(src);
          }
      }
      this._variable_width.sort((GLib.CompareFunc<weak Ltk.Widget>)CompareWidth);

      if( (src.fill_mask & Ltk.SOptions.fill_vertical) == 0){
          if(this._fixed_height.find(src) == null){
            this._fixed_height.append(src);
            this._fixed_height_count++;
          }
          if( this._variable_height.find(src) != null){
            this._variable_height.remove(src);
          }

      }else{
          if( this._fixed_height.find(src) != null){
            this._fixed_height.remove(src);
            this._fixed_height_count--;
          }
          if( this._variable_height.find(src) == null){
            this._variable_height.append(src);
          }
      }
      this._variable_height.sort((GLib.CompareFunc<weak Ltk.Widget>)CompareWidth);

    }//on_size_changed

//~     public uint length(){
//~       return this._count;
//~     }
    public unowned List<Widget> find (Widget data){
      return this._childs.find(data);
    }

  }//class WidgetList
  /********************************************************************/

  public abstract class Widget : GLib.Object{
    public weak Container? parent = null;
    public WidgetList childs;
    public bool have_background = true;
    //widget name, used for styling
    private string? _name = null;
    public string name{
      get{
        if(_name != null){
          return _name;
        }else{
          return this.get_class().get_name();
        }
      }
      set{
        _name = value;
      }
      }
    private uint _min_width;
    public uint min_width{
      get{ return  this._min_width;}
      set{
        if(value != this._min_width){
          debug("Widget min_width_old=%u new=%u",(uint)this._min_width,value);
          this._min_width = value;
          if(this.A.width < this._min_width)
            this.damaged = true;
          this.size_changed(this,this.A);
        }
        }
    }
    private uint _min_height;
    public uint min_height{
      get{ return  this._min_height;}
      set{
        if(value != this._min_height){
          this._min_height = value;
          if(this.A.height < this._min_height)
            this.damaged = true;
          this.size_changed(this,this.A);
        }
        }

    }
//~     public uint x;
//~     public uint y;
    public Allocation A;

    private  SOptions  _fill_mask;
    public  SOptions  fill_mask {
      get{
        return ((SOptions)_fill_mask & (SOptions.fill_horizontal | SOptions.fill_vertical));
      }
      set{
        var tmp = value & (SOptions.fill_horizontal | SOptions.fill_vertical) ;
        if(tmp != (_fill_mask & (SOptions.fill_horizontal | SOptions.fill_vertical))){
          var prev  = this.A;
          _fill_mask &= ~(SOptions.fill_horizontal | SOptions.fill_vertical);
          _fill_mask |= tmp;
          this.size_changed(this,prev);
        }
      }
      default = 0;//do not fill
    }

    private  SOptions  _place_policy;
    public  SOptions  place_policy {
      get{
        return ((SOptions)_place_policy & (SOptions.place_horizontal | SOptions.place_vertical));
      }
      set{
        var tmp = value & (SOptions.place_horizontal | SOptions.place_vertical) ;
        if(tmp != (_place_policy & (SOptions.place_horizontal | SOptions.place_vertical))){
          var prev  = this.A;
          _place_policy &= ~(SOptions.place_horizontal | SOptions.place_vertical);
          _place_policy |= tmp;
          this.size_changed(this,prev);
        }
      }
      default = SOptions.place_horizontal;
    }

    public virtual uint get_prefered_width(){
      return this.min_width;
    }
    public virtual uint get_prefered_height(){
      return this.min_height;
    }

    public  bool visible {
      get{
        return ((A.options & SOptions.visible) > 0);
      }
      set{
        var prev  = this.A;
        if( value != ((A.options & SOptions.visible) > 0) ){
          this.A.options |= SOptions.visible;
          this.damaged = true;
        }else if( value == ((A.options & SOptions.visible) > 0) ){
          this.A.options &= ~(SOptions.visible);
          this.damaged = true;
        }
        this.size_changed(this,prev);
      }
      default = true;
    }
    private bool _damaged;
    public bool damaged{
      get {return _damaged;}
      set {
        _damaged = value;
        if(_damaged){
          this.send_damage();
        }
        debug("--- Widget damaged=%u width=%u height=%u childs=%u",(uint)_damaged,this.A.width,this.A.height, this.childs.count);
        }
      default = true;
    }

    public Ltk.ThemeEngine engine;
    public WidgetState state;

    public Widget(Container? parent = null){
      GLib.Object();
      this.childs = new WidgetList();
//~       this.x = this.y = 0;
      if(parent != null)
        this.parent = parent;
      this.engine = new ThemeEngine("");

      this.engine.map.bg[DrawStyle.normal] = {128,128,128,255};
      this.engine.map.br[DrawStyle.normal] = {76,76,76,255};
    }//create

    ~Widget(){
      this.childs.remove_all();
      debug("~Widget");
    }

    public virtual bool draw(Cairo.Context cr){
        this.engine.begin(this.state,this.A.width,this.A.height);
        if(this.damaged){
          if(this.have_background){
            this.engine.draw_box(cr);
          }
          this.engine.translate2box(cr);
//~           this.engine.draw_border(cr,this.A.width, this.A.height, this.A.height / 20.0, 50);
          this.damaged=false;
        }

      return true;//continue
    }//draw

    public virtual void show(){
      this.visible = true;
    }
    public virtual void hide(){
      this.visible = false;
    }
    public weak Window? get_top_window(){
      unowned Container? w = this.parent;
      while( w != null && w.parent !=null){
        w = w.parent;
      }
      if(w is Window){
        return (Window)w;
      }else{
        return null;
      }
    }
    public void send_damage(Widget w = this,uint sx = this.A.x,uint sy = this.A.y,uint swidth = this.A.width,uint sheight = this.A.height){
//~        debug("Widget send_damage");
       var win = get_top_window();
//~        debug("Widget send_damage %u",(uint)win);
       if(win != null){
          win.damage(w,sx,sy,swidth,sheight);
        }
//~       GLib.Signal.emit_by_name(((Widget)this),"damage2",null,this.A.x,this.A.y,this.A.width,this.A.height);
    }

    private bool _focused = false;
    //set input focus
    public virtual bool set_focus(bool focus){

      if(focus && !this._focused){
        this._focused = focus;
        var win = this.get_top_window();
        debug("set_focus=%p",win);
        if(win != null){
          win.grab_focus(this);
        }
      }else
        this._focused = focus;

      return this._focused;
    }//set_focus

    //is widget focused?
    public virtual bool get_focus(){
      return this._focused;
    }//get_focus

    public virtual void allocation_changed(){
    }

    public signal void size_changed(Widget src,Allocation old);//for parents
//~     [Signal (action=true, detailed=true, run=true, no_recurse=true, no_hooks=true)]
//~     [Signal (run="first")]

    [Signal (run="first")]
    public virtual signal void on_mouse_move(uint x, uint y){}
    [Signal (run="first")]
    public virtual signal void on_mouse_enter(uint x, uint y){ this.state |= WidgetState.hover; }
    [Signal (run="first")]
    public virtual signal void on_mouse_leave(uint x, uint y){ this.state &= ~WidgetState.hover; }
    [Signal (run="first")]
    public virtual signal void on_key_press(uint keycode, uint state){}
    [Signal (run="first")]
    public virtual signal void on_key_release(uint keycode, uint state){}
    [Signal (run="first")]
    public virtual signal void on_button_press(uint button, uint state,uint x, uint y){}
    [Signal (run="first")]
    public virtual signal void on_button_release(uint button, uint state,uint x, uint y){}

  }//class Widget
  /********************************************************************/



  /*[SimpleType] must not be simple type*/
  [CCode (has_type_id = false)]
  public struct ColorRGBA{
    public uint8 r;
    public uint8 g;
    public uint8 b;
    public uint8 a;
    /*public ColorRGBA( uint8 r, uint8 g, uint8 b, uint8 a){
      this.r = r;
      this.g = g;
      this.b = b;
      this.a = a;
    }*/
    public void set_source_rgb(Cairo.Context cr){
      cr.set_source_rgb((double)r/255.0,(double)g/255.0,(double)b/255.0);
    }
  }

//~   [SimpleType]
[Compact]
[CCode (has_type_id = false)]
  public class ColorMap{
//~   public struct ColorMap{
    public ColorRGBA bg[5];
    public ColorRGBA fg[5];
    public ColorRGBA br[5];
    public ColorRGBA text[5];
  }

  [SimpleType]
  [CCode (has_type_id = false)]
  public enum WidgetState{
    disabled  = 1<<1,
    hover     = 1<<2,
    focused   = 1<<3,
    activated = 1<<4  /*button pressed,selected menu or check box*/
  }
  [SimpleType]
  [CCode (has_type_id = false)]
  public enum DrawStyle{
    normal   = 0,
    active   = 1,
    hover    = 2,
    focused  = 3,
    disabled = 4
  }
  [SimpleType]
  [CCode (has_type_id = false)]
  public struct Borders{
    double top;
    double bottom;
    double left;
    double right;
  }
  [Compact]
  [CCode (has_type_id = false)]
  public class ThemeEngine{
    public string widget_path;
    public ColorMap map;
//~     public GLib.HashTable<int,Cairo.Pattern> patterns;
    public DrawStyle style;
    public Borders border;
    public Borders border_radius;
    public Borders margin;
    public Borders padding;
    public double width;
    public double height;

    public ThemeEngine(string widget_path){
      this.widget_path = widget_path;
//~       this.patterns = new GLib.HashTable<int,Cairo.Pattern> (int_hash, int_equal);
      this.map = new ColorMap();
    }
//~     public void generate_patterns(){
//~       this.patterns.insert(WidgetState.disabled,new Cairo.Pattern.rgb(map.bg.r, map.bg.g, map.bg.b));
//~     }
//~     public void set_color_map(ColorMap* map){
//~       this.map = *map;
//~     }
    public void begin(WidgetState state,double width,double height){
      this.width = width;
      this.height = height;

      if((state & WidgetState.disabled)>0){
        this.style = DrawStyle.disabled;
      }else if((state & WidgetState.activated)>0){
        this.style = DrawStyle.active;
      }else if((state & WidgetState.hover)>0){
        this.style = DrawStyle.hover;
      }else if((state & WidgetState.focused)>0){
        this.style = DrawStyle.focused;
      }else{
        this.style = DrawStyle.normal;
      }
    }//begin

    public void translate2box(Cairo.Context cr){
       double x = border.left + padding.left;
       double y = border.top + padding.top;
       double w = width
                - (/*border.left +*/ border.right)
                - (padding.left  + padding.right);
       double h = height
                - (/*border.top +*/ border.bottom)
                - (padding.top + padding.bottom);
      cr.rectangle (x, y, w, h);
      cr.clip ();
      cr.translate (x,y);
    }

    public void draw_box(Cairo.Context cr,double corner_radius = 0){
      if(corner_radius == 0){
        cr.save();
        map.bg[this.style].set_source_rgb(cr);
        cr.rectangle (0, 0, width, height);
        cr.fill_preserve ();

        map.br[this.style].set_source_rgb(cr);
        cr.set_line_width(2);
        cr.set_source_rgb(0, 0, 0);
        cr.rectangle (0, 0, width, height);
//~           cr.stroke ();
//~           cr.restore();
        cr.stroke ();
        cr.restore();
      }else{
        double aspect = 1.0;
        double radius = corner_radius / aspect;
        double degrees = Math.PI / 180.0;
        double x = 0;
        double y = 0;
        cr.save();
        cr.translate (border.left,border.top);
        width -= (border.left + border.right);
        height -= (border.top + border.bottom);
        cr.new_sub_path ();
        cr.arc ( x + width - radius, y + radius, radius, -90 * degrees, 0 * degrees);
        cr.arc ( x + width - radius, y + height - radius, radius, 0 * degrees, 90 * degrees);
        cr.arc ( x + radius, y + height - radius, radius, 90 * degrees, 180 * degrees);
        cr.arc ( x + radius, y + radius, radius, 180 * degrees, 270 * degrees);
        cr.close_path ();

        map.bg[this.style].set_source_rgb(cr);
        cr.fill_preserve ();
        map.br[this.style].set_source_rgb(cr);
        cr.set_line_width (border.left);
        cr.stroke ();
        cr.restore();
      }

    }
  }//ThemeEngine


}//namespace Ltk
