//
//  gtkeditable.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Dec 29 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//
#import <AppKit/AppKit.h>
#import "NSGtkText.h"
#import "NSGtkEntry.h"

#include "gdk/gdkkeysyms.h"
#include "gdk/gdki18n.h"
#include <gtk/gtk.h>

enum {
  CHANGED,
  INSERT_TEXT,
  DELETE_TEXT,
  /* Binding actions */
  ACTIVATE,
  SET_EDITABLE,
  MOVE_CURSOR,
  MOVE_WORD,
  MOVE_PAGE,
  MOVE_TO_ROW,
  MOVE_TO_COLUMN,
  KILL_CHAR,
  KILL_WORD,
  KILL_LINE,
  CUT_CLIPBOARD,
  COPY_CLIPBOARD,
  PASTE_CLIPBOARD,
  LAST_SIGNAL
};

extern guint editable_signals[LAST_SIGNAL];

void
gtk_editable_set_editable (GtkEditable    *editable,
			   gboolean        is_editable)
{
  g_return_if_fail (editable != NULL);
  g_return_if_fail (GTK_IS_EDITABLE (editable));
  
  [GTK_WIDGET(editable)->proxy setEditable:is_editable];
  gtk_signal_emit (GTK_OBJECT (editable), editable_signals[SET_EDITABLE], is_editable != FALSE);
}

void
gtk_editable_insert_text (GtkEditable *editable,
			  const gchar *new_text,
			  gint         new_text_length,
			  gint        *position)
{
  NSGtkEntry *tf;
  GtkEditableClass *klass;
  gchar buf[64];
  gchar *text;

  g_return_if_fail (editable != NULL);
  g_return_if_fail (GTK_IS_EDITABLE (editable));

  gtk_widget_ref (GTK_WIDGET (editable));

  klass = GTK_EDITABLE_CLASS (GTK_OBJECT (editable)->klass);

  if (new_text_length <= 64)
    text = buf;
  else
    text = g_new (gchar, new_text_length);

  strncpy (text, new_text, new_text_length);

  gtk_signal_emit (GTK_OBJECT (editable), editable_signals[INSERT_TEXT], text, new_text_length, position);
  gtk_signal_emit (GTK_OBJECT (editable), editable_signals[CHANGED]);

  if (new_text_length > 64)
    g_free (text);
/*
  tf = GTK_WIDGET(editable)->proxy;
  if(tf->locked) return;
  tf->locked = TRUE;
  [tf setStringValue:[NSString stringWithCString:new_text]];
  tf->locked = FALSE;
*/

  gtk_widget_unref (GTK_WIDGET (editable));
}

void
gtk_editable_delete_text (GtkEditable *editable,
			  gint         start_pos,
			  gint         end_pos)
{
  GtkEditableClass *klass;

  g_return_if_fail (editable != NULL);
  g_return_if_fail (GTK_IS_EDITABLE (editable));

  gtk_widget_ref (GTK_WIDGET (editable));

  klass = GTK_EDITABLE_CLASS (GTK_OBJECT (editable)->klass);

  gtk_signal_emit (GTK_OBJECT (editable), editable_signals[DELETE_TEXT], start_pos, end_pos);
  gtk_signal_emit (GTK_OBJECT (editable), editable_signals[CHANGED]);

  gtk_widget_unref (GTK_WIDGET (editable));
}
