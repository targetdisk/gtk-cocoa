
//
//  gtkradiomenuitem.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Oct 13 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//
#import <AppKit/AppKit.h>
#import "NSGtkMenuItem.h"

#include <gtk/gtk.h>


GtkWidget*
gtk_radio_menu_item_new_with_label (GSList *group,
				    const gchar *label)
{
  GtkWidget *radio_menu_item;
  GtkWidget *accel_label;
  NSGtkMenuItem *l;
  
  radio_menu_item = gtk_radio_menu_item_new (group);
  accel_label = gtk_accel_label_new (label);
  gtk_misc_set_alignment (GTK_MISC (accel_label), 0.0, 0.5);
  gtk_container_add (GTK_CONTAINER (radio_menu_item), accel_label);
  accel_label->superview = NULL;
  gtk_accel_label_set_accel_widget (GTK_ACCEL_LABEL (accel_label), radio_menu_item);
  gtk_widget_show (accel_label);
  
  l = [[NSGtkMenuItem alloc] initWithTitle:[NSString stringWithCString:label] action:@selector(activated:)  keyEquivalent:@""];
  [l setTarget:l];
  [GTK_WIDGET(radio_menu_item)->proxy release];
  GTK_WIDGET(radio_menu_item)->proxy = l;
  GTK_WIDGET(radio_menu_item)->window = l;
  l->proxy = radio_menu_item;
  
  return radio_menu_item;
}

void
gtk_radio_menu_item_activate (GtkMenuItem *menu_item)
{
  GtkRadioMenuItem *radio_menu_item;
  GtkCheckMenuItem *check_menu_item;
  GtkCheckMenuItem *tmp_menu_item;
  GSList *tmp_list;
  gint toggled;

  g_return_if_fail (menu_item != NULL);
  g_return_if_fail (GTK_IS_RADIO_MENU_ITEM (menu_item));

  radio_menu_item = GTK_RADIO_MENU_ITEM (menu_item);
  check_menu_item = GTK_CHECK_MENU_ITEM (menu_item);
  toggled = FALSE;

  if (check_menu_item->active)
    {
      tmp_menu_item = NULL;
      tmp_list = radio_menu_item->group;

      while (tmp_list)
	{
	  tmp_menu_item = tmp_list->data;
	  tmp_list = tmp_list->next;

	  if (tmp_menu_item->active && (tmp_menu_item != check_menu_item))
	    break;

	  tmp_menu_item = NULL;
	}

      if (tmp_menu_item)
	{
	  toggled = TRUE;
	  check_menu_item->active = !check_menu_item->active;
	 
	}
    }
  else
    {
      toggled = TRUE;
      check_menu_item->active = !check_menu_item->active;

      tmp_list = radio_menu_item->group;
      while (tmp_list)
	{
	  tmp_menu_item = tmp_list->data;
	  tmp_list = tmp_list->next;

	  if (tmp_menu_item->active && (tmp_menu_item != check_menu_item))
	    {
	      gtk_menu_item_activate (GTK_MENU_ITEM (tmp_menu_item));
	      break;
	    }
	}
    }
 
  if (toggled)
    gtk_check_menu_item_toggled (check_menu_item); 
    
  
  gtk_widget_queue_draw (GTK_WIDGET (radio_menu_item));
}


