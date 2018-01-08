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
  public class Container: Widget{
    private bool _calculating_size = false;
    public uint size_changed_serial = 0;//public for window class
    private uint size_update_width_serial = 0;
    private uint size_update_height_serial = 0;
    private uint size_update_childs = 0;
    private uint8 color=28;
    public Container(){
      base();
      this.fill_mask = Ltk.SOptions.fill_vertical | Ltk.SOptions.fill_horizontal;
    }

    private void on_child_size_changed(Widget src, Allocation prev){

        if(this._calculating_size)  return;
        this.size_changed_serial++;

        int diff_width = ((int)src.min_width - (int)src.A.width);
        int diff_height = ((int)src.min_height - (int)src.A.height);

        //important, set default size for fixed widget
        if( (src.fill_mask & Ltk.SOptions.fill_horizontal) == 0){
          src.A.width = src.min_width;
        }
        if( (src.fill_mask & Ltk.SOptions.fill_vertical) == 0){
          src.A.height = src.min_height;
        }

        debug("diff_width=%d diff_height=%d",diff_width,diff_height);

        if(diff_height != 0 || diff_width != 0){
            this.update_childs_sizes();
        }
    }

    public void add(Widget child){
      if(this.childs.find(child) == null && child.parent == null){
        child.parent = this;
        this.childs.append(child);
        this.on_child_size_changed(child,child.A);
        child.size_changed.connect(this.on_child_size_changed);
        this.update_childs_sizes();
      }
    }//add

    public void remove(Widget child){
      if(this.childs.find(child) != null){
        this.childs.remove(child);
        child.parent = null;
        this.size_changed_serial++;
        this.update_childs_sizes();
      }
    }//remove

    private void update_childs_sizes(){
      uint oldw = this.A.width;
      uint oldh = this.A.height;
      this.calculate_size(ref oldw,ref oldh,this);
      this.update_childs_position();
    }//update_childs_sizes

    public void update_childs_position(){
      debug("@@@ update_childs_position xy=%u,%u count=%u",this.A.x,this.A.y, this.childs.count);

      //calculate position
      uint _x = this.A.x, _y = this.A.y, _w = 0, _h = 0;

      foreach(var w in this.childs){
            bool do_damage=false;
            if(this.place_policy == SOptions.place_horizontal){
              _y = this.A.y + ((this.A.height-w.A.height)/2);
              if( _x != w.A.x || _y != w.A.y || this.damaged){//redraw all childs if container was damaged
                do_damage=true;
              }
              w.A.x = _x;
              w.A.y = _y;
              if(w.damaged && w is Ltk.Container){
                ((Ltk.Container)w).update_childs_position();
              }
              _x+=w.A.width;
            }else{
              _x = this.A.x + (this.A.width - w.A.width)/2;
              if( _x != w.A.x || _y != w.A.y || this.damaged){//redraw all childs if container was damaged
                do_damage=true;
              }
              w.A.x = _x;
              w.A.y = _y;
              if(w.damaged && w is Ltk.Container){
                ((Ltk.Container)w).update_childs_position();
              }
              _y+=w.A.height;
            }
            if(do_damage && !(w is Ltk.Container)){
              w.damaged=true;
              if(w.parent != null){
                var P = w.parent;
                uint Px = ( P.place_policy == SOptions.place_horizontal ? w.A.x    : P.A.x ),
                     Py = ( P.place_policy == SOptions.place_horizontal ? P.A.y : w.A.y ),
                     Pw = ( P.place_policy == SOptions.place_horizontal ? w.A.width     : P.A.width ),
                     Ph = ( P.place_policy == SOptions.place_horizontal ? P.A.height : w.A.height   );
                    P.send_damage(P,Px,Py,Pw,Ph);
                 }

            }
      }
    }//update_childs_position


    public override uint get_prefered_width(){
      int h = -1;
      uint wmin,wmax;
      this.get_width_for_height(h,out wmin,out wmax);
      this.min_width = (this.place_policy == SOptions.place_horizontal? wmax : wmin);
      return this.min_width;
    }//get_prefered_width

    public override uint get_prefered_height(){
      int w = -1;
      uint hmin,hmax;
      this.get_height_for_width(w,out hmin,out hmax);
      this.min_height = (this.place_policy == SOptions.place_vertical? hmax : hmin);
      return this.min_height;
    }//get_prefered_height

    public virtual void get_height_for_width(int width,out uint height_min,out uint height_max){
      uint _h;
      if(this.size_update_height_serial != this.size_changed_serial){
        foreach(var w in this.childs){
          _h = w.get_prefered_height();
          height_min = uint.max(height_min, _h);
          height_max = (this.place_policy == SOptions.place_vertical ? height_max + _h : height_min);
          debug( "get_height_for_width1 min=%u max=%u %s",_h,height_max, ( (w is Button ) ? "label="+((Button)w).label: "") );
        }
        this.size_update_height_serial = this.size_changed_serial;
      }else{
        height_min = this.min_height;
        height_max = height_min;//uint.max(this.A.height,height_min);
        debug( "get_height_for_width2 min=%u max=%u ",height_min,height_max );
      }
    }//get_height_for_width

    public virtual void get_width_for_height(int height,out uint width_min,out uint width_max){
      uint _w;
      if(this.size_update_width_serial != this.size_changed_serial){
        foreach(var w in this.childs){
          _w = w.get_prefered_width();
          width_min = uint.max( width_min, _w );
          width_max = (this.place_policy == SOptions.place_horizontal ? width_max + _w : width_min);
          debug( "get_width_for_height1 min=%u max=%u %s",_w,width_max, ( (w is Button ) ? "label="+((Button)w).label: "") );
        }
        this.size_update_width_serial = this.size_changed_serial;
      }else{
        width_min = this.min_width;
        width_max = width_min;//uint.max(this.A.width,width_min);
      }
      debug( "get_width_for_height2 min=%u max=%u",width_min,width_max);
    }//get_width_for_height

    public virtual void calculate_size(ref uint calc_width,ref uint calc_height, Widget calc_initiator){
      debug( "container calculate_size min=%u,%u A=%u,%u  CALC=%u,%u loop=%d childs=%u", this.min_width,this.min_height,this.A.width,this.A.height,calc_width,calc_height,(int)this._calculating_size,this.childs.count);

      if(this._calculating_size)
        return;


      this.get_prefered_width();
      this.get_prefered_height();

      if( (this.size_changed_serial == this.size_update_childs && calc_initiator == this) &&
         this.A.width >= this.min_width &&
         this.A.height >= this.min_height ){
            this._calculating_size=false;
            debug( "container quick end. calculate_size w=%u h=%u loop=%d childs=%u", this.min_width,this.min_height,(int)this._calculating_size,this.childs.count);
            return;
      }
      this._calculating_size=true;

      this.size_update_childs = this.size_changed_serial;

        debug( "container this.fill_mask=%d",this.fill_mask );
        debug( "container calc_width=%u wmax=%u",calc_width , this.min_width );
        debug( "container calc_height=%u hmax=%u",calc_height , this.min_height );

        //just to be shure
        if(calc_width < this.min_width)  { calc_width  = this.min_width; }
        if(calc_height < this.min_height){ calc_height = this.min_height;}

          if( calc_width != this.A.width || calc_height != this.A.height ){
            this.damaged=true;
          }
          debug("container damaged=%u calc=%u,%u A=%u,%u",(uint)this.damaged,calc_width,calc_height,this.A.width,this.A.height);

          this.A.width = calc_width;//apply new allocation
          this.A.height = calc_height;

        if(this.place_policy == Ltk.SOptions.place_horizontal){
          debug("container SOptions.place_horizontal min=%u,%u A=%u,%u",this.min_width,this.min_height,this.A.width,this.A.height);
          //set sizes for childs

          uint extra_width_delta = this.A.width;

          debug("container childs.length=%u ",this.childs.count);

          if(extra_width_delta > this.min_width){
            extra_width_delta -= this.childs.fixed_width;
            if(this.childs.count > this.childs.fixed_width_count){
              extra_width_delta = extra_width_delta/(this.childs.count-this.childs.fixed_width_count);
            }
          }else{
            extra_width_delta = 0;
          }

          debug("container w=%u extra_width_delta=%u",this.A.width, extra_width_delta);

          //_variable_width is sorted,first bigger then smaller
          foreach(var w in this.childs.variable_width()){

  //~           w.A.x = 0;
  //~           w.A.y = 0;
            uint new_width = 0;
            uint new_height = 0;

            if( (w.fill_mask & Ltk.SOptions.fill_horizontal) > 0 ){
              if( extra_width_delta >= w.min_width){
                new_width = extra_width_delta;
              }else{
                new_width = w.min_width;
                //100 | 100
                //x   | 150
                if(extra_width_delta > 0){
                  uint dela_minus = (w.min_width-extra_width_delta);
                  if(extra_width_delta > dela_minus){
                    extra_width_delta -= dela_minus;
                  }else{
                    extra_width_delta = 0;//hmm, something wrong
                  }
                }
              }
            }else{
                new_width = w.min_width;
            }
            if((w.fill_mask & Ltk.SOptions.fill_vertical) > 0){
              new_height = this.A.height;
            }else{
              new_height = w.min_height;
            }
            debug("container A w=%u h=%u",new_width,new_height);
            if( new_width != w.A.width || new_height != w.A.height ){
              w.damaged=true;
            }

            if(w is Ltk.Container){
              ((Ltk.Container)w).calculate_size(ref new_width,ref new_height, this);
            }else{
              w.A.width = new_width;
              w.A.height = new_height;
              w.allocation_changed();
            }

            w.A.options ^= w.A.options;
            w.A.options |= w.place_policy;
            w.A.options |= w.fill_mask;

          }//foreach childs
        }else{//SOptions.place_vertical
          debug("container SOptions.place_vertical min=%u,%u A=%u,%u",this.min_width,this.min_height,this.A.width,this.A.height);
          //set sizes for childs
          uint extra_height_delta = this.A.height;

          debug("container childs.length=%u ",this.childs.count);

          if(extra_height_delta > this.min_height){
            extra_height_delta -= this.childs.fixed_height;
            if(this.childs.count > this.childs.fixed_height_count){
              extra_height_delta = extra_height_delta/(this.childs.count-this.childs.fixed_height_count);
            }
          }else{
            extra_height_delta = 0;
          }

          debug("container h=%u extra_height_delta=%u",this.A.height, extra_height_delta);


          //_variable_height is sorted,first bigger then smaller
          foreach(var w in this.childs.variable_height()){

  //~           w.A.x = 0;
  //~           w.A.y = 0;
            uint new_width = 0;
            uint new_height = 0;

            if( (w.fill_mask & Ltk.SOptions.fill_vertical) > 0 ){
              if( extra_height_delta >= w.min_height){
                new_height = extra_height_delta;
              }else{
                new_height = w.min_height;
                //100 | 100
                //x   | 150
                if(extra_height_delta > 0){
                  uint dela_minus = (w.min_height-extra_height_delta);
                  if(extra_height_delta > dela_minus){
                    extra_height_delta -= dela_minus;
                  }else{
                    extra_height_delta = 0;//hmm, something wrong
                  }
                }
              }
            }else{
                new_height = w.min_height;
            }

            if((w.fill_mask & Ltk.SOptions.fill_horizontal) > 0){
              new_width = this.A.width;
            }else{
              new_width = w.get_prefered_width();
            }

            debug("container A w=%u h=%u",w.A.width,w.A.height);

            if( new_width != w.A.width || new_height != w.A.height ){
              w.damaged=true;
            }

            if(w is Ltk.Container){
              ((Ltk.Container)w).calculate_size(ref new_width,ref new_height, this);
            }else{
              w.A.width = new_width;
              w.A.height = new_height;
              w.allocation_changed();
            }
            w.A.options ^= w.A.options;
            w.A.options |= w.place_policy;
            w.A.options |= w.fill_mask;
          }//foreach childs
        }//SOptions.place_vertical
      debug( "container end calculate_size w=%u h=%u loop=%d childs=%u damage=%u", this.min_width,this.min_height,(int)this._calculating_size,this.childs.count,(uint)this.damaged);
      this._calculating_size=false;
    }//calculate_size

    public override bool draw(Cairo.Context cr){
        var _ret = base.draw(cr);//widget
        debug( "container x,y=%u,%u w,h=%u,%u childs=%u",this.A.x, this.A.y, this.A.width, this.A.height, this.childs.count);

        double dx=0,dy=0;

        foreach(var w in this.childs){
          cr.save();

            if(w.damaged || w is Ltk.Container){//always propagate draw for container childs
              if(!(w is Ltk.Container)){//container will draw it own background
                uint _x = ( this.place_policy == SOptions.place_horizontal ? w.A.x    : this.A.x ),
                     _y = ( this.place_policy == SOptions.place_horizontal ? this.A.y : w.A.y ),
                     _w = ( this.place_policy == SOptions.place_horizontal ? w.A.width     : this.A.width ),
                     _h = ( this.place_policy == SOptions.place_horizontal ? this.A.height : w.A.height   );
                    dx = _x;
                    dy = _y;
                    cr.device_to_user(ref dx,ref dy);
                    cr.translate (dx, dy);
                    this.engine.begin(this.state,_w,_h);//repaint container background under widget, recover background if widget become smaller
                    this.engine.draw_box(cr);
                    //this.send_damage(this,_x,_y,_w,_h); don't send damage from draw
              }

              dx=w.A.x;
              dy=w.A.y;
              cr.device_to_user(ref dx,ref dy);
//~               debug( "+++ childs draw %d [%f,%f]",(int)w.A.width,dx,dy);
              cr.translate (dx, dy);
              cr.rectangle (0, 0, w.A.width , w.A.height );
              cr.clip ();
              w.draw(cr);
            }

//~             cr.pop_group ();
          cr.restore();
          }//foreach
        return _ret;
      }//draw

  }//class container

}//namespace Ltk
