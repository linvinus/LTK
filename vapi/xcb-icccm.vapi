/* xcb-icccm.vapi
 *
 * Copyright (C) 2013  Sergio Costas
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 *  Sergio Costas <raster@rastersoft.com>
 */

using Xcb;

[Deprecated (since = "vala-0.26", replacement = "bindings distributed with vala-extra-vapis")]
namespace Xcb {



	[CCode (lower_case_cprefix = "xcb_icccm_", cheader_filename = "xcb/xcb_icccm.h")]
	namespace Icccm {

    [CCode ( cname = "int", has_type_id = false)]
    public enum SizeHint{
      US_POSITION,
      US_SIZE,
      P_POSITION,
      P_SIZE,
      P_MIN_SIZE,
      P_MAX_SIZE,
      P_RESIZE_INC,
      P_ASPECT,
      BASE_SIZE,
      P_WIN_GRAVITY;
      }

//~     [compact]
//~     [CCode (cname = "xcb_size_hints_t", ref_function = "", unref_function = "free")]
//~     public class SizeHints {
//~       [CCode (has_construct_function = false)]
//~       public SizeHints();
	//[SimpleType]
	[CCode (cname = "xcb_size_hints_t",has_destroy_function = false, has_type_id = false)]
	public struct SizeHints {
      public uint32 @flags;
      public int32 x;
      public int32 y;
      public int32 width;
      public int32 height;
      public int32 min_width;
      public int32 min_height;
      public int32 max_width;
      public int32 max_height;
      public int32 width_inc;
      public int32 height_inc;
      public int32 min_aspect_num;
      public int32 min_aspect_den;
      public int32 max_aspect_num;
      public int32 max_aspect_den;
      public int32 base_width;
      public int32 base_height;
      public uint32 win_gravity;
    }


/* WM_HINTS */

/**
 * @brief WM hints structure (may be extended in the future).
 */
	[CCode (cname = "xcb_icccm_wm_hints_t",has_destroy_function = false, has_type_id = false)]
	public struct WmHints {
    /** Marks which fields in this structure are defined */
      int32 @flags;
    /** Does this application rely on the window manager to get keyboard
        input? */
      uint32 input;
      /** See below */
      int32 initial_state;
      /** Pixmap to be used as icon */
      Xcb.Pixmap icon_pixmap;
      /** Window to be used as icon */
      Xcb.Window icon_window;
      /** Initial position of icon */
      int32 icon_x;
      int32 icon_y;
      /** Icon mask bitmap */
      Xcb.Pixmap icon_mask;
      /* Identifier of related window group */
      Xcb.Window window_group;
    }

/** Number of elements in this structure */
//~ #define XCB_ICCCM_NUM_WM_HINTS_ELEMENTS 9

/**
 * @brief WM_HINTS window states.
 */
    [CCode ( cname = "int", has_type_id = false)]
    public enum WmState{
      WITHDRAWN,
      NORMAL,
      ICONIC;
    }

    [CCode ( cname = "int", has_type_id = false)]
    public enum WmHint{
      INPUT,
      STATE,
      ICON_PIXMAP,
      ICON_WINDOW,
      ICON_POSITION,
      ICON_MASK,
      WINDOW_GROUP,
      X_URGENCY;
    }

		/**
		 * A factory method that creates an Icccm object. It allows to call the Xcb Icccm methods
		 * @param conn The current Xcb connection
		 * @return the new Icccm object
		 */
		public static unowned Icccm new(Xcb.Connection conn) {
			unowned Xcb.Icccm.Icccm retval = (Xcb.Icccm.Icccm)conn;
			return retval;
		}

		// The Icccm class is, in fact, a Xcb.Connection class in disguise
		[Compact, CCode (cname = "xcb_connection_t", cprefix = "xcb_icccm_", unref_function = "")]
		public class Icccm : Xcb.Connection {
			public GetPropertyCookie get_wm_class(Window window);
			public GetPropertyCookie get_wm_class_unchecked(Window window);
			public GetPropertyCookie get_wm_client_machine(Window window);
			public GetPropertyCookie set_wm_client_machine(Window window,AtomT encoding,uint8 format, uint32 name_len,string name);
			public void get_wm_client_machine_reply(GetPropertyCookie cookie,out string s,out GenericError? e = null);
			public GetPropertyCookie set_wm_normal_hints(Window window, SizeHints hints);
			public GetPropertyCookie set_wm_hints(Window window, WmHints hints);
			public GetPropertyCookie set_wm_protocols(Window window,
                                             AtomT wm_protocols,
                                             [CCode (array_length_pos = 2.9, array_length_type = "uint32_t")] AtomT[] atoms);
		}

		[SimpleType]
		[CCode (cname = "xcb_icccm_get_wm_class_reply_t", has_type_id = false)]
		public struct GetWmClassFromReply {
			unowned string instance_name;
			unowned string class_name;
		}

		public void get_wm_class_from_reply(out GetWmClassFromReply reply, GetPropertyReply input);
		public void get_wm_size_hints_from_reply(out SizeHints reply, GetPropertyReply input);

		public void wm_hints_set_normal(ref WmHints hints);
	}
}
