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

  public class Window: Container{
    private XcbWindow window;
    private bool _calculating_size = false;
    private string? title = null;
    string text="HELLO :) Проверка ЁЙ Русский язык اللغة العربية English language اللغة العربية";
    private weak Widget? previous_widget_under_mouse = null;
    private weak Widget? focused_widget = null;
    private weak Widget? button_press_widget[25];//man4/mousedrv.4. default value is 3. The maximum number is 24

    public Window(){

      base();
      this.min_width=this.min_height=1;

      this.window = new XcbWindow();
      this.window.size_changed.connect(on_xcb_window_size_change);
      this.window.draw.connect(this.draw);
      //someone can subscribe to this signals
      this.window.on_mouse_move.connect((x,y)=>{this.on_mouse_move(x,y);});
      this.window.on_mouse_enter.connect((x,y)=>{this.on_mouse_enter(x,y);});
      this.window.on_mouse_leave.connect((x,y)=>{this.on_mouse_leave(x,y);});
      //generate on_mouse_enter,on_mouse_leave events for childs
      this.window.on_mouse_move.connect(this._on_mouse_move);
      this.window.on_mouse_enter.connect(this._on_mouse_move);
      this.window.on_mouse_leave.connect(this._on_mouse_move);

      //firstly send to child, so child can cancel event
      this.window.on_key_press.connect((keycode, state) => {
        if(focused_widget!=null){
          focused_widget.on_key_press(keycode, state);
          }
      });
      this.window.on_key_press.connect((keycode, state) => {this.on_key_press(keycode, state);});

      //firstly send to child, so child can cancel event
      this.window.on_key_release.connect((keycode, state) => {
        if(focused_widget!=null){
          this.focused_widget.on_key_release(keycode, state);
          }
      });
      this.window.on_key_release.connect((keycode, state) => {this.on_key_press(keycode, state);});

      //firstly send to child, so child can cancel event
      this.window.on_button_press.connect(_on_button_press_translate_for_child);
      this.window.on_button_press.connect(_on_button_press);

      //firstly send to child, so child can cancel event
      this.window.on_button_release.connect(_on_button_release_translate_for_child);

//~       this.damage.connect((widget,x,y,w,h)=>{});

//~       GLib.Signal.connect_swapped(w,"damage2",(GLib.Callback)this.on_damage222,this);

//~       this.window.on_quit.connect(()=>{
//~         GLib.Signal.stop_emission_by_name(this.window,"on-quit");
//~         ltkdebug("Window window.on_quit");
//~         return false;
//~         });
//~       return base(null);
    }

    ~Window(){
      ltkdebug("~Window");
    }


    public override bool draw(Cairo.Context cr){
      ltkdebug( "window draw w=%u h=%u childs=%u damage=%u", this.min_width,this.min_height,this.childs.count,(uint)this.damaged);
      var _ret = base.draw(cr);//Container
      return _ret;
    }//draw

    private void on_xcb_window_size_change(uint width,uint height){
        this.size_changed_serial++;
        this.calculate_size(ref width,ref height,this);
        this.update_childs_position();
//~         this.damaged=true;
    }

    public void damage_all(Container P){
      foreach(var w in P.childs){
        if(w is Container){
          this.damage_all((Container) w);
        }else
          w.damaged=true;
      }
    }

    public override void calculate_size(ref uint calc_width,ref uint calc_height,Widget calc_initiator){
      ltkdebug( "window calculate_size1 min=%u,%u A=%u,%u  CALC=%u,%u loop=%d", this.min_width,this.min_height,this.A.width,this.A.height,calc_width,calc_height,(int)this._calculating_size);
      this._calculating_size=true;
      uint oldw = uint32.min(this.A.width,calc_width);
      uint oldh = uint32.min(this.A.height,calc_height);
      base.calculate_size(ref calc_width,ref calc_height, calc_initiator);
      ltkdebug( "window calculate_size2 min=%u,%u A=%u,%u  CALC=%u,%u loop=%d", this.min_width,this.min_height,this.A.width,this.A.height,calc_width,calc_height,(int)this._calculating_size);
      if(calc_width != oldw||
         calc_height != oldh){
           this.window.resize_and_remember(calc_width,calc_height);
           this.A.width = calc_width;
           this.A.height = calc_height;
           this.damage_all(this);//redraw whole window
      }
      this._calculating_size=false;
    }


    public void size_request(uint new_width, uint new_height){
      ltkdebug( "window size_request=%u,%u", new_width,new_height);
      if(this.A.width != new_width || this.A.height != new_height){
        this.window.resize(new_width,new_height);
      }
    }

    public void set_title(string title){
      this.window.set_title(title);
    }

    public override void show(){
      base.show();
      this.window.show();
    }

    private weak Widget? find_mouse_child(Container cont, uint x, uint y){
      foreach(Widget w in cont.childs){
//~           ltkdebug( "> %u < %u < %u ,  %u < %u < %u  ",w.A.x,x,(w.A.x+w.A.width), w.A.y,y,(w.A.y + w.A.height) );

        if( ( x > w.A.x  && x < (w.A.x + w.A.width) ) &&
            ( y > w.A.y  && y < (w.A.y + w.A.height) ) ){
          if(w is Container){
            return this.find_mouse_child((Container)w,x,y);
          }else{
            weak Widget tmp = w;
            return tmp;
          }
        }
      }
      return null;
    }//find_mouse_child

    private weak Widget? find_mouse_child_up(Container cont, uint x, uint y){
      Widget? w = this.find_mouse_child(cont,x,y);
      if(w == null && cont.parent != null){
        return this.find_mouse_child_up(cont.parent,x,y);
      }
      weak Widget tmp = w;
      return tmp;
    }//find_mouse_child_up

    private void _on_mouse_move(uint x, uint y){
//~       ltkdebug("window on_mouse_move=%u,%u",x,y);
      if(this.previous_widget_under_mouse == null){
        this.previous_widget_under_mouse = this.find_mouse_child(this,x,y);
         if(this.previous_widget_under_mouse != null){
           Widget w = this.previous_widget_under_mouse;//take owner
           w.on_mouse_enter(x,y);
           return;
         }
      }else{
        Widget w = this.previous_widget_under_mouse;
        if( !( ( x > w.A.x  && x < (w.A.x + w.A.width) ) &&
               ( y > w.A.y  && y < (w.A.y + w.A.height) ) ) ){
                 w.on_mouse_leave(x,y);
                 this.previous_widget_under_mouse = this.find_mouse_child_up(w.parent,x,y);
                 if(this.previous_widget_under_mouse != null){
                   w = this.previous_widget_under_mouse;//take owner
                   w.on_mouse_enter(x,y);
                   return;
                 }
        }
      }
      if(this.previous_widget_under_mouse != null){
        Widget w = this.previous_widget_under_mouse;//take owner
        w.on_mouse_move(x,y);
//~         ltkdebug( "window child under mouse is wh=%u,%u",
//~             this.previous_widget_under_mouse.A.width,
//~             this.previous_widget_under_mouse.A.height);
      }
    }//_on_mouse_move

    public virtual signal void damage(Widget? src,uint x,uint y,uint width,uint height){
      this.window.damage(x,y,width,height);
    }
    /*public virtual bool on_mouse_move(uint x, uint y){return true;}
    public virtual bool on_mouse_enter(uint x, uint y){return true;}
    public virtual bool on_mouse_leave(uint x, uint y){return true;}
    public virtual bool on_key_press(uint keycode, uint state){return true;}
    public virtual bool on_key_release(uint keycode, uint state){return true;}*/
//~     public override signal void on_key_press(uint keycode, uint state){}
//~     public override signal void on_key_release(uint keycode, uint state){}
//~     public override void on_button_press(uint detail,uint x, uint y){

    //set focus for child widget
    private void _on_button_press_translate_for_child(uint button,uint state,uint x, uint y){
        uint tx=x,ty=y;
        if(this.translate_coordinates(ref tx,ref ty)){
          Widget? w = this.find_mouse_child(this,tx,ty);
          ltkdebug("window on_button_press2 %u xy=%u,%u w=%p",button, tx, ty,w);
          if(w != null){
            this.button_press_widget[button % 25] = w;//remember latest widget
            w.on_button_press(button,state, tx, ty);
          }
        }
    }
    private void _on_button_release_translate_for_child(uint button,uint state,uint x, uint y){
        uint tx=x,ty=y;
        this.translate_coordinates(ref tx,ref ty);
        Widget? w = this.button_press_widget[button];//release event could be outside our window, so use remembered widget
        ltkdebug("window on_button_release2 %u xy=%u,%u w=%p",button, x, y,w);
        if(w != null){
          w.on_button_release(button,state, tx, ty);//could be outside window!!!!
          this.button_press_widget[button % 25] = null;//done
        }
    }
    private void _on_button_press(uint button,uint state,uint x, uint y){
        ltkdebug("window on_button_press %u xy=%u,%u",button, x, y);
          Widget? w = this.focused_widget;
          uint tx=x,ty=y;
          if(this.translate_coordinates(ref tx,ref ty)){
            if( w == null ||
               (w != null &&
                !( ( tx > w.A.x  && tx < (w.A.x + w.A.width) ) &&
                   ( ty > w.A.y  && ty < (w.A.y + w.A.height) ) ) )
            ){
                 w = this.find_mouse_child(this,tx,ty);
            }
          }

         if(this.focused_widget != w){
           this.grab_focus(w);
         }
    }//on_button_press
    
    public weak XcbWindow get_xcb_window(){
      return this.window;
    }

    public void grab_focus(Widget? w){
       if(this.focused_widget != null &&
          this.focused_widget is Widget &&
          this.focused_widget != w){
         this.focused_widget.set_focus(false);
         this.focused_widget = null;
       }
       if(w != null && w.set_focus(true)){
         this.focused_widget = w;
       }else{
         this.focused_widget = null;
       }
       ltkdebug("window grab_focus widget=%p",this.focused_widget);
    }

    public bool translate_coordinates(ref uint x, ref uint y){
        var win = this.get_xcb_window();
        uint wx = win.x,
             wy = win.y,
             ww = win.width,
             wh = win.height;
        if( ( ( x > wx  && x < (wx + ww) ) &&
              ( y > wy  && y < (wy + wh) ) ) ){
                 x = x - wx;
                 y = y - wy;
                 ltkdebug("window on_button xy=%u,%u",x,y);
                 return true;
        }
        return false;
    }

  }//class Window

}//namespace Ltk
