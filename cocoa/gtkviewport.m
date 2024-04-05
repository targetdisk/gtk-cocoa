//
//  gtkviewport.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Aug 11 2002.
//  Copyright (c) 2002 Zebra Development. All rights reserved.
//
#import <AppKit/AppKit.h>

#include <gtk/gtk.h>

NSPoint convert_coords(GtkWidget *widget, int x, int y);

void
gtk_viewport_adjustment_value_changed (GtkAdjustment *adjustment,
				       gpointer       data)
{
  NSView *view;
  GtkViewport *viewport;
  GtkBin *bin;
  GtkAllocation child_allocation;

  g_return_if_fail (adjustment != NULL);
  g_return_if_fail (data != NULL);
  g_return_if_fail (GTK_IS_VIEWPORT (data));

  viewport = GTK_VIEWPORT (data);
  bin = GTK_BIN (data);

  if (bin->child && GTK_WIDGET_VISIBLE (bin->child))
    {
      child_allocation.x = 0;
      child_allocation.y = 0;

      if (viewport->hadjustment->lower != (viewport->hadjustment->upper -
					   viewport->hadjustment->page_size))
	child_allocation.x =  viewport->hadjustment->lower - viewport->hadjustment->value;

      if (viewport->vadjustment->lower != (viewport->vadjustment->upper -
					   viewport->vadjustment->page_size))
	child_allocation.y = GTK_WIDGET(viewport)->allocation.y + viewport->vadjustment->value - (viewport->vadjustment->upper - viewport->vadjustment->page_size); 

/*
      if (GTK_WIDGET_REALIZED (viewport))
	gdk_window_move (viewport->bin_window,
			 child_allocation.x,
			 child_allocation.y);
*/
	view = GTK_WIDGET(bin->child)->proxy;
	NSPoint origin = convert_coords( bin->child, child_allocation.x,child_allocation.y);
	printf("scrollwindow frame orgin %f %f\n",origin.x, origin.y);
	[view setFrameOrigin:origin];
  	[view setNeedsDisplay:TRUE];
    }
}


