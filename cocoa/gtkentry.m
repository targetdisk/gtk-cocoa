//
//  gtkentry.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Dec 29 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//
#import <AppKit/AppKit.h>
#import "NSGtkEntry.h"

#include <gtk/gtk.h>

void
gtk_entry_init (GtkEntry *entry)
{
  NSGtkEntry *tf;
  GTK_WIDGET_SET_FLAGS (entry, GTK_CAN_FOCUS);

  entry->text_area = NULL;
  entry->backing_pixmap = NULL;
  entry->text = NULL;
  entry->text_size = 0;
  entry->text_length = 0;
  entry->text_max_length = 0;
  entry->scroll_offset = 0;
  entry->timer = 0;
  entry->button = 0;
  entry->visible = 1;

  entry->char_offset = NULL;
  entry->text_mb = NULL;
  entry->text_mb_dirty = TRUE;
  entry->use_wchar = FALSE;

  tf = [[NSGtkEntry alloc] initWithFrame:NSMakeRect(0,0,100,22)];
  tf->locked = FALSE;
  tf->sb = NULL;
  [GTK_WIDGET(entry)->proxy release];
  GTK_WIDGET(entry)->proxy = tf;
  GTK_WIDGET(entry)->window = tf;
  [tf setDelegate:tf];
  [tf setAction: @selector (activate:)];
  [tf setTarget: tf];
  [[tf cell] setScrollable:YES];
  tf->proxy = entry;
  gtk_entry_grow_text (entry);
}

void
gtk_entry_size_allocate (GtkWidget     *widget,
			 GtkAllocation *allocation)
{
  GtkEntry *entry;
  GtkEditable *editable;
  NSGtkEntry *tf;

  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_ENTRY (widget));
  g_return_if_fail (allocation != NULL);

  tf = widget->proxy;
  allocation->width -=8;
  allocation->height  = [tf frame].size.height;
  allocation->x +=4;
  allocation->y +=8;
  widget->allocation = *allocation;
  entry = GTK_ENTRY (widget);
  editable = GTK_EDITABLE (widget);

}

void
gtk_entry_size_request (GtkWidget      *widget,
			GtkRequisition *requisition)
{
  NSGtkEntry *tf;

  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_ENTRY (widget));
  g_return_if_fail (requisition != NULL);

  tf = widget->proxy;
  requisition->width = [tf frame].size.width+8;
  requisition->height = [tf frame].size.height+12;
}

void
gtk_entry_set_editable(GtkEntry *entry,
		       gboolean  editable)
{
  NSGtkEntry *tf;
  NSWindow *win;
  GtkWidget *top;

  g_return_if_fail (entry != NULL);
  g_return_if_fail (GTK_IS_ENTRY (entry));

  tf = GTK_WIDGET(entry)->proxy;
  if(!editable)
  {
	  [tf setEditable:NO];
	  [tf setRefusesFirstResponder:YES];
	  win = [tf window];
	  [win makeFirstResponder:NULL];
  }
  else
  {
	  [tf setEditable:YES];
	  [tf setRefusesFirstResponder:NO];
  }
  gtk_editable_set_editable (GTK_EDITABLE (entry), editable);
}

void
gtk_entry_set_visibility (GtkEntry *entry,
			  gboolean visible)
{
  NSGtkEntry *tf;
  g_return_if_fail (entry != NULL);
  g_return_if_fail (GTK_IS_ENTRY (entry));

  tf = GTK_WIDGET(entry)->proxy;
  entry->visible = visible ? TRUE : FALSE;
  GTK_EDITABLE (entry)->visible = visible ? TRUE : FALSE;
  gtk_entry_recompute_offsets (entry);
  gtk_widget_queue_draw (GTK_WIDGET (entry));
}

void
gtk_entry_delete_text (GtkEditable *editable,
		       gint         start_pos,
		       gint         end_pos)
{
  NSGtkEntry *tf;

  gtk_entry_delete_text_gtk (editable,start_pos, end_pos);
  tf = GTK_WIDGET(editable)->proxy;
  if(tf->locked) return;
  tf->locked = TRUE;
  [tf setStringValue:[NSString stringWithCString:gtk_entry_get_text(editable)]];
  tf->locked = FALSE;
}

void
gtk_entry_delete_text_gtk (GtkEditable *editable,
		       gint         start_pos,
		       gint         end_pos)
{
  GdkWChar *text;
  gint deletion_length;
  gint i;

  GtkEntry *entry;
  
  g_return_if_fail (editable != NULL);
  g_return_if_fail (GTK_IS_ENTRY (editable));

  entry = GTK_ENTRY (editable);

  if (end_pos < 0)
    end_pos = entry->text_length;

  if (editable->selection_start_pos > start_pos)
    editable->selection_start_pos -= MIN(end_pos, editable->selection_start_pos) - start_pos;
  if (editable->selection_end_pos > start_pos)
    editable->selection_end_pos -= MIN(end_pos, editable->selection_end_pos) - start_pos;
  
  if ((start_pos < end_pos) &&
      (start_pos >= 0) &&
      (end_pos <= entry->text_length))
    {
      text = entry->text;
      deletion_length = end_pos - start_pos;

      /* Fix up the character offsets */
      if (GTK_WIDGET_REALIZED (entry))
	{
	  gint deletion_width = 
	    entry->char_offset[end_pos] - entry->char_offset[start_pos];

	  for (i = 0 ; i <= entry->text_length - end_pos; i++)
	    entry->char_offset[start_pos+i] = entry->char_offset[end_pos+i] - deletion_width;
	}

      for (i = end_pos; i < entry->text_length; i++)
        text[i - deletion_length] = text[i];

      for (i = entry->text_length - deletion_length; i < entry->text_length; i++)
        text[i] = '\0';

      entry->text_length -= deletion_length;
      editable->current_pos = start_pos;
    }

  entry->text_mb_dirty = 1;
}

void
gtk_entry_insert_text (GtkEditable *editable,
		       const gchar *new_text,
		       gint         new_text_length,
		       gint        *position)
{
  NSGtkEntry *tf;

  gtk_entry_insert_text_gtk (editable,new_text,new_text_length,position);
  tf = GTK_WIDGET(editable)->proxy;
  if(tf->locked) return;
  tf->locked = TRUE;
  [tf setStringValue:[NSString stringWithCString:gtk_entry_get_text(editable)]];
  tf->locked = FALSE;
}

void
gtk_entry_insert_text_gtk (GtkEditable *editable,
		       const gchar *new_text,
		       gint         new_text_length,
		       gint        *position)
{
  GdkWChar *text;
  gint start_pos;
  gint end_pos;
  gint last_pos;
  gint max_length;
  gint i;

  guchar *new_text_nt;
  gint insertion_length;
  GdkWChar *insertion_text;
  
  GtkEntry *entry;
  GtkWidget *widget;
  
  g_return_if_fail (editable != NULL);
  g_return_if_fail (GTK_IS_ENTRY (editable));

  entry = GTK_ENTRY (editable);
  widget = GTK_WIDGET (editable);
#if 0
  if ((entry->text_length == 0) && (entry->use_wchar == FALSE))
    {
      if (!GTK_WIDGET_REALIZED (widget))
	gtk_widget_ensure_style (widget);
      if ((widget->style) && (widget->style->font->type == GDK_FONT_FONTSET))
	entry->use_wchar = TRUE;
    }
#endif

  if (new_text_length < 0)
    {
      new_text_nt = (gchar *)new_text;
      new_text_length = strlen (new_text);
      if (new_text_length <= 0) return;
    }
  else if (new_text_length == 0)
    {
      return;
    }
  else
    {
      /* make a null-terminated copy of new_text */
      new_text_nt = g_new (gchar, new_text_length + 1);
      memcpy (new_text_nt, new_text, new_text_length);
      new_text_nt[new_text_length] = 0;
    }
    
  /* The algorithms here will work as long as, the text size (a
   * multiple of 2), fits into a guint16 but we specify a shorter
   * maximum length so that if the user pastes a very long text, there
   * is not a long hang from the slow X_LOCALE functions.  */
 
  if (entry->text_max_length == 0)
    max_length = 2047;
  else
    max_length = MIN (2047, entry->text_max_length);

  /* Convert to wide characters */
  insertion_text = g_new (GdkWChar, new_text_length);
/*
  if (entry->use_wchar)
    insertion_length = gdk_mbstowcs (insertion_text, new_text_nt,
				     new_text_length);
  else
*/
    for (insertion_length=0; new_text_nt[insertion_length]; insertion_length++)
      insertion_text[insertion_length] = new_text_nt[insertion_length];
  if (new_text_nt != (guchar *)new_text)
    g_free (new_text_nt);

  /* Make sure we do not exceed the maximum size of the entry. */
  if (insertion_length + entry->text_length > max_length)
    insertion_length = max_length - entry->text_length;

  /* Don't insert anything, if there was nothing to insert. */
  if (insertion_length <= 0)
    {
      g_free(insertion_text);
      return;
    }

  /* Make sure we are inserting at integral character position */
  start_pos = *position;
  if (start_pos < 0)
    start_pos = 0;
  else if (start_pos > entry->text_length)
    start_pos = entry->text_length;

  end_pos = start_pos + insertion_length;
  last_pos = insertion_length + entry->text_length;

  if (editable->selection_start_pos >= *position)
    editable->selection_start_pos += insertion_length;
  if (editable->selection_end_pos >= *position)
    editable->selection_end_pos += insertion_length;

  while (last_pos >= entry->text_size)
    gtk_entry_grow_text (entry);

  text = entry->text;
  for (i = last_pos - 1; i >= end_pos; i--)
    text[i] = text[i- (end_pos - start_pos)];
  for (i = start_pos; i < end_pos; i++)
    text[i] = insertion_text[i - start_pos];
  g_free (insertion_text);

  /* Fix up the the character offsets */
  
  if (GTK_WIDGET_REALIZED (entry))
    {
      gint offset = 0;
      
      for (i = last_pos; i >= end_pos; i--)
	entry->char_offset[i] = entry->char_offset[i - insertion_length];
      
      for (i=start_pos; i<end_pos; i++)
	{
	  GdkWChar ch;

	  entry->char_offset[i] = entry->char_offset[start_pos] + offset;

	  if (editable->visible)
	    ch = entry->text[i];
	  else 
	    ch = gtk_entry_get_invisible_char (entry);
/*
	  if (entry->use_wchar)
	    offset += gdk_char_width_wc (GTK_WIDGET (entry)->style->font, ch);
	  else
	    offset += gdk_char_width (GTK_WIDGET (entry)->style->font, ch);
*/
	}
      for (i = end_pos; i <= last_pos; i++)
	entry->char_offset[i] += offset;
    }

  entry->text_length += insertion_length;
  *position = end_pos;

  entry->text_mb_dirty = 1;
}


