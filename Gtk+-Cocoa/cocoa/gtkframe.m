//
//  gtkframe.m
//  Gtk+
//
//  Created by Paolo Costabel on Sat Oct 05 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//
#import <AppKit/AppKit.h>
#import "NSGtkBox.h"

#include <gtk/gtk.h>

void
gtk_frame_init (GtkFrame *frame)
{
  NSGtkBox *box;
  GtkContainer *container = GTK_CONTAINER(frame);

  frame->label = NULL;
  frame->shadow_type = GTK_SHADOW_ETCHED_IN;
  frame->label_width = 0;
  frame->label_height = 0;
  frame->label_xalign = 0.0;
  frame->label_yalign = 0.5;

  container->border_width = 1;

  box = [[NSGtkBox alloc] initWithFrame:NSMakeRect(0,0,10,10)];
  [box setAutoresizesSubviews:FALSE];
  [box setContentViewMargins:NSMakeSize(0,0)];
  box->highlight = FALSE;
  [GTK_WIDGET(frame)->proxy release];
  GTK_WIDGET(frame)->proxy = box;
  GTK_WIDGET(frame)->window = box;
}

void
gtk_frame_set_label (GtkFrame *frame,
		     const gchar *label)
{
  NSGtkBox *box;
  g_return_if_fail (frame != NULL);
  g_return_if_fail (GTK_IS_FRAME (frame));

#if 0
  if ((label && frame->label && (strcmp (frame->label, label) == 0)) ||
      (!label && !frame->label))
    return;

  if (frame->label)
    g_free (frame->label);
  frame->label = NULL;

  if (label)
    {
      frame->label = g_strdup (label);
      frame->label_width = gdk_string_measure (GTK_WIDGET (frame)->style->font, frame->label) + 7;
      frame->label_height = (GTK_WIDGET (frame)->style->font->ascent +
			     GTK_WIDGET (frame)->style->font->descent + 1);
    }
  else
    {
      frame->label_width = 0;
      frame->label_height = 0;
    }

  if (GTK_WIDGET_DRAWABLE (frame))
    {
      GtkWidget *widget;

      /* clear the old label area
      */
      widget = GTK_WIDGET (frame);
      gtk_widget_queue_clear_area (widget,
				   widget->allocation.x + GTK_CONTAINER (frame)->border_width,
				   widget->allocation.y + GTK_CONTAINER (frame)->border_width,
				   widget->allocation.width - GTK_CONTAINER (frame)->border_width,
				   widget->allocation.y + frame->label_height);

    }
  
  gtk_widget_queue_resize (GTK_WIDGET (frame));
#endif
  box = GTK_WIDGET(frame)->proxy;
  if(label)
  {
	[box setTitlePosition:NSAtTop];
  	[GTK_WIDGET(frame)->proxy setTitle:[NSString stringWithCString: label]]; 
	frame->label_height = 14;
  }
  else
  {
	frame->label_height = 0;
	[box setTitlePosition:NSNoTitle];
  }
}

void
gtk_frame_set_shadow_type (GtkFrame      *frame,
			   GtkShadowType  type)
{
  NSGtkBox *box;
  g_return_if_fail (frame != NULL);
  g_return_if_fail (GTK_IS_FRAME (frame));

  if ((GtkShadowType) frame->shadow_type != type)
    {
      frame->shadow_type = type;

  	box = GTK_WIDGET(frame)->proxy;
	switch(type)
	{
		case GTK_SHADOW_NONE:
		    [box setBorderType:NSNoBorder];
		    break;
		case GTK_SHADOW_IN:
		case GTK_SHADOW_OUT:
		    [box setBorderType:NSLineBorder];
		    break;
		case GTK_SHADOW_ETCHED_IN:
		case GTK_SHADOW_ETCHED_OUT:
		    [box setBorderType:NSGrooveBorder];
		    break;
	}
			
    }
}


void
gtk_frame_highlight(GtkWidget *widget, gboolean on)
{
	NSGtkBox *box = widget->proxy;

	box->highlight = on;
	[box setNeedsDisplay:YES];
}
