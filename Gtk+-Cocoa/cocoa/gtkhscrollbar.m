//
//  gtkhscrollbar.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Aug 11 2002.
//  Copyright (c) 2002 Zebra Development. All rights reserved.
//
#import <AppKit/AppKit.h>

#import "NSGtkScrollbar.h"
#include <gtk/gtk.h>

void
gtk_hscrollbar_init (GtkHScale *hscrollbar)
{
  NSGtkScrollbar *scroller;
  
  scroller = [[NSGtkScrollbar alloc] initWithFrame:NSMakeRect(0,0,100,20)]; 
  [scroller setEnabled:YES]; 
  [scroller setAction: @selector(value_changed:)];
  [scroller setTarget: scroller];
  scroller->proxy = hscrollbar;
  GTK_WIDGET(hscrollbar)->proxy = scroller;
}

void
gtk_hscrollbar_size_request (GtkWidget      *widget,
                         GtkRequisition *requisition)
{
  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_HSCROLLBAR (widget));
  g_return_if_fail (requisition != NULL);
  
  requisition->width = 15; // [widget->proxy frame].size.width;
  requisition->height = 15; //[widget->proxy frame].size.height;
}

void
gtk_hscrollbar_size_allocate (GtkWidget     *widget,
                              GtkAllocation *allocation)
{
  GtkRange *range;
  gint slider_width;
  gint trough_border;
  gint stepper_size;
  
  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_HSCROLLBAR (widget));
  g_return_if_fail (allocation != NULL);
  
  allocation->height = 15;
  widget->allocation = *allocation;
}


