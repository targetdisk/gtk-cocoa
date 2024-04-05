//
//  gtkvscrollbar.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Aug 11 2002.
//  Copyright (c) 2002 Zebra Development. All rights reserved.
//
#import <AppKit/AppKit.h>
#import "NSGtkScrollbar.h"

#include <gtk/gtk.h>

void
gtk_vscrollbar_init (GtkHScale *vscrollbar)
{
  NSGtkScrollbar *scroller;
  
  scroller = [[NSGtkScrollbar alloc] initWithFrame:NSMakeRect(0,0,20,100)]; 
  [scroller setEnabled:YES]; 
  [scroller setAction: @selector(value_changed:)];
  [scroller setTarget: scroller];
  scroller->proxy = vscrollbar;
  GTK_WIDGET(vscrollbar)->proxy = scroller;
  GTK_WIDGET(vscrollbar)->window = scroller;
}

void
gtk_vscrollbar_size_request (GtkWidget      *widget,
                         GtkRequisition *requisition)
{
  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_VSCROLLBAR (widget));
  g_return_if_fail (requisition != NULL);
  
  requisition->width = 15; // [widget->proxy frame].size.width;
  requisition->height = 15; //[widget->proxy frame].size.height;
}

void
gtk_vscrollbar_size_allocate (GtkWidget     *widget,
                              GtkAllocation *allocation)
{
  GtkRange *range;
  gint slider_width;
  gint trough_border;
  gint stepper_size;
  
  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_VSCROLLBAR (widget));
  g_return_if_fail (allocation != NULL);
  
  allocation->width = 15;
  widget->allocation = *allocation;
}


