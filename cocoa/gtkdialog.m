/*
 *  gtkdialog.c
 *  Gtk+
 *
 *  Created by Paolo Costabel on Sat Aug 10 2002.
 *  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
 *
 */
#import <AppKit/AppKit.h>
#import "GtkWindowPrivate.h"

#include "gtk/gtk.h"

void
gtk_dialog_init (GtkDialog *dialog)
{
  GtkWindowPrivate *win;
  GtkWidget *separator;
  NSRect	contentRect;
  unsigned int windowStyle;

  windowStyle = (NSTitledWindowMask | NSMiniaturizableWindowMask | 
                            NSResizableWindowMask | NSClosableWindowMask);
  win = [GtkWindowPrivate alloc];
  contentRect = NSMakeRect(0,0,100,500);

  win->widget = dialog;
  [win initWithContentRect:contentRect
		styleMask: windowStyle backing:NSBackingStoreBuffered defer: NO];
  GTK_WIDGET(dialog)->proxy = win;
  GTK_WIDGET(dialog)->window = [win contentView];
  dialog->vbox = gtk_vbox_new (FALSE, 0);
  gtk_container_add (GTK_CONTAINER (dialog), dialog->vbox);
  gtk_widget_show (dialog->vbox);

  dialog->action_area = gtk_hbox_new (TRUE, 5);
  gtk_container_set_border_width (GTK_CONTAINER (dialog->action_area), 10);
  gtk_box_pack_end (GTK_BOX (dialog->vbox), dialog->action_area, FALSE, TRUE, 0);
  gtk_widget_show (dialog->action_area);

  separator = gtk_hseparator_new ();
  gtk_box_pack_end (GTK_BOX (dialog->vbox), separator, FALSE, TRUE, 0);
  gtk_widget_show (separator);

  }
