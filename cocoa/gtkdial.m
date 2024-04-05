//
//  gtkdial.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Aug 11 2002.
//  Copyright (c) 2002 Zebra Development. All rights reserved.
//
#import <AppKit/AppKit.h>
#import "NSGtkDial.h"

#include <gtk/gtk.h>
#include "gtkdial.h"

void
gtk_dial_init (GtkDial *dial)
{
  NSGtkDial *d;

  dial->button           = 0;
  dial->policy           = GTK_UPDATE_CONTINUOUS;
  dial->view_only        = FALSE;
  dial->timer            = 0;
  dial->radius           = 0;
  dial->pointer_width    = 0;
  dial->angle            = 0.0;
  dial->percentage       = 0.0;
  dial->old_value        = 0.0;
  dial->old_lower        = 0.0;
  dial->old_upper        = 0.0;
  dial->adjustment       = NULL;
  dial->offscreen_pixmap = NULL;

  d = [[NSGtkDial alloc] initWithFrame:NSMakeRect(0,0,60,60)];
 [d setAllowsNonEdgePositions:FALSE];
 [d setAllowsCenterPoint:FALSE];
 [d setAction:@selector(value_changed:)];
 [d setTarget:d];

  GTK_WIDGET(dial)->proxy = d;
  d->proxy = dial;
}


