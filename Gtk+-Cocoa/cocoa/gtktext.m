//
//  gtktext.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Dec 29 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//
#import <AppKit/AppKit.h>
#import "NSGtkText.h"

#include "gdk/gdkkeysyms.h"
#include "gdk/gdki18n.h"
#include <gtk/gtk.h>

#define INITIAL_BUFFER_SIZE      1024
#define INITIAL_LINE_CACHE_SIZE  256
#define MIN_GAP_SIZE             256
#define LINE_DELIM               '\n'
#define MIN_TEXT_WIDTH_LINES     20
#define MIN_TEXT_HEIGHT_LINES    10
#define TEXT_BORDER_ROOM         1
#define LINE_WRAP_ROOM           8           /* The bitmaps are 6 wide. */
#define DEFAULT_TAB_STOP_WIDTH   4
#define SCROLL_PIXELS            5
#define KEY_SCROLL_PIXELS        10
#define SCROLL_TIME              100
#define FREEZE_LENGTH            1024        
/* Freeze text when inserting or deleting more than this many characters */

#define SET_PROPERTY_MARK(m, p, o)  do {                   \
                                      (m)->property = (p); \
			              (m)->offset = (o);   \
			            } while (0)
#define MARK_CURRENT_PROPERTY(mark) ((TextProperty*)(mark)->property->data)
#define MARK_NEXT_PROPERTY(mark)    ((TextProperty*)(mark)->property->next->data)
#define MARK_PREV_PROPERTY(mark)    ((TextProperty*)((mark)->property->prev ?     \
						     (mark)->property->prev->data \
						     : NULL))
#define MARK_PREV_LIST_PTR(mark)    ((mark)->property->prev)
#define MARK_LIST_PTR(mark)         ((mark)->property)
#define MARK_NEXT_LIST_PTR(mark)    ((mark)->property->next)
#define MARK_OFFSET(mark)           ((mark)->offset)
#define MARK_PROPERTY_LENGTH(mark)  (MARK_CURRENT_PROPERTY(mark)->length)


#define MARK_CURRENT_FONT(text, mark) \
  ((MARK_CURRENT_PROPERTY(mark)->flags & PROPERTY_FONT) ? \
         MARK_CURRENT_PROPERTY(mark)->font->gdk_font : \
         GTK_WIDGET (text)->style->font)
#define MARK_CURRENT_FORE(text, mark) \
  ((MARK_CURRENT_PROPERTY(mark)->flags & PROPERTY_FOREGROUND) ? \
         &MARK_CURRENT_PROPERTY(mark)->fore_color : \
         &((GtkWidget *)text)->style->text[((GtkWidget *)text)->state])
#define MARK_CURRENT_BACK(text, mark) \
  ((MARK_CURRENT_PROPERTY(mark)->flags & PROPERTY_BACKGROUND) ? \
         &MARK_CURRENT_PROPERTY(mark)->back_color : \
         &((GtkWidget *)text)->style->base[((GtkWidget *)text)->state])
#define MARK_CURRENT_TEXT_FONT(text, mark) \
  ((MARK_CURRENT_PROPERTY(mark)->flags & PROPERTY_FONT) ? \
         MARK_CURRENT_PROPERTY(mark)->font : \
         text->current_font)

#define TEXT_LENGTH(t)              ((t)->text_end - (t)->gap_size)
#define FONT_HEIGHT(f)              ((f)->ascent + (f)->descent)
#define LINE_HEIGHT(l)              ((l).font_ascent + (l).font_descent)
#define LINE_CONTAINS(l, i)         ((l).start.index <= (i) && (l).end.index >= (i))
#define LINE_STARTS_AT(l, i)        ((l).start.index == (i))
#define LINE_START_PIXEL(l)         ((l).tab_cont.pixel_offset)
#define LAST_INDEX(t, m)            ((m).index == TEXT_LENGTH(t))
#define CACHE_DATA(c)               (*(LineParams*)(c)->data)

typedef struct _TextProperty          TextProperty;
typedef struct _TabStopMark           TabStopMark;
typedef struct _PrevTabCont           PrevTabCont;
typedef struct _FetchLinesData        FetchLinesData;
typedef struct _LineParams            LineParams;
typedef struct _SetVerticalScrollData SetVerticalScrollData;

typedef enum
{
  FetchLinesPixels,
  FetchLinesCount
} FLType;

struct _SetVerticalScrollData {
  gint pixel_height;
  gint last_didnt_wrap;
  gint last_line_start;
  GtkPropertyMark mark;
};

struct _GtkTextFont
{
  /* The actual font. */
  GdkFont *gdk_font;
  guint ref_count;

  gint16 char_widths[256];
};

typedef enum {
  PROPERTY_FONT =       1 << 0,
  PROPERTY_FOREGROUND = 1 << 1,
  PROPERTY_BACKGROUND = 1 << 2
} TextPropertyFlags;

struct _TextProperty
{
  /* Font. */
  GtkTextFont* font;

  /* Background Color. */
  GdkColor back_color;
  
  /* Foreground Color. */
  GdkColor fore_color;

  /* Show which properties are set */
  TextPropertyFlags flags;

  /* Length of this property. */
  guint length;
};

struct _TabStopMark
{
  GList* tab_stops; /* Index into list containing the next tab position.  If
		     * NULL, using default widths. */
  gint to_next_tab;
};

struct _PrevTabCont
{
  guint pixel_offset;
  TabStopMark tab_start;
};

struct _LineParams
{
  guint font_ascent;
  guint font_descent;
  guint pixel_width;
  guint displayable_chars;
  guint wraps : 1;
  
  PrevTabCont tab_cont;
  PrevTabCont tab_cont_next;
  
  GtkPropertyMark start;
  GtkPropertyMark end;
};


extern GMemChunk  *params_mem_chunk    ;
extern GMemChunk  *text_property_chunk ;

void
gtk_text_init (GtkText *text)
{
  NSScrollView *sw;
  NSGtkText *tf;
  GTK_WIDGET_SET_FLAGS (text, GTK_CAN_FOCUS);

  text->text_area = NULL;
  text->hadj = NULL;
  text->vadj = NULL;
  text->gc = NULL;
  text->bg_gc = NULL;
  text->line_wrap_bitmap = NULL;
  text->line_arrow_bitmap = NULL;
  
  text->use_wchar = FALSE;
  text->text.ch = g_new (guchar, INITIAL_BUFFER_SIZE);
  text->text_len = INITIAL_BUFFER_SIZE;
 
  text->scratch_buffer.ch = NULL;
  text->scratch_buffer_len = 0;
 
  text->freeze_count = 0;
  
  if (!params_mem_chunk)
    params_mem_chunk = g_mem_chunk_new ("LineParams",
					sizeof (LineParams),
					256 * sizeof (LineParams),
					G_ALLOC_AND_FREE);
  
  text->default_tab_width = 4;
  text->tab_stops = NULL;
  
  text->tab_stops = g_list_prepend (text->tab_stops, (void*)8);
  text->tab_stops = g_list_prepend (text->tab_stops, (void*)8);
  
  text->line_start_cache = NULL;
  text->first_cut_pixels = 0;
  
  text->line_wrap = TRUE;
  text->word_wrap = FALSE;
  
  text->timer = 0;
  text->button = 0;
  
  text->current_font = NULL;
  
  init_properties (text);
  
  GTK_EDITABLE (text)->editable = FALSE;
  
  gtk_editable_set_position (GTK_EDITABLE (text), 0);

  sw =[[NSScrollView alloc] initWithFrame:NSMakeRect(0,0,100,22)];
  [sw setHasVerticalScroller:YES];
  [sw setBorderType:NSLineBorder];
  tf = [[NSGtkText alloc] initWithFrame:NSMakeRect(0,0,100,22)];
  [sw setDocumentView:tf];
  [GTK_WIDGET(text)->proxy release];
  GTK_WIDGET(text)->proxy = sw;
  [tf setDelegate:tf];
  [tf setEditable:FALSE];
  [tf setHorizontallyResizable:YES];
  [tf setVerticallyResizable:YES];
//  [tf setFont:[NSFont userFixedPitchFontOfSize:0]];
  tf->proxy = text;
  tf->tag = 0;
}

void
gtk_text_insert (GtkText    *text,
		 GdkFont    *font,
		 GdkColor   *fore,
		 GdkColor   *back,
		 const char *chars,
		 gint        nchars)
{
  NSGtkText *t;
  NSTextStorage *textStorage;
  NSString *s;
  NSAttributedString *as;
  int l;
  	
	t = [GTK_WIDGET(text)->proxy documentView];
  
	if(nchars==-1)
		nchars = strlen(chars);
  	gtk_text_insert_gtk (text,  font, fore, back, chars, nchars);
  	if(t->locked) return;
  	l  = TEXT_LENGTH(text);
 	 t->locked = TRUE;
	s = [NSString stringWithCString:chars length:nchars];
	as = [[NSAttributedString alloc] initWithString:s];
  	textStorage = [t textStorage];
	[textStorage beginEditing];
	[textStorage appendAttributedString:as];
	[textStorage endEditing];
	[as release];
//	[s release];
/*
  if(l)
  	[t setString:[NSString stringWithCString:text->text.ch length:l]];
  else
	[t setString:@""];
*/
  t->locked = FALSE;
}

void 
gtk_text_delete_text    (GtkEditable       *editable,
			 gint               start_pos,
			 gint               end_pos)
{
  GtkText *text;
  NSGtkText *t;
  int l;
  
  g_return_if_fail (start_pos >= 0);
  
  text = GTK_TEXT (editable);
  t = [GTK_WIDGET(text)->proxy documentView];
  l  = TEXT_LENGTH(text);
  gtk_text_set_point (text, start_pos);
  if (end_pos < 0)
    end_pos = TEXT_LENGTH (text);
  
  if (end_pos > start_pos)
    gtk_text_forward_delete (text, end_pos - start_pos);
  if(t->locked) return;
  t->locked = TRUE;
  [t setString:@""];
  t->locked = FALSE;
}

void
gtk_text_set_editable (GtkText *text,
		       gboolean is_editable)
{
  NSGtkText *t;
  g_return_if_fail (text != NULL);
  g_return_if_fail (GTK_IS_TEXT (text));

  t = [GTK_WIDGET(text)->proxy documentView];
//  gtk_editable_set_editable (GTK_EDITABLE (text), is_editable);
  [t setEditable:is_editable];
}

int
gtk_text_font_height(GtkText *text)
{
 	NSGtkText *t;
  	g_return_if_fail (text != NULL);

	 t = [GTK_WIDGET(text)->proxy documentView];
	return [[t font] ascender] - [[t font] descender]+2;
}

void
gtk_text_adjustment (GtkAdjustment *adjustment,
		     GtkText       *text)
{
	NSScroller *hs;
	NSScrollView *sw = GTK_WIDGET(text)->proxy;
	float size;

	g_return_if_fail (adjustment != NULL);
	g_return_if_fail (GTK_IS_ADJUSTMENT (adjustment));
	g_return_if_fail (text != NULL);
	g_return_if_fail (GTK_IS_TEXT (text));

	size = [[sw documentView] frame].size.height;
	size -=[sw frame].size.height;
	size = (float)adjustment->value/size;
	hs = [sw verticalScroller];
	[[sw documentView] scrollPoint:NSMakePoint(0,adjustment->value)];
#if 0
  /* Clamp the value here, because we'll get really confused
   * if someone tries to move the adjusment outside of the
   * allowed bounds
   */
  old_val = adjustment->value;

  adjustment->value = MIN (adjustment->value, adjustment->upper - adjustment->page_size);
  adjustment->value = MAX (adjustment->value, 0.0);

  if (adjustment->value != old_val)
    {
      gtk_signal_handler_block_by_func (GTK_OBJECT (adjustment),
					GTK_SIGNAL_FUNC (gtk_text_adjustment),
					text);
      gtk_adjustment_changed (adjustment);
      gtk_signal_handler_unblock_by_func (GTK_OBJECT (adjustment),
					  GTK_SIGNAL_FUNC (gtk_text_adjustment),
					  text);
    }
  
  /* Just ignore it if we haven't been size-allocated and realized yet */
  if (text->line_start_cache == NULL) 
    return;
  
  if (adjustment == text->hadj)
    {
      g_warning ("horizontal scrolling not implemented");
    }
  else
    {
      gint diff = ((gint)adjustment->value) - text->last_ver_value;
      
      if (diff != 0)
	{
	  undraw_cursor (text, FALSE);
	  
	  if (diff > 0)
	    scroll_down (text, diff);
	  else /* if (diff < 0) */
	    scroll_up (text, diff);
	  
	  draw_cursor (text, FALSE);
	  
	  text->last_ver_value = adjustment->value;
	}
    }
#endif
}

void
gtk_text_freeze (GtkText *text)
{
  NSGtkText *t;
  g_return_if_fail (text != NULL);
  g_return_if_fail (GTK_IS_TEXT (text));

	t = [GTK_WIDGET(text)->proxy documentView];
	[[t textStorage] beginEditing];
  text->freeze_count++;
 // undraw_cursor (text, FALSE);
	[[t textStorage] endEditing];
}

void
gtk_text_thaw (GtkText *text)
{
  NSGtkText *t;
  g_return_if_fail (text != NULL);
  g_return_if_fail (GTK_IS_TEXT (text)); 
   
	t = [GTK_WIDGET(text)->proxy documentView];
	[[t textStorage] beginEditing];
  if (text->freeze_count)
    if (!(--text->freeze_count) && GTK_WIDGET_REALIZED (text))
      {
//    recompute_geometry (text);
    gtk_widget_queue_draw (GTK_WIDGET (text));
      }
//  draw_cursor (text, FALSE);
	[[t textStorage] endEditing];
}


