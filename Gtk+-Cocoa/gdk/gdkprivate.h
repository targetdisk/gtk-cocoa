/* GDK - The GIMP Drawing Kit
 * Copyright (C) 1995-1997 Peter Mattis, Spencer Kimball and Josh MacDonald
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

/*
 * Modified by the GTK+ Team and others 1997-1999.  See the AUTHORS
 * file for a list of people on the GTK+ Team.  See the ChangeLog
 * files for a list of changes.  These files are distributed with
 * GTK+ at ftp://ftp.gtk.org/pub/gtk/. 
 */

#ifndef __GDK_PRIVATE_H__
#define __GDK_PRIVATE_H__

#include <gdk/gdktypes.h>


#define gdk_window_lookup(xid)	   ((GdkWindow*) gdk_xid_table_lookup (xid))
#define gdk_pixmap_lookup(xid)	   ((GdkPixmap*) gdk_xid_table_lookup (xid))
#define gdk_font_lookup(xid)	   ((GdkFont*) gdk_xid_table_lookup (xid))


#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

typedef struct _GdkGCPrivate	       GdkGCPrivate;

struct _GdkEventFilter {
  GdkFilterFunc function;
  gpointer data;
};

struct _GdkClientFilter {
  GdkAtom       type;
  GdkFilterFunc function;
  gpointer      data;
};


struct _GdkGCPrivate
{
  GdkGC gc;
  GdkGCValues values;
  GdkRectangle clip_rectangle;
  guint ref_count;
};

typedef enum {
  GDK_DEBUG_MISC          = 1 << 0,
  GDK_DEBUG_EVENTS        = 1 << 1,
  GDK_DEBUG_DND           = 1 << 2,
  GDK_DEBUG_COLOR_CONTEXT = 1 << 3,
  GDK_DEBUG_XIM           = 1 << 4
} GdkDebugFlag;

void gdk_events_init (void);
void gdk_window_init (void);
void gdk_visual_init (void);
void gdk_dnd_init    (void);

void gdk_image_init  (void);
void gdk_image_exit (void);

/* If you pass x = y = -1, it queries the pointer
   to find out where it currently is.
   If you pass x = y = -2, it does anything necessary
   to know that the drag is ending.
*/
void gdk_dnd_display_drag_cursor(gint x,
				 gint y,
				 gboolean drag_ok,
				 gboolean change_made);

extern gint		 gdk_debug_level;
extern gint		 gdk_show_events;
extern gint		 gdk_use_xshm;
extern gint		 gdk_stack_trace;
extern gchar		*gdk_display_name;
extern gint		 gdk_screen;
extern gchar		*gdk_progclass;
extern gint		 gdk_error_code;
extern gint		 gdk_error_warnings;
extern gint              gdk_null_window_warnings;
extern GList            *gdk_default_filters;
extern const int         gdk_nevent_masks;
extern const int         gdk_event_mask_table[];

/* Debugging support */

#ifdef G_ENABLE_DEBUG

#define GDK_NOTE(type,action)		     G_STMT_START { \
    if (gdk_debug_flags & GDK_DEBUG_##type)		    \
       { action; };			     } G_STMT_END

#else /* !G_ENABLE_DEBUG */

#define GDK_NOTE(type,action)
      
#endif /* G_ENABLE_DEBUG */


gboolean _gdk_font_wc_to_glyphs (GdkFont         *font,
				 const GdkWChar  *text,
				 gint             text_length,
				 gchar          **result,
				 gint            *result_length);
gchar *_gdk_wcstombs_len      (const GdkWChar  *src,
			       int              length);

#ifdef __cplusplus
}
#endif /* __cplusplus */


#endif /* __GDK_PRIVATE_H__ */
