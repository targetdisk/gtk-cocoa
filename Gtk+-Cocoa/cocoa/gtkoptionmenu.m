//
//  gtkoptionmenu.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Aug 11 2002.
//  Copyright (c) 2002 Zebra Development. All rights reserved.
//
#import <AppKit/AppKit.h>
#import "NSGtkPopUpButton.h"

#include <gtk/gtk.h>

void gtk_option_menu_detacher (GtkWidget     *widget, GtkMenu	*menu);
void gtk_option_menu_deactivate      (GtkMenuShell       *menu_shell, GtkOptionMenu      *option_menu);
void
gtk_option_menu_init (GtkOptionMenu *option_menu)
{
  NSGtkPopUpButton *om;
  GTK_WIDGET_SET_FLAGS (option_menu, GTK_CAN_FOCUS);
  GTK_WIDGET_UNSET_FLAGS (option_menu, GTK_CAN_DEFAULT | GTK_RECEIVES_DEFAULT);

  option_menu->menu = NULL;
  option_menu->menu_item = NULL;
  option_menu->width = 0;
  option_menu->height = 30;
  om = [[NSGtkPopUpButton alloc] initWithFrame:NSMakeRect(0,0,100,20)];
  [om setAction:@selector(changed:)];
  [om setTarget:om];
  om->proxy = option_menu;
  [GTK_WIDGET(option_menu)->proxy release];
  GTK_WIDGET(option_menu)->proxy = om;
}

void
gtk_option_menu_set_menu (GtkOptionMenu *option_menu,
			  GtkWidget     *menu)
{
  NSGtkPopUpButton *om;
  GList *l;
  GtkMenuItem *mi;
  g_return_if_fail (option_menu != NULL);
  g_return_if_fail (GTK_IS_OPTION_MENU (option_menu));
  g_return_if_fail (menu != NULL);
  g_return_if_fail (GTK_IS_MENU (menu));

  om = (NSGtkPopUpButton *)GTK_WIDGET(option_menu)->proxy;

  if (option_menu->menu != menu)
    {
      gtk_option_menu_remove_menu (option_menu);

      option_menu->menu = menu;

#if 0
      gtk_menu_attach_to_widget (GTK_MENU (menu),
				 GTK_WIDGET (option_menu),
				 gtk_option_menu_detacher);

	 
      gtk_option_menu_calc_size (option_menu);
      gtk_signal_connect (GTK_OBJECT (option_menu->menu), "deactivate",
			  (GtkSignalFunc) gtk_option_menu_deactivate,
			  option_menu);
#endif

	[om removeAllItems];
	for(l = GTK_MENU_SHELL (menu)->children;l;l= g_list_next(l))
	{
		char *s;
		mi = GTK_MENU_ITEM(l->data);
		gtk_label_get(GTK_LABEL(GTK_BIN(mi)->child),&s);
		[om addItemWithTitle:[NSString stringWithCString:s]];
	}
	[om sizeToFit];
	option_menu->width =[om frame].size.width;
	option_menu->height =[om frame].size.height;
    if (GTK_WIDGET (option_menu)->parent)
	{
		gtk_widget_queue_resize (GTK_WIDGET (option_menu));
		gdk_idle_hook();
	}

//      gtk_option_menu_update_contents (option_menu);
    }
	menu->proxy = om;
}

gchar *
gtk_option_menu_active_label(GtkOptionMenu *omenu)
{
	if(!omenu )
		return NULL;
	if( !GTK_IS_OPTION_MENU(omenu))
		return NULL;

	return [[[GTK_WIDGET(omenu)->proxy selectedItem] title] cString];
}

int
gtk_option_menu_active_index(GtkOptionMenu *omenu)
{
	return [GTK_WIDGET(omenu)->proxy indexOfSelectedItem];
}

void
gtk_option_menu_set_history (GtkOptionMenu *option_menu,
			     guint          index)
{
  GtkWidget *menu_item;
  NSGtkPopUpButton *om;
  
  g_return_if_fail (option_menu != NULL);
  g_return_if_fail (GTK_IS_OPTION_MENU (option_menu));

  if (option_menu->menu)
    {
      gtk_menu_set_active (GTK_MENU (option_menu->menu), index);
      menu_item = gtk_menu_get_active (GTK_MENU (option_menu->menu));

    om = (NSGtkPopUpButton *)GTK_WIDGET(option_menu)->proxy;
    printf("num items %d\n",[om numberOfItems]);
	[om selectItemAtIndex:index];
 //     if (menu_item != option_menu->menu_item)
//	gtk_option_menu_update_contents (option_menu);
    }
}


