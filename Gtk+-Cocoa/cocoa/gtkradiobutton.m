//
//  gtkradiobutton.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Oct 13 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//
#import <AppKit/AppKit.h>
#import "NSGtkButton.h"

#include <gtk/gtk.h>

void
gtk_radio_button_init (GtkRadioButton *radio_button)
{
  NSGtkButton *but;

  GTK_WIDGET_SET_FLAGS (radio_button, GTK_NO_WINDOW);
  GTK_WIDGET_UNSET_FLAGS (radio_button, GTK_RECEIVES_DEFAULT);

  GTK_TOGGLE_BUTTON (radio_button)->active = TRUE;

  radio_button->group = g_slist_prepend (NULL, radio_button);


  but = [[NSGtkButton alloc] initWithFrame:NSMakeRect(0,0,100,100)];
  [GTK_WIDGET(radio_button)->proxy release];
  GTK_WIDGET(radio_button)->proxy = but;
  [but setButtonType:NSRadioButton];
  [but setAction: @selector (clicked:)];
  [but setTarget: but];
  [but setState:NSOnState];
  but->proxy = radio_button;
  //GTK_WIDGET(radio_button)->proxy = but;
  gtk_widget_set_state (GTK_WIDGET (radio_button), GTK_STATE_ACTIVE);

}

GtkWidget*
gtk_radio_button_new_with_label (GSList      *group,
				 const gchar *label)
{
  NSGtkButton *but;
  NSString *l;
  GtkWidget *radio_button;

  radio_button = gtk_radio_button_new (group);
  but = radio_button->proxy; 
  l = [NSString stringWithCString: label];
  [but setTitle:l];
  [but sizeToFit];

  return radio_button;
}

void
gtk_radio_button_set_group (GtkRadioButton *radio_button,
			    GSList         *group)
{
  g_return_if_fail (radio_button != NULL);
  g_return_if_fail (GTK_IS_RADIO_BUTTON (radio_button));
  g_return_if_fail (!g_slist_find (group, radio_button));

  if (radio_button->group)
    {
      GSList *slist;
      
      radio_button->group = g_slist_remove (radio_button->group, radio_button);
      
      for (slist = radio_button->group; slist; slist = slist->next)
	{
	  GtkRadioButton *tmp_button;
	  
	  tmp_button = slist->data;
	  
	  tmp_button->group = radio_button->group;
	}
    }
  
  radio_button->group = g_slist_prepend (group, radio_button);
  
  if (group)
    {
      GSList *slist;
      
      for (slist = group; slist; slist = slist->next)
	{
	  GtkRadioButton *tmp_button;
	  
	  tmp_button = slist->data;
	  
	  tmp_button->group = radio_button->group;
	}
    }

  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (radio_button), group == NULL);
}

void
gtk_radio_button_clicked (GtkButton *button)
{
  NSGtkButton *but;
  GtkToggleButton *toggle_button;
  GtkRadioButton *radio_button;
  GtkToggleButton *tmp_button;
  GtkStateType new_state;
  GSList *tmp_list;
  gint toggled;

  g_return_if_fail (button != NULL);
  g_return_if_fail (GTK_IS_RADIO_BUTTON (button));

  radio_button = GTK_RADIO_BUTTON (button);
  toggle_button = GTK_TOGGLE_BUTTON (button);
  toggled = FALSE;
  but = GTK_WIDGET(button)->proxy;

  gtk_widget_ref (GTK_WIDGET (button));

  if (toggle_button->active)
    {
      tmp_button = NULL;
      tmp_list = radio_button->group;

      while (tmp_list)
	{
	  tmp_button = tmp_list->data;
	  tmp_list = tmp_list->next;

	  if (tmp_button->active && tmp_button != toggle_button)
	    break;

	  tmp_button = NULL;
	}

      if (!tmp_button)
	{
	  new_state = (button->in_button ? GTK_STATE_PRELIGHT : GTK_STATE_ACTIVE);
	}
      else
	{
	  toggled = TRUE;
	  toggle_button->active = !toggle_button->active;
	
	  new_state = (button->in_button ? GTK_STATE_PRELIGHT : GTK_STATE_NORMAL);
	}
    }
  else
    {
      toggled = TRUE;
      toggle_button->active = !toggle_button->active;

      tmp_list = radio_button->group;
      while (tmp_list)
	{
	  tmp_button = tmp_list->data;
	  tmp_list = tmp_list->next;

	  if (tmp_button->active && (tmp_button != toggle_button))
	    {
	      gtk_button_clicked (GTK_BUTTON (tmp_button));
	      break;
	    }
	}

      new_state = (button->in_button ? GTK_STATE_PRELIGHT : GTK_STATE_ACTIVE);
    }

  if (GTK_WIDGET_STATE (button) != new_state)
    gtk_widget_set_state (GTK_WIDGET (button), new_state);

  if (toggled)
    gtk_toggle_button_toggled (toggle_button);

  gtk_widget_queue_draw (GTK_WIDGET (button));

  gtk_widget_unref (GTK_WIDGET (button));  
  
  [but setState:(toggle_button->active ? NSOnState : NSOffState)];
}


