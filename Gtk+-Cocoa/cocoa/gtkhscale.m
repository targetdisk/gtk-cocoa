//
//  gtkhscale.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Aug 11 2002.
//  Copyright (c) 2002 Zebra Development. All rights reserved.
//
#import <AppKit/AppKit.h>
#import "NSGtkScale.h"

#include <gtk/gtk.h>

void
gtk_hscale_init (GtkHScale *hscale)
{
  NSGtkScale *slider;
  GTK_WIDGET_SET_FLAGS (hscale, GTK_NO_WINDOW);
  
  slider = [[NSGtkScale alloc] initWithFrame:NSMakeRect(0,0,100,20)]; 
  [slider setAction: @selector(value_changed:)];
  [slider setTarget: slider];
  slider->proxy = hscale;
  GTK_WIDGET(hscale)->proxy = slider;
}

void
gtk_hscale_size_request (GtkWidget      *widget,
                         GtkRequisition *requisition)
{
  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_HSCALE (widget));
  g_return_if_fail (requisition != NULL);
  
  requisition->width = [widget->proxy frame].size.width;
  requisition->height = [widget->proxy frame].size.height;
}


