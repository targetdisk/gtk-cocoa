//
//  gtkrange.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Aug 11 2002.
//  Copyright (c) 2002 Zebra Development. All rights reserved.
//
#import <AppKit/AppKit.h>

#import "NSGtkScrollbar.h"
#include <gtk/gtk.h>

void gtk_range_adjustment_changed       (GtkAdjustment    *adjustment, gpointer          data);
void gtk_range_adjustment_value_changed (GtkAdjustment    *adjustment, gpointer          data);

void
gtk_range_default_slider_update (GtkRange *range)
{
  NSGtkScrollbar *scroller;
  NSSlider *slider;
  gfloat value,knob;

  g_return_if_fail (range != NULL);
  g_return_if_fail (GTK_IS_RANGE (range));

  if (GTK_WIDGET_REALIZED (range))
    {

      if (range->adjustment->value < range->adjustment->lower)
	{
	  range->adjustment->value = range->adjustment->lower;
	  gtk_signal_emit_by_name (GTK_OBJECT (range->adjustment), "value_changed");
	}
      else if (range->adjustment->value > range->adjustment->upper)
	{
	  range->adjustment->value = range->adjustment->upper;
	  gtk_signal_emit_by_name (GTK_OBJECT (range->adjustment), "value_changed");
	}

    }

	
    value = ((float)range->adjustment->value - range->adjustment->lower)/(range->adjustment->upper-range->adjustment->lower);
    knob = ((float)range->adjustment->page_size)/(range->adjustment->upper-range->adjustment->lower);
    if(knob > 1)
        knob = 1;
    if([GTK_WIDGET(range)->proxy isMemberOfClass:[NSGtkScrollbar class]])
    {
        scroller = GTK_WIDGET(range)->proxy;
	[scroller setFloatValue:value knobProportion:knob]; 
    }
    else
    {
        slider = GTK_WIDGET(range)->proxy;
		if([slider isVertical])
			[slider setFloatValue:(1-value)];
		else
			[slider setFloatValue:value];
    }
}


void
gtk_range_set_adjustment (GtkRange      *range,
			  GtkAdjustment *adjustment)
{
  NSScroller *scroller;
  NSSlider *slider;
  gfloat value,knob;
  g_return_if_fail (range != NULL);
  g_return_if_fail (GTK_IS_RANGE (range));
  
  if (!adjustment)
    adjustment = (GtkAdjustment*) gtk_adjustment_new (0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
  else
    g_return_if_fail (GTK_IS_ADJUSTMENT (adjustment));

  if (range->adjustment != adjustment)
    {
      if (range->adjustment)
	{
	  gtk_signal_disconnect_by_data (GTK_OBJECT (range->adjustment),
					 (gpointer) range);
	  gtk_object_unref (GTK_OBJECT (range->adjustment));
	}

      range->adjustment = adjustment;
      gtk_object_ref (GTK_OBJECT (adjustment));
      gtk_object_sink (GTK_OBJECT (adjustment));
      
      gtk_signal_connect (GTK_OBJECT (adjustment), "changed",
			  (GtkSignalFunc) gtk_range_adjustment_changed,
			  (gpointer) range);
      gtk_signal_connect (GTK_OBJECT (adjustment), "value_changed",
			  (GtkSignalFunc) gtk_range_adjustment_value_changed,
			  (gpointer) range);
      
      range->old_value = adjustment->value;
      range->old_lower = adjustment->lower;
      range->old_upper = adjustment->upper;
      range->old_page_size = adjustment->page_size;
      
      gtk_range_adjustment_changed (adjustment, (gpointer) range);
    }

    value = ((float)range->adjustment->value - range->adjustment->lower)/(range->adjustment->upper-range->adjustment->lower);
    knob = ((float)range->adjustment->page_size)/(range->adjustment->upper-range->adjustment->lower);
	if(knob > 1)
     knob = 1;
     
     if([GTK_WIDGET(range)->proxy isMemberOfClass:[NSScroller class]])
	{
		scroller = GTK_WIDGET(range)->proxy;
		[scroller setFloatValue:value knobProportion:knob]; 
	}
	else
	{
		slider = GTK_WIDGET(range)->proxy;
		[slider setFloatValue:value]; 
	}
}
