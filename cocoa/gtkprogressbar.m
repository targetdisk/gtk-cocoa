//
//  gtkprogressbar.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Aug 11 2002.
//  Copyright (c) 2002 Zebra Development. All rights reserved.
//
#import <AppKit/AppKit.h>
#import "NSGtkProgressBar.h"

#include <gtk/gtk.h>
 
void
gtk_progress_bar_init (GtkProgressBar *pbar)
{
  NSGtkProgressBar *pb;

  pbar->bar_style = GTK_PROGRESS_CONTINUOUS;
  pbar->blocks = 10;
  pbar->in_block = -1;
  pbar->orientation = GTK_PROGRESS_LEFT_TO_RIGHT;
  pbar->activity_pos = 0;
  pbar->activity_dir = 1;
  pbar->activity_step = 3;
  pbar->activity_blocks = 5;

  pb = [[NSGtkProgressBar alloc] initWithFrame:NSMakeRect(0,0,100,20)];
  pb->proxy = pbar;
  [GTK_WIDGET(pbar)->proxy release];
  GTK_WIDGET(pbar)->proxy = pb;
  GTK_WIDGET(pbar)->window = pb;
  [pb setMinValue:0];
  [pb setMaxValue:1];
  [pb setDoubleValue:0];
  [pb setIndeterminate:FALSE];
}

void
gtk_progress_bar_real_update (GtkProgress *progress)
{
  GtkProgressBar *pbar;
  GtkWidget *widget;
  GtkAdjustment *adj;
  NSGtkProgressBar *pb;

  g_return_if_fail (progress != NULL);
  g_return_if_fail (GTK_IS_PROGRESS (progress));

  pbar = GTK_PROGRESS_BAR (progress);
  widget = GTK_WIDGET (progress);
 
  if (pbar->bar_style == GTK_PROGRESS_CONTINUOUS ||
      GTK_PROGRESS (pbar)->activity_mode)
    {
      if (GTK_PROGRESS (pbar)->activity_mode)
	{
	  guint size;

	  /* advance the block */

	  if (pbar->orientation == GTK_PROGRESS_LEFT_TO_RIGHT ||
	      pbar->orientation == GTK_PROGRESS_RIGHT_TO_LEFT)
	    {
	      size = MAX (2, widget->allocation.width / pbar->activity_blocks);

	      if (pbar->activity_dir == 0)
		{
		  pbar->activity_pos += pbar->activity_step;
		  if (pbar->activity_pos + size >=
		      widget->allocation.width -
		      widget->style->klass->xthickness)
		    {
		      pbar->activity_pos = widget->allocation.width -
			widget->style->klass->xthickness - size;
		      pbar->activity_dir = 1;
		    }
		}
	      else
		{
		  pbar->activity_pos -= pbar->activity_step;
		  if (pbar->activity_pos <= widget->style->klass->xthickness)
		    {
		      pbar->activity_pos = widget->style->klass->xthickness;
		      pbar->activity_dir = 0;
		    }
		}
	    }
	  else
	    {
	      size = MAX (2, widget->allocation.height / pbar->activity_blocks);

	      if (pbar->activity_dir == 0)
		{
		  pbar->activity_pos += pbar->activity_step;
		  if (pbar->activity_pos + size >=
		      widget->allocation.height -
		      widget->style->klass->ythickness)
		    {
		      pbar->activity_pos = widget->allocation.height -
			widget->style->klass->ythickness - size;
		      pbar->activity_dir = 1;
		    }
		}
	      else
		{
		  pbar->activity_pos -= pbar->activity_step;
		  if (pbar->activity_pos <= widget->style->klass->ythickness)
		    {
		      pbar->activity_pos = widget->style->klass->ythickness;
		      pbar->activity_dir = 0;
		    }
		}
	    }
	}
  //    gtk_progress_bar_paint (progress);
      gtk_widget_queue_draw (GTK_WIDGET (progress));
    }
  else
    {
      gint in_block;
      
      in_block = -1 + (gint)(gtk_progress_get_current_percentage (progress) *
			     (gfloat)pbar->blocks);
      
      if (pbar->in_block != in_block)
	{
	  pbar->in_block = in_block;
//	  gtk_progress_bar_paint (progress);
	  gtk_widget_queue_draw (GTK_WIDGET (progress));
	}
    }
	adj = GTK_PROGRESS (pbar)->adjustment;
	pb = GTK_WIDGET(pbar)->proxy;
	[pb setMinValue:adj->lower];
	[pb setMaxValue:adj->upper];
	[pb setDoubleValue:adj->value ];
    [pb display];
}


