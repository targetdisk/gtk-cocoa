//
//  gnomemenus.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Aug 11 2002.
//  Copyright (c) 2002 Zebra Development. All rights reserved.
//
#import <AppKit/AppKit.h>
#import "NSGtkMenuItem.h"

#include <gtk/gtk.h>
#include <gnome.h>
#include "gnome-app.h"
#include "gnome-app-helper.h"
#include "gnome-uidefs.h"

void do_ui_signal_connect (GnomeUIInfo        *uiinfo, const char         *signal_name, GnomeUIBuilderData *uibdata);
/**
 * gnome_app_fill_menu
 * @menu_shell:
 * @uiinfo:
 * @accel_group:
 * @uline_accels:
 * @pos:
 *
 * Description:
 * Fills the specified menu shell with items created from the specified
 * info, inserting them from the item no. pos on.
 * The accel group will be used as the accel group for all newly created
 * sub menus and serves as the global accel group for all menu item
 * hotkeys. If it is passed as NULL, global hotkeys will be disabled.
 * The uline_accels argument determines whether underline accelerators
 * will be featured from the menu item labels.
 **/

void
gnome_app_fill_menu (GtkMenuShell  *menu_shell,
		     GnomeUIInfo   *uiinfo,
		     GtkAccelGroup *accel_group,
		     gboolean       uline_accels,
		     gint           pos)
{
	GnomeUIBuilderData uibdata;
	NSMenuItem* helpMenu;

//	g_return_if_fail (menu_shell != NULL);
//	g_return_if_fail (GTK_IS_MENU_SHELL (menu_shell));
	g_return_if_fail (uiinfo != NULL);
	g_return_if_fail (pos >= 0);

	uibdata.connect_func =  do_ui_signal_connect;
	uibdata.data = NULL;
	uibdata.is_interp = FALSE;
	uibdata.relay_func = NULL;
	uibdata.destroy_func = NULL;


	[[NSApp mainMenu] setAutoenablesItems:FALSE];
	if(!menu_shell)
	{
		helpMenu = [[NSApp mainMenu] itemAtIndex:1];
		[helpMenu retain];
		[[NSApp mainMenu] removeItem:helpMenu];
	gnome_app_fill_menu_custom ([NSApp mainMenu], uiinfo, &uibdata,
				    accel_group, uline_accels,
				    pos);
		[[NSApp mainMenu] addItem:helpMenu];
		[helpMenu release];
	}
	else
	gnome_app_fill_menubar(menu_shell,uiinfo, &uibdata,
                    accel_group, uline_accels,
                    pos);
	return;
}


void
gnome_app_fill_menubar (GtkMenuBar *menu_bar,
			    GnomeUIInfo        *uiinfo,
			    GnomeUIBuilderData *uibdata,
			    GtkAccelGroup      *accel_group,
			    gboolean            uline_accels,
			    gint                pos)
{
  NSButton *l;
  GnomeUIBuilderData *orig_uibdata;
  GtkMenuItem *item;
  GtkMenuItem *menu;
  GtkMenu *submenu;
  char label[256];
  int i;
  char *c;
  

	orig_uibdata = uibdata;

	for (; uiinfo->type != GNOME_APP_UI_ENDOFINFO; uiinfo++)
	{
			for(i=0,c = uiinfo->label;c && *c;c++)
			{
				if(*c!='_')
					label[i++] = *c;
			}
			label[i] = '\0';
		switch (uiinfo->type) 
		{
				
			case GNOME_APP_UI_ITEM:
			case GNOME_APP_UI_ITEM_CONFIGURABLE:
			case GNOME_APP_UI_TOGGLEITEM:
				if(uiinfo->type==GNOME_APP_UI_TOGGLEITEM)
					item = gtk_check_menu_item_new_with_label (label); 
				else
					item = gtk_menu_item_new_with_label (label); 
				uiinfo->widget = item;
				gtk_widget_show(item);
				gtk_menu_append(menu_bar, item);
			break;
			case GNOME_APP_UI_SUBTREE:
			case GNOME_APP_UI_SUBTREE_STOCK:
				l = [[NSButton alloc] initWithFrame:NSMakeRect(0,0,100,10)];
				[l  setBordered:NO];
				[l setTitle:[NSString stringWithCString:label]];
				[l sizeToFit];
				menu = gtk_menu_item_new_with_label (label); 
                [GTK_WIDGET(menu)->proxy release];
				GTK_WIDGET(menu)->proxy = l;
				gtk_menu_bar_append(menu_bar, menu);
				gtk_widget_show(menu);
				submenu = gtk_menu_new();
				uiinfo->widget = menu;
				gnome_app_fill_menu_custom
					([GTK_WIDGET(submenu)->proxy menu],
					 uiinfo->moreinfo, orig_uibdata,
					 accel_group, uline_accels, 0);
				gtk_menu_item_set_submenu (menu, submenu);
		break;
			case GNOME_APP_UI_SEPARATOR:
				[[GTK_WIDGET(menu_bar)->proxy menu] addItem:[NSMenuItem separatorItem]];
		break;
			case GNOME_APP_UI_RADIOITEMS:
			pos = create_radio_menu_items ([GTK_WIDGET(menu_bar)->proxy menu],
					uiinfo->moreinfo, uibdata, accel_group,
					pos);
		}
	}
}
	
/**
 * gnome_app_fill_menu_custom
 * @menu_shell:
 * @uiinfo:
 * @uibdata:
 * @accel_group:
 * @uline_accels:
 * @pos:
 *
 * Description:
 * Fills the specified menu shell with items created from the specified
 * info, inserting them from item no. pos on and using the specified
 * builder data -- this is intended for language bindings.
 * The accel group will be used as the accel group for all newly created
 * sub menus and serves as the global accel group for all menu item
 * hotkeys. If it is passed as NULL, global hotkeys will be disabled.
 * The uline_accels argument determines whether underline accelerators
 * will be featured from the menu item labels.
 **/

void
gnome_app_fill_menu_custom (NSMenu *menu,
			    GnomeUIInfo        *uiinfo,
			    GnomeUIBuilderData *uibdata,
			    GtkAccelGroup      *accel_group,
			    gboolean            uline_accels,
			    gint                pos)
{
  NSGtkMenuItem *item;
  NSMenu *submenu;
  GnomeUIBuilderData *orig_uibdata;
  char label[256];
  int i;
  char *c;
  

	orig_uibdata = uibdata;

	for (; uiinfo->type != GNOME_APP_UI_ENDOFINFO; uiinfo++)
	{
			for(i=0,c = uiinfo->label;c && *c;c++)
			{
				if(*c!='_')
					label[i++] = *c;
			}
			label[i] = '\0';
		switch (uiinfo->type) 
		{
				
			case GNOME_APP_UI_ITEM:
			case GNOME_APP_UI_ITEM_CONFIGURABLE:
			case GNOME_APP_UI_TOGGLEITEM:
				if(uiinfo->accelerator_key)
				{
					char key[2];

					key[0] = uiinfo->accelerator_key;
					key[1] = '\0';
					item = [[NSGtkMenuItem alloc] initWithTitle:[NSString stringWithCString:label] action:@selector(activated:)  
							keyEquivalent:[NSString stringWithCString:key]];
				}
				else
					item = [[NSGtkMenuItem alloc] initWithTitle:[NSString stringWithCString:label] action:@selector(activated:)  keyEquivalent:@""];
				item->callback = uiinfo->moreinfo;
				item->user_data = uiinfo->user_data;
				if(uiinfo->type==GNOME_APP_UI_TOGGLEITEM)
					item->proxy = gtk_check_menu_item_new (); 
				else
					item->proxy = gtk_menu_item_new (); 
				uiinfo->widget = item->proxy;
				[item setTarget:item];
				[item setEnabled:FALSE];
 				[menu addItem: item];
				[item->proxy->proxy release];
				item->proxy->proxy = item;
				item->proxy->superview = NULL;
			break;
			case GNOME_APP_UI_SUBTREE:
			case GNOME_APP_UI_SUBTREE_STOCK:
 				item = [[NSGtkMenuItem alloc] initWithTitle:[NSString stringWithCString:label] action:nil keyEquivalent:@""];
 				[menu addItem: item];
				submenu = [[NSMenu alloc] initWithTitle:[NSString stringWithCString:label]];	
				gnome_app_fill_menu_custom
					(submenu,
					 uiinfo->moreinfo, orig_uibdata,
					 accel_group, uline_accels, 0);
 				[menu setSubmenu:submenu forItem:item];
				item->proxy = gtk_menu_item_new (); 
				[item->proxy->proxy release];
				item->proxy->proxy = item;
				uiinfo->widget = item->proxy;
		break;
			case GNOME_APP_UI_SEPARATOR:
				[menu addItem:[NSMenuItem separatorItem]];
		break;
			case GNOME_APP_UI_RADIOITEMS:
			pos = create_radio_menu_items (menu,
					uiinfo->moreinfo, uibdata, accel_group,
					pos);
		}
	}
	
#if 0

	g_return_if_fail (menu_shell != NULL);
	g_return_if_fail (GTK_IS_MENU_SHELL (menu_shell));
	g_return_if_fail (uiinfo != NULL);
	g_return_if_fail (uibdata != NULL);
	g_return_if_fail (pos >= 0);

	/* Store a pointer to the original uibdata so that we can use it for
	 * the subtrees */


	/* if it is a GtkMenu, make sure the accel group is associated
	 * with the menu */
	if (GTK_IS_MENU (menu_shell) &&
	    GTK_MENU (menu_shell)->accel_group == NULL)
			gtk_menu_set_accel_group (GTK_MENU (menu_shell),
						  accel_group);

	for (; uiinfo->type != GNOME_APP_UI_ENDOFINFO; uiinfo++)
		switch (uiinfo->type) {
		case GNOME_APP_UI_BUILDER_DATA:
			/* Set the builder data for subsequent entries in the
			 * current uiinfo array */
			uibdata = uiinfo->moreinfo;
			break;
/*
		case GNOME_APP_UI_HELP:
			pos = create_help_entries (menu_shell, uiinfo, pos);
			break;
*/

		case GNOME_APP_UI_RADIOITEMS:
			/* Create the radio item group */
			pos = create_radio_menu_items (menu_shell,
					uiinfo->moreinfo, uibdata, accel_group,
					pos);
			break;

		case GNOME_APP_UI_SEPARATOR:
		case GNOME_APP_UI_ITEM:
		case GNOME_APP_UI_ITEM_CONFIGURABLE:
		case GNOME_APP_UI_TOGGLEITEM:
		case GNOME_APP_UI_SUBTREE:
		case GNOME_APP_UI_SUBTREE_STOCK:
			if (uiinfo->type == GNOME_APP_UI_SUBTREE_STOCK)
				create_menu_item (menu_shell, uiinfo, FALSE,
						  NULL, uibdata,
						  accel_group, pos);
			else
				create_menu_item (menu_shell, uiinfo, FALSE,
						  NULL, uibdata,
						  accel_group, pos);

			if (uiinfo->type == GNOME_APP_UI_SUBTREE ||
			    uiinfo->type == GNOME_APP_UI_SUBTREE_STOCK) {
				/* Create the subtree for this item */
				GtkWidget *menu;
				GtkWidget *tearoff;
				guint notify_id;
				//GConfClient *client;
				
				menu = gtk_menu_new ();
				gtk_menu_item_set_submenu
					(GTK_MENU_ITEM(uiinfo->widget), menu);
				gtk_menu_set_accel_group (GTK_MENU (menu), accel_group);
				gnome_app_fill_menu_custom
					(GTK_MENU_SHELL (menu),
					 uiinfo->moreinfo, orig_uibdata,
					 accel_group, uline_accels, 0);
/*
				if (gnome_gconf_get_bool ("/desktop/gnome/interface/menus_have_tearoff")) {
					tearoff = gtk_tearoff_menu_item_new ();
					gtk_widget_show (tearoff);
					gtk_object_set_data (GTK_OBJECT (menu), "gnome-app-tearoff", tearoff);
					gtk_menu_shell_prepend (GTK_MENU_SHELL (menu), tearoff);
				}
*/

				/*
				client = gconf_client_get_default ();
				gtk_object_set_data_full(GTK_OBJECT(menu), gnome_app_helper_gconf_client,
						       client, gtk_object_unref);

				notify_id = gconf_client_notify_add (client,
								     "/desktop/gnome/interface/menus_have_tearoff",
								     menus_have_tearoff_changed_notify,
								     menu, NULL, NULL);
				gtk_signal_connect(menu, "destroy",
						 GTK_SIGNAL_FUNC(remove_notify_cb),
						 GINT_TO_POINTER(notify_id));
				*/

			}
			pos++;
			break;

		case GNOME_APP_UI_INCLUDE:
		        gnome_app_fill_menu_custom
			  (menu_shell,
			   uiinfo->moreinfo, orig_uibdata,
			   accel_group, uline_accels, pos);
			break;

		default:
			g_warning ("Invalid GnomeUIInfo element type %d\n",
					(int) uiinfo->type);
		}

	/* Make the end item contain a pointer to the parent menu shell */

	uiinfo->widget = GTK_WIDGET (menu_shell);
#endif
}

/* Creates a group of radio menu items.  Returns the updated position parameter. */
int
create_radio_menu_items (NSMenu *menu, GnomeUIInfo *uiinfo,
		GnomeUIBuilderData *uibdata, GtkAccelGroup *accel_group,
		gint pos)
{
  NSGtkMenuItem *item;
	GSList *group;

	group = NULL;

	for (; uiinfo->type != GNOME_APP_UI_ENDOFINFO; uiinfo++)
		switch (uiinfo->type) {
		case GNOME_APP_UI_BUILDER_DATA:
			uibdata = uiinfo->moreinfo;
			break;

		case GNOME_APP_UI_ITEM:
 				item = [[NSGtkMenuItem alloc] initWithTitle:[NSString stringWithCString:uiinfo->label] action:@selector(activated:) keyEquivalent:@""];
				item->proxy = gtk_radio_menu_item_new (group);
				item->callback = uiinfo->moreinfo;
				[item->proxy->proxy release];
				item->proxy->proxy = item;
				uiinfo->widget = item->proxy;
				group = gtk_radio_menu_item_group(item->proxy);
				[item setTarget:item];
 				[menu addItem: item];
			pos++;
			break;

		default:
			g_warning ("GnomeUIInfo element type %d is not valid "
					"inside a menu radio item group",
				   (int) uiinfo->type);
		}

	return pos;
}


