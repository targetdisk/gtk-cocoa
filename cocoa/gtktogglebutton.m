//
//  gtktogglebutton.m
//  Gtk+
//
//  Created by Paolo Costabel on Sat Oct 12 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//
#import <AppKit/AppKit.h>
#import "NSGtkButton.h"

#include <gtk/gtk.h>

void
gtk_toggle_button_init (GtkCheckButton *toggle_button)
{
  NSGtkButton *but;

  GTK_WIDGET_SET_FLAGS (toggle_button, GTK_NO_WINDOW);
  GTK_WIDGET_UNSET_FLAGS (toggle_button, GTK_RECEIVES_DEFAULT);
  GTK_TOGGLE_BUTTON (toggle_button)->draw_indicator = TRUE;
  //but = [[NSGtkButton alloc] initWithFrame:NSMakeRect(0,0,100,100)];
	but = GTK_WIDGET(toggle_button)->proxy;
  [but setButtonType:NSPushOnPushOffButton];
  //[but setBezelStyle:NSRegularSquareBezelStyle];
  [but setBezelStyle:NSRoundedBezelStyle];
  [but setAction: @selector (clicked:)];
  [but setTarget: but];
  but->proxy = toggle_button;
  but->width = 48;
  but->height = 48;
  //GTK_WIDGET(toggle_button)->proxy = but;

}

GtkWidget*
gtk_toggle_button_new_with_label (const gchar *label)
{
  NSGtkButton *but;
  NSString *l;
  GtkWidget *toggle_button;
  GtkWidget *label_widget;
  
  toggle_button = gtk_toggle_button_new ();
  label_widget = gtk_label_new (label);
  gtk_misc_set_alignment (GTK_MISC (label_widget), 0.5, 0.5);

  gtk_container_add (GTK_CONTAINER (toggle_button), label_widget);

  but = toggle_button->proxy; 
  l = [NSString stringWithCString: label];
  [but setTitle:l];
  [but sizeToFit];

  but->width = [but frame].size.width;
  but->height = [but frame].size.height;
  
  // set the button as the label proxy
  // so that the text can be accessed directly
  //
  [label_widget->proxy release];
  label_widget->proxy= but;
  return toggle_button;
}

void
gtk_toggle_button_size_allocate (GtkWidget     *widget,
				GtkAllocation *allocation)
{
  GtkToggleButton *toggle_button;
  GtkButton *button;
  GtkAllocation child_allocation;
  gint indicator_size;
  gint indicator_spacing;
  
  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_TOGGLE_BUTTON (widget));
  g_return_if_fail (allocation != NULL);
  
  toggle_button = GTK_TOGGLE_BUTTON (widget);

  widget->allocation = *allocation;
#if 0
  if (toggle_button->draw_indicator)
    {
      _gtk_check_button_get_props (check_button, &indicator_size, &indicator_spacing);
						    
      widget->allocation = *allocation;
      if (GTK_WIDGET_REALIZED (widget))
	gdk_window_move_resize (toggle_button->event_window,
				allocation->x, allocation->y,
				allocation->width, allocation->height);
      
      button = GTK_BUTTON (widget);
      
      if (GTK_BIN (button)->child && GTK_WIDGET_VISIBLE (GTK_BIN (button)->child))
	{
	  gint border_width = GTK_CONTAINER (widget)->border_width;

	  child_allocation.x = (border_width +
				indicator_size +
				indicator_spacing * 3 + 1 +
				widget->allocation.x);
	  child_allocation.y = border_width + 1 + widget->allocation.y;
	  child_allocation.width =
	    MAX (1, allocation->x + (gint)allocation->width - (gint)child_allocation.x - (border_width + 1));
	  child_allocation.height = MAX (1, (gint)allocation->height - (border_width + 1) * 2);
	  
	  gtk_widget_size_allocate (GTK_BIN (button)->child, &child_allocation);
	}
    }
  else
    {
      if (GTK_WIDGET_CLASS (parent_class)->size_allocate)
	(* GTK_WIDGET_CLASS (parent_class)->size_allocate) (widget, allocation);
    }
#endif
}

void
gtk_toggle_button_set_active (GtkToggleButton *toggle_button,
			      gboolean         is_active)
{
  NSGtkButton *but;
  
  g_return_if_fail (toggle_button != NULL);
  g_return_if_fail (GTK_IS_TOGGLE_BUTTON (toggle_button));

  is_active = is_active != 0;

  but = GTK_WIDGET(toggle_button)->proxy; 
 if(is_active)
 	[but setState:NSOnState];
  else
 	[but setState:NSOffState]; 

  if (toggle_button->active != is_active)
    gtk_button_clicked (GTK_BUTTON (toggle_button));
}

void
gtk_toggle_button_set_mode (GtkToggleButton *toggle_button,
			    gboolean         draw_indicator)
{
  NSGtkButton *but, *oldBut;
  GtkWidget *widget;

  g_return_if_fail (toggle_button != NULL);
  g_return_if_fail (GTK_IS_TOGGLE_BUTTON (toggle_button));

  widget = GTK_WIDGET (toggle_button);
  draw_indicator = draw_indicator ? TRUE : FALSE;

  if (toggle_button->draw_indicator != draw_indicator)
    {
    
        oldBut = widget->proxy; 
        but = [[NSGtkButton alloc] initWithFrame:NSMakeRect(0,0,100,100)];
        [but setBordered:[oldBut isBordered]];
        [but setAction: @selector (clicked:)];
        [but setTarget: but];
        [but setTitle:[oldBut title]];
        if(oldBut->customImage)
        {
            [but setImage:[oldBut image]];
            [[but cell] setImagePosition:[[oldBut cell] imagePosition]];
        }
        but->proxy = widget;
        if(draw_indicator)
        {
            [but setButtonType:NSToggleButton];
        }
        else
        {
            [but setButtonType:NSPushOnPushOffButton]; 
        }
        [oldBut release];
        widget->proxy = but;
        widget->window = but;
        gtk_button_set_relief(widget, GTK_BUTTON(widget)->relief);
        [but sizeToFit];
        but->width = [but frame].size.width;
        but->height = [but frame].size.height;
        if (GTK_WIDGET_REALIZED (toggle_button))
	{
	  gboolean visible = GTK_WIDGET_VISIBLE (toggle_button);

	  if (visible)
	    gtk_widget_hide (widget);

	  gtk_widget_unrealize (widget);
	  toggle_button->draw_indicator = draw_indicator;

	  if (toggle_button->draw_indicator)
	    GTK_WIDGET_SET_FLAGS (toggle_button, GTK_NO_WINDOW);
	  else
	    GTK_WIDGET_UNSET_FLAGS (toggle_button, GTK_NO_WINDOW);
	  
	  gtk_widget_realize (widget);

	  if (visible)
	    gtk_widget_show (widget);
	}
      else
	{
	  toggle_button->draw_indicator = draw_indicator;

	  if (toggle_button->draw_indicator)
	    GTK_WIDGET_SET_FLAGS (toggle_button, GTK_NO_WINDOW);
	  else
	    GTK_WIDGET_UNSET_FLAGS (toggle_button, GTK_NO_WINDOW);
	}

      if (GTK_WIDGET_VISIBLE (toggle_button))
	gtk_widget_queue_resize (GTK_WIDGET (toggle_button));
    }
}

