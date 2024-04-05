//
//  gtkscale.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Aug 11 2002.
//  Copyright (c) 2002 Zebra Development. All rights reserved.
//
#import <AppKit/AppKit.h>

#include <gtk/gtk.h>

void
gtk_scale_set_draw_value (GtkScale *scale,
			  gboolean  draw_value)
{
  NSSlider *slider;
  g_return_if_fail (scale != NULL);
  g_return_if_fail (GTK_IS_SCALE (scale));

  draw_value = draw_value != FALSE;

  if (scale->draw_value != draw_value)
    {
      scale->draw_value = draw_value;

      gtk_widget_queue_resize (GTK_WIDGET (scale));
    }
  slider = GTK_WIDGET(scale)->proxy;
  if(draw_value)
	  [slider setNumberOfTickMarks:10];
  else
	  [slider setNumberOfTickMarks:0];
}


