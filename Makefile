
LTK_TOP := $(dir $(lastword $(MAKEFILE_LIST)))

LTK_FLAGS = --vapidir $(LTK_TOP)vapi  --pkg gobject-2.0 --pkg posix  --pkg glib-2.0 --pkg gio-2.0 --pkg gio-unix-2.0 --pkg xcb --pkg xcb-icccm --pkg cairo-xcb --pkg  xkbcommon-keysyms --pkg ltkdebug -X -I$(LTK_TOP) -X -lfreetype -X -lxcb-keysyms -X -lxkbcommon
#enable debug
#LTK_FLAGS += -X -DLTK_DEBUG=1

LTK_FILES  = $(LTK_TOP)font_loader.vala\
             $(LTK_TOP)ltkmain.vala \
             $(LTK_TOP)ltkwidget.vala \
             $(LTK_TOP)ltkxcbwindow.vala \
             $(LTK_TOP)ltkcontainer.vala \
             $(LTK_TOP)ltkwindow.vala \
             $(LTK_TOP)ltkbutton.vala \
             $(LTK_TOP)ltkdialog.vala \
             $(LTK_TOP)ltkpopupmenu.vala

