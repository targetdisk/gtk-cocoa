/* GTK - The GIMP Toolkit
 * Copyright (C) 1995-1997 Peter Mattis, Spencer Kimball and Josh MacDonald
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
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

#ifndef __GTK_TEXT_H__
#define __GTK_TEXT_H__


#include <gdk/gdk.h>
#include <gtk/gtkadjustment.h>
#include <gtk/gtkeditable.h>

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */


#define GTK_TYPE_TEXT                  (gtk_text_get_type ())
#define GTK_TEXT(obj)                  (GTK_CHECK_CAST ((obj), GTK_TYPE_TEXT, GtkText))
#define GTK_TEXT_CLASS(klass)          (GTK_CHECK_CLASS_CAST ((klass), GTK_TYPE_TEXT, GtkTextClass))
#define GTK_IS_TEXT(obj)               (GTK_CHECK_TYPE ((obj), GTK_TYPE_TEXT))
#define GTK_IS_TEXT_CLASS(klass)       (GTK_CHECK_CLASS_TYPE ((klass), GTK_TYPE_TEXT))

typedef struct _GtkTextFont       GtkTextFont;
typedef struct _GtkPropertyMark   GtkPropertyMark;
typedef struct _GtkText           GtkText;
typedef struct _GtkTextClass      GtkTextClass;

struct _GtkPropertyMark
{
  /* Position in list. */
  GList* property;

  /* Offset into that property. */
  guint offset;

  /* Current index. */
  guint index;
};

struct _GtkText
{
  GtkEditable editable;

  GdkWindow *text_area;

  GtkAdjustment *hadj;
  GtkAdjustment *vadj;

  GdkGC *gc;

  GdkPixmap* line_wrap_bitmap;
  GdkPixmap* line_arrow_bitmap;

		      /* GAPPED TEXT SEGMENT */

  /* The text, a single segment of text a'la emacs, with a gap
   * where insertion occurs. */
  union { GdkWChar *wc; guchar  *ch; } text;
  /* The allocated length of the text segment. */
  guint text_len;
  /* The gap position, index into address where a char
   * should be inserted. */
  guint gap_position;
  /* The gap size, s.t. *(text + gap_position + gap_size) is
   * the first valid character following the gap. */
  guint gap_size;
  /* The last character position, index into address where a
   * character should be appeneded.  Thus, text_end - gap_size
   * is the length of the actual data. */
  guint text_end;
			/* LINE START CACHE */

  /* A cache of line-start information.  Data is a LineParam*. */
  GList *line_start_cache;
  /* Index to the start of the first visible line. */
  guint first_line_start_index;
  /* The number of pixels cut off of the top line. */
  guint first_cut_pixels;
  /* First visible horizontal pixel. */
  guint first_onscreen_hor_pixel;
  /* First visible vertical pixel. */
  guint first_onscreen_ver_pixel;

			     /* FLAGS */

  /* True iff this buffer is wrapping lines, otherwise it is using a
   * horizontal scrollbar. */
  guint line_wrap : 1;
  guint word_wrap : 1;
 /* If a fontset is supplied for the widget, use_wchar become true,
   * and we use GdkWchar as the encoding of text. */
  guint use_wchar : 1;

  /* Frozen, don't do updates. @@@ fixme */
  guint freeze_count;
			/* TEXT PROPERTIES */

  /* A doubly-linked-list containing TextProperty objects. */
  GList *text_properties;
  /* The end of this list. */
  GList *text_properties_end;
  /* The first node before or on the point along with its offset to
   * the point and the buffer's current point.  This is the only
   * PropertyMark whose index is guaranteed to remain correct
   * following a buffer insertion or deletion. */
  GtkPropertyMark point;

			  /* SCRATCH AREA */

  union { GdkWChar *wc; guchar *ch; } scratch_buffer;
  guint   scratch_buffer_len;

			   /* SCROLLING */

  gint last_ver_value;

			     /* CURSOR */

  gint            cursor_pos_x;       /* Position of cursor. */
  gint            cursor_pos_y;       /* Baseline of line cursor is drawn on. */
  GtkPropertyMark cursor_mark;        /* Where it is in the buffer. */
  GdkWChar        cursor_char;        /* Character to redraw. */
  gchar           cursor_char_offset; /* Distance from baseline of the font. */
  gint            cursor_virtual_x;   /* Where it would be if it could be. */
  gint            cursor_drawn_level; /* How many people have undrawn. */

			  /* Current Line */

  GList *current_line;

			   /* Tab Stops */

  GList *tab_stops;
  gint default_tab_width;

  GtkTextFont *current_font;	/* Text font for current style */

  /* Timer used for auto-scrolling off ends */
  gint timer;
  
  guint button;			/* currently pressed mouse button */
  GdkGC *bg_gc;			/* gc for drawing background pixmap */
};

struct _GtkTextClass
{
  GtkEditableClass parent_class;

  void  (*set_scroll_adjustments)   (GtkText	    *text,
				     GtkAdjustment  *hadjustment,
				     GtkAdjustment  *vadjustment);
};


GtkType    gtk_text_get_type        (void);
GtkWidget* gtk_text_new             (GtkAdjustment *hadj,
				     GtkAdjustment *vadj);
void       gtk_text_set_editable    (GtkText       *text,
				     gboolean       editable);
void       gtk_text_set_word_wrap   (GtkText       *text,
				     gint           word_wrap);
void       gtk_text_set_line_wrap   (GtkText       *text,
				     gint           line_wrap);
void       gtk_text_set_adjustments (GtkText       *text,
				     GtkAdjustment *hadj,
				     GtkAdjustment *vadj);
void       gtk_text_set_point       (GtkText       *text,
				     guint          index);
guint      gtk_text_get_point       (GtkText       *text);
guint      gtk_text_get_length      (GtkText       *text);
void       gtk_text_freeze          (GtkText       *text);
void       gtk_text_thaw            (GtkText       *text);
void       gtk_text_insert          (GtkText       *text,
				     GdkFont       *font,
				     GdkColor      *fore,
				     GdkColor      *back,
				     const char    *chars,
				     gint           length);
gint       gtk_text_backward_delete (GtkText       *text,
				     guint          nchars);
gint       gtk_text_forward_delete  (GtkText       *text,
				     guint          nchars);
gint
			gtk_text_font_height(GtkText *text);

#define GTK_TEXT_INDEX(t, index)	(((t)->use_wchar) \
	? ((index) < (t)->gap_position ? (t)->text.wc[index] : \
					(t)->text.wc[(index)+(t)->gap_size]) \
	: ((index) < (t)->gap_position ? (t)->text.ch[index] : \
					(t)->text.ch[(index)+(t)->gap_size]))

#ifdef __cplusplus
}
#endif /* __cplusplus */


#endif /* __GTK_TEXT_H__ */
