## gtkgl directory

if OS_WIN32
export_symbols = -export-symbols gtkgl.def
no_undefined = -no-undefined

gdkgl = gdkgl-win32.c

install-libtool-import-lib:
	$(INSTALL) .libs/libgtkgl-2.0.dll.a $(DESTDIR)$(libdir)
uninstall-libtool-import-lib:
	-rm $(DESTDIR)$(libdir)/libgtkgl-2.0.dll.a
else

gdkgl = gdkgl.c

install-libtool-import-lib:
uninstall-libtool-import-lib:
endif

if MS_LIB_AVAILABLE
noinst_DATA = gtkgl-2.0.lib

install-ms-lib:
	$(INSTALL) gtkgl-2.0.lib $(DESTDIR)$(libdir)

uninstall-ms-lib:
	-rm $(DESTDIR)$(libdir)/gtkgl-2.0.lib
else
install-ms-lib:
uninstall-ms-lib:
endif

EXTRA_DIST = makefile.mingw makefile.mingw.in gdkgl-win32.c gtkgl.def

AM_CFLAGS = $(GTK_CFLAGS) $(GL_CFLAGS)
INCLUDES= -I$(top_srcdir)

gtkglincludedir = $(includedir)/gtkgl-2.0/gtkgl

lib_LTLIBRARIES= libgtkgl-2.0.la

gtkglinclude_HEADERS= gdkgl.h gtkglarea.h
libgtkgl_2_0_la_SOURCES = $(gdkgl) gtkglarea.c
libgtkgl_2_0_la_LDFLAGS = -version-info $(GTKGL_LIBRARY_VERSION) $(export_symbols) $(no_undefined)
libgtkgl_2_0_la_LIBADD = $(GTK_LIBS) $(GL_LIBS)

gtkgl-2.0.lib: libgtkgl-2.0.la gtkgl.def
	lib -name:libgtkgl-2.0-@LT_CURRENT_MINUS_AGE@.dll -def:gtkgl.def -out:$@

install-data-local: install-ms-lib install-libtool-import-lib

uninstall-local: uninstall-ms-lib uninstall-libtool-import-lib
