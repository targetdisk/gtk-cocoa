//
//  gtkaccellabel.m
//  Gtk+
//
//  Created by Paolo Costabel on Sat Sep 28 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//
#import <AppKit/AppKit.h>

#include <gtk/gtk.h>

extern GtkLabelClass *parent_class;

void
gtk_accel_label_init (GtkAccelLabel *accel_label)
{
  NSButton *text;

  accel_label->queue_id = 0;
  accel_label->accel_padding = 3;
  accel_label->accel_widget = NULL;
  accel_label->accel_string = NULL;
  
  text = [[NSButton alloc] initWithFrame:NSMakeRect(0,0,100,10)];

  [GTK_WIDGET(accel_label)->proxy release];
  GTK_WIDGET(accel_label)->proxy = text;
  GTK_WIDGET(accel_label)->superview = NULL;
  [text  setBordered:NO];

  gtk_accel_label_refetch (accel_label);
}

void
gtk_accel_label_size_request (GtkWidget	     *widget,
			      GtkRequisition *requisition)
{
  GtkAccelLabel *accel_label;
  NSButton *text;
  
  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_ACCEL_LABEL (widget));
  g_return_if_fail (requisition != NULL);
  
  accel_label = GTK_ACCEL_LABEL (widget);
  text = widget->proxy;
  
  if (GTK_WIDGET_CLASS (parent_class)->size_request)
    GTK_WIDGET_CLASS (parent_class)->size_request (widget, requisition);
  
  accel_label->accel_string_width = [text frame].size.width;
}


