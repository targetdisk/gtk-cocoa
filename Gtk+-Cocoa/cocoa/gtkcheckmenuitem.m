
//
//  gtkcheckmenuitem.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Oct 13 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//
#import <AppKit/AppKit.h>
#import "NSGtkMenuItem.h"

#include <gtk/gtk.h>


enum {
  TOGGLED,
  LAST_SIGNAL
};

extern guint check_menu_item_signals[LAST_SIGNAL];

void
gtk_check_menu_item_set_active (GtkCheckMenuItem *check_menu_item,
				gboolean          is_active)
{
  g_return_if_fail (check_menu_item != NULL);
  g_return_if_fail (GTK_IS_CHECK_MENU_ITEM (check_menu_item));

  is_active = is_active != 0;

  if (check_menu_item->active != is_active)
    gtk_menu_item_activate (GTK_MENU_ITEM (check_menu_item));
  if(is_active)
	  [GTK_WIDGET(check_menu_item)->proxy setState:NSOnState];
  else
	  [GTK_WIDGET(check_menu_item)->proxy setState:NSOffState];
}

GtkWidget*
gtk_check_menu_item_new_with_label (const gchar *label)
{
  NSGtkMenuItem *l;
  GtkWidget *check_menu_item;
  GtkWidget *accel_label;

  check_menu_item = gtk_check_menu_item_new ();
  accel_label = gtk_accel_label_new (label);
  gtk_misc_set_alignment (GTK_MISC (accel_label), 0.0, 0.5);

  gtk_container_add (GTK_CONTAINER (check_menu_item), accel_label);
  gtk_accel_label_set_accel_widget (GTK_ACCEL_LABEL (accel_label), check_menu_item);
  gtk_widget_show (accel_label);

  l = [[NSGtkMenuItem alloc] initWithTitle:[NSString stringWithCString:label] action:nil keyEquivalent:@""];
  GTK_WIDGET(check_menu_item)->proxy = l;
  return check_menu_item;
}

void
gtk_check_menu_item_toggled (GtkCheckMenuItem *check_menu_item)
{
  if(check_menu_item->active)
		  [GTK_WIDGET(check_menu_item)->proxy setState:NSOnState];
	 else
		  [GTK_WIDGET(check_menu_item)->proxy setState:NSOffState];
  gtk_signal_emit (GTK_OBJECT (check_menu_item), check_menu_item_signals[TOGGLED]);
}

