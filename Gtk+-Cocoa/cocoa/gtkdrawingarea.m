
//
//  gtkdrawingarea.m
//  Gtk+
//
//  Created by Paolo Costabel on Sat Oct 05 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//
#import <AppKit/AppKit.h>
#import <NSGtkDrawingArea.h>

#include <gtk/gtk.h>

void
gtk_drawing_area_init (GtkDrawingArea *darea)
{
	NSGtkDrawingArea *view;	
	
  view = [[NSGtkDrawingArea alloc] initWithFrame:NSMakeRect(0,0,10,10)];
  darea->draw_data = NULL;
  [GTK_WIDGET(darea)->proxy release];
  GTK_WIDGET(darea)->proxy = view;
  GTK_WIDGET(darea)->window = view;
//  GTK_WIDGET(darea)->style = &default_style;
  view->proxy = darea;
}


