//
//  gtkmenu.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Oct 13 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//
#import <AppKit/AppKit.h>
#import "NSGtkButton.h"
#import "GtkEvents.h"

#include <gtk/gtk.h>

#define	MENU_NEEDS_RESIZE(m) GTK_MENU_SHELL (m)->menu_flag

extern gboolean gtk_menu_window_event (GtkWidget *window, GdkEvent  *event, GtkWidget *menu);

void
gtk_menu_init (GtkMenu *menu)
{
  NSPopUpButton *m;

  menu->parent_menu_item = NULL;
  menu->old_active_menu_item = NULL;
  menu->accel_group = NULL;
  menu->position_func = NULL;
  menu->position_func_data = NULL;

  menu->toplevel = gtk_window_new (GTK_WINDOW_POPUP);
  gtk_signal_connect (GTK_OBJECT (menu->toplevel),
		      "event",
		      GTK_SIGNAL_FUNC (gtk_menu_window_event), 
		      GTK_OBJECT (menu));
  gtk_window_set_policy (GTK_WINDOW (menu->toplevel),
			 FALSE, FALSE, TRUE);

  gtk_container_add (GTK_CONTAINER (menu->toplevel), GTK_WIDGET (menu));

  /* Refloat the menu, so that reference counting for the menu isn't
   * affected by it being a child of the toplevel
   */
  GTK_WIDGET_SET_FLAGS (menu, GTK_FLOATING);

  menu->tearoff_window = NULL;
  menu->torn_off = FALSE;

  MENU_NEEDS_RESIZE (menu) = TRUE;

  m = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0,0,100,200) pullsDown:YES];
  [m addItemWithTitle:@""];
  [m setBordered:NO];
  [GTK_WIDGET(menu)->proxy release];
  GTK_WIDGET(menu)->proxy = m;
  GTK_WIDGET(menu)->window = m;
}


void
gtk_menu_append (GtkMenu   *menu,
		 GtkWidget *child)
{
    NSPopUpButton *m;

    m = GTK_WIDGET(menu)->proxy;

	[[m menu] addItem:child->proxy];
  gtk_menu_shell_append (GTK_MENU_SHELL (menu), child);
}

void
gtk_menu_insert (GtkMenu   *menu,
		 GtkWidget *child,
		 gint	    position)
{
  NSPopUpButton *m;

   m = GTK_WIDGET(menu)->proxy;
  [m insertItemWithTitle:[child->proxy title] atIndex:position];
  gtk_menu_shell_insert (GTK_MENU_SHELL (menu), child, position);
}


void
gtk_menu_popup (GtkMenu		    *menu,
		GtkWidget	    *parent_menu_shell,
		GtkWidget	    *parent_menu_item,
		GtkMenuPositionFunc  func,
		gpointer	     data,
		guint		     button,
		guint32		     activate_time)
{
	NSEvent * tEvent; 
	NSEventType type;
	int x = 0, y = 0;

	if(func)
		(*func)(menu,&x,&y,data);

	switch(button)
	{
		case 1:
			type = NSLeftMouseDown;
			break;
		case 2: 
			type = NSOtherMouseDown;
			break;
		default:
			type = NSRightMouseDown;
			break;
	}
	tEvent=[NSEvent mouseEventWithType:type
					location:NSMakePoint(x,y)
					modifierFlags:0
					timestamp:1
					windowNumber:[[NSApp mainWindow] windowNumber]
					context:[NSGraphicsContext currentContext]
					eventNumber:1
					clickCount:1
					pressure:0.0];
	[NSMenu popUpContextMenu:[GTK_WIDGET(menu)->proxy menu] withEvent:tEvent forView:[[NSApp mainWindow] contentView]];
	_mouse_state = 0;
}

void
gtk_menu_popdown (GtkMenu *menu)
{
}
