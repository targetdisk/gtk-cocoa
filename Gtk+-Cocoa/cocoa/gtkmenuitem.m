//
//  gtkmenuitem.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Oct 13 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//
#import <AppKit/AppKit.h>
#import "NSGtkButton.h"

#include <gtk/gtk.h>
#import "NSGtkMenuItem.h"

void gtk_menu_item_detacher (GtkWidget     *widget, GtkMenu       *menu);

GtkWidget*
gtk_menu_item_new_with_label (const gchar *label)
{
  NSGtkMenuItem *l;
  GtkWidget *menu_item;
  GtkWidget *accel_label;

  menu_item = GTK_WIDGET (gtk_type_new (gtk_menu_item_get_type ()));
  accel_label = gtk_accel_label_new (label);
  gtk_misc_set_alignment (GTK_MISC (accel_label), 0.0, 0.5);

  gtk_container_add (GTK_CONTAINER (menu_item), accel_label);
  gtk_accel_label_set_accel_widget (GTK_ACCEL_LABEL (accel_label), menu_item);
  gtk_widget_show (accel_label);

  l = [[NSGtkMenuItem alloc] initWithTitle:[NSString stringWithCString:label] action:@selector(activated:)  keyEquivalent:@""];
  [l setTarget:l];
  [GTK_WIDGET(menu_item)->proxy release];
  GTK_WIDGET(menu_item)->proxy = l;
  l->proxy = menu_item;

  return menu_item;
}
 
void
gtk_menu_item_set_submenu (GtkMenuItem *menu_item,
			   GtkWidget   *submenu)
{
  NSPopUpButton *s;
  NSButton *m;
  NSRect frame;

  g_return_if_fail (menu_item != NULL);
  g_return_if_fail (GTK_IS_MENU_ITEM (menu_item));
  
  if (menu_item->submenu != submenu)
    {
      gtk_menu_item_remove_submenu (menu_item);
      
      menu_item->submenu = submenu;
      gtk_menu_attach_to_widget (GTK_MENU (submenu),
				 GTK_WIDGET (menu_item),
				 gtk_menu_item_detacher);
      
      if (GTK_WIDGET (menu_item)->parent)
	gtk_widget_queue_resize (GTK_WIDGET (menu_item));
    }
	m = GTK_WIDGET(menu_item)->proxy;
	s = submenu->proxy;
    if([m respondsToSelector:@selector(frame)])
    {
        frame = [m frame];
        frame.size.width +=50; // get rid of arrow
        [s setFrame:frame];
        [m addSubview:submenu->proxy];
    }
    else
     [m setSubmenu:[s menu]];
}

