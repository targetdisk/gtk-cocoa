//
//  gtkcheckbutton.m
//  Gtk+
//
//  Created by Paolo Costabel on Sat Oct 12 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//
#import <AppKit/AppKit.h>
#import "NSGtkButton.h"

#include <gtk/gtk.h>

void
gtk_check_button_init (GtkCheckButton *check_button)
{
  NSGtkButton *but;

  GTK_WIDGET_SET_FLAGS (check_button, GTK_NO_WINDOW);
  GTK_WIDGET_UNSET_FLAGS (check_button, GTK_RECEIVES_DEFAULT);
  GTK_TOGGLE_BUTTON (check_button)->draw_indicator = TRUE;
//  but = [[NSGtkButton alloc] initWithFrame:NSMakeRect(0,0,100,100)];
  but = GTK_WIDGET(check_button)->proxy;
  [but setButtonType:NSSwitchButton];
  [but setAction: @selector (clicked:)];
  [but setTarget: but];
  [but setTitle:@""];
  but->proxy = check_button;
  //GTK_WIDGET(check_button)->proxy = but;

}

GtkWidget*
gtk_check_button_new_with_label (const gchar *label)
{
  NSGtkButton *but;
  NSString *l;
  GtkWidget *check_button;
  GtkWidget *label_widget;
  
  check_button = gtk_check_button_new ();
  but = check_button->proxy; 
  l = [NSString stringWithCString: label];
  [but setTitle:l];
  [but sizeToFit];

  return check_button;
}

void
gtk_check_button_size_request (GtkWidget      *widget,
			       GtkRequisition *requisition)
{
  GtkToggleButton *toggle_button;
#if 0
  gint temp;
  gint indicator_size;
  gint indicator_spacing;
#endif
  
  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_CHECK_BUTTON (widget));
  g_return_if_fail (requisition != NULL);
  
  toggle_button = GTK_TOGGLE_BUTTON (widget);
  
  requisition->width = [widget->proxy frame].size.width; 
  requisition->height = [widget->proxy frame].size.height;
#if 0
  if (GTK_WIDGET_CLASS (parent_class)->size_request)
    (* GTK_WIDGET_CLASS (parent_class)->size_request) (widget, requisition);
  
  if (toggle_button->draw_indicator)
    {
      _gtk_check_button_get_props (GTK_CHECK_BUTTON (widget),
				   &indicator_size, &indicator_spacing);
						    
      requisition->width += (indicator_size +
			     indicator_spacing * 3 + 2);
      
      temp = indicator_size + indicator_spacing * 2;
      requisition->height = MAX (requisition->height, temp) + 2;
    }
#endif
}

void
gtk_check_button_size_allocate (GtkWidget     *widget,
				GtkAllocation *allocation)
{
  GtkCheckButton *check_button;
  GtkToggleButton *toggle_button;
  GtkButton *button;
  GtkAllocation child_allocation;
  gint indicator_size;
  gint indicator_spacing;
  
  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_CHECK_BUTTON (widget));
  g_return_if_fail (allocation != NULL);
  
  check_button = GTK_CHECK_BUTTON (widget);
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
gtk_real_check_button_draw_indicator (GtkCheckButton *check_button,
				      GdkRectangle   *area)
{
  NSGtkButton *but;
  GtkWidget *widget;
  GtkToggleButton *toggle_button;
  GtkStateType state_type;
  GtkShadowType shadow_type;
  GdkRectangle restrict_area;
  GdkRectangle new_area;
  gint width, height;
  gint x, y;
  gint indicator_size;
  gint indicator_spacing;
  GdkWindow *window;
  
  g_return_if_fail (check_button != NULL);
  g_return_if_fail (GTK_IS_CHECK_BUTTON (check_button));
  
  widget = GTK_WIDGET (check_button);
  toggle_button = GTK_TOGGLE_BUTTON (check_button);
  
#if 0
  if (GTK_WIDGET_DRAWABLE (check_button))
    {
      window = widget->window;
      
      _gtk_check_button_get_props (check_button, &indicator_size, &indicator_spacing);
						    
      state_type = GTK_WIDGET_STATE (widget);
      if (state_type != GTK_STATE_NORMAL &&
	  state_type != GTK_STATE_PRELIGHT)
	state_type = GTK_STATE_NORMAL;
      
      restrict_area.x = widget->allocation.x + GTK_CONTAINER (widget)->border_width;
      restrict_area.y = widget->allocation.y + GTK_CONTAINER (widget)->border_width;
      restrict_area.width = widget->allocation.width - ( 2 * GTK_CONTAINER (widget)->border_width);
      restrict_area.height = widget->allocation.height - ( 2 * GTK_CONTAINER (widget)->border_width);
      
      if (gdk_rectangle_intersect (area, &restrict_area, &new_area))
	{
	  if (state_type != GTK_STATE_NORMAL)
	    gtk_paint_flat_box (widget->style, window, state_type, 
				GTK_SHADOW_ETCHED_OUT, 
				area, widget, "checkbutton",
				new_area.x, new_area.y,
				new_area.width, new_area.height);
	}
      
      x = widget->allocation.x + indicator_spacing + GTK_CONTAINER (widget)->border_width;
      y = widget->allocation.y + (widget->allocation.height - indicator_size) / 2;
      width = indicator_size;
      height = indicator_size;
      


      gtk_paint_check (widget->style, window,
		       state_type, shadow_type,
		       area, widget, "checkbutton",
		       x + 1, y + 1, width, height);
    }
#endif

      but = GTK_WIDGET(check_button)->proxy;
      if (GTK_TOGGLE_BUTTON (check_button)->active)
	{
	  state_type = GTK_STATE_ACTIVE;
	  shadow_type = GTK_SHADOW_IN;
	  [but setState:NSOnState];
	}
      else
	{
	  shadow_type = GTK_SHADOW_OUT;
	  state_type = GTK_WIDGET_STATE (widget);
	  [but setState:NSOffState];
	}
}
