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
	
  public class Button: Widget{
    public string? label = null;
    private uint8 color=128;

    public Button(string? label = null){
      base();
      this.label = label;
      this.min_width = 50;
      this.min_height = 50;
      engine.map.bg[DrawStyle.normal] = {0,128,0,255};

      engine.map.bg[DrawStyle.focused] = {0,229,0,255};
      engine.map.br[DrawStyle.focused] = {128,0,0,255};

      engine.map.bg[DrawStyle.active] = {128,0,229,255};
      engine.map.br[DrawStyle.active] = {128,0,0,255};

      engine.map.bg[DrawStyle.hover] = {0,128,0,255};
      engine.map.br[DrawStyle.hover] = {128,0,128,255};

      engine.border.left = 3;
      engine.border.right = 3;
      engine.border.top = 3;
      engine.border.bottom = 3;

      engine.padding.top = 0;
      engine.padding.bottom = 0;
      engine.padding.left = 0;
      engine.padding.right = 0;
    }
    public override bool draw(Cairo.Context cr){
      debug( "Button draw %s",this.get_class().get_name());
        this.engine.begin(this.state,this.A.width,this.A.height);
        if(this.damaged){
         this.engine.draw_box(cr,this.engine.height / 10.0);
         this.engine.translate2box(cr);//main part where we can draw

         cr.translate (0,(double)(this.A.height/2));
         if(this.label != null){
          cr.set_font_size (14.0);
          engine.map.text[this.engine.style].set_source_rgb(cr);
          cr.show_text(this.label);
          }
         cr.stroke ();
         this.damaged=false;
      }
      this.color+=50;
//~       engine.map.bg[this.engine.style].g = (double)this.color/255.0;
//~       cr.paint();
      return true;//continue
    }//draw
    public override void on_button_press(uint button,uint x, uint y){
      this.state |= WidgetState.activated;
      this.damaged = true;//redraw button with new state
    }
    public override void on_button_release(uint button,uint x, uint y){
      this.state &= ~WidgetState.activated;
      this.damaged = true;//redraw button with new state
      this.on_click();
    }

    public override void on_mouse_enter(uint x, uint y){
      base.on_mouse_enter(x,y);
      this.damaged = true;//redraw button with new state
    }

    public override void on_mouse_leave(uint x, uint y){
      base.on_mouse_leave(x,y);
      this.damaged = true;//redraw button with new state
    }
    //set input focus
    public override bool set_focus(bool focus){
      if(!focus && (this.state & WidgetState.focused) >0 ){
        this.state  &= ~WidgetState.focused;
        this.damaged = true;
      }else if(focus && (this.state & WidgetState.focused) == 0 ){
        this.state  |= WidgetState.focused;
        this.damaged = true;
      }
      return base.set_focus(focus);
    }//set_focus

    public signal void on_click();
  }//class Button

}//namespace Ltk
