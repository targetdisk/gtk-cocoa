//
//  gtkseparator.m
//  Gtk+
//
//  Created by Paolo Costabel on Sat Oct 05 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//
#import <AppKit/AppKit.h>

#include <gtk/gtk.h>

void
gtk_separator_init (GtkSeparator *separator)
{
  NSBox *box;

  GTK_WIDGET_SET_FLAGS (separator, GTK_NO_WINDOW);
  box = [[NSBox alloc] initWithFrame:NSMakeRect(0,0,4,4)];
  [box setTitlePosition:NSNoTitle];
  [box setBoxType:NSBoxSeparator];
  GTK_WIDGET(separator)->proxy = box;
}
