//
//  gtkmenubar.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Oct 13 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//
#import <AppKit/AppKit.h>
#import "NSGtkButton.h"
#import	"NSGtkView.h"

#include <gtk/gtk.h>

void
gtk_menu_bar_init (GtkMenuBar *menu_bar)
{
  menu_bar->shadow_type = GTK_SHADOW_OUT;
}

void
gtk_menu_bar_append (GtkMenuBar *menu_bar,
		     GtkWidget  *child)
{
 	NSView *menuBar = (NSView *)GTK_WIDGET(menu_bar)->proxy;
  	NSPopUpButton *item;
      
 	item = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0,0,200,200) pullsDown:YES];
	[[item cell] setArrowPosition:NSPopUpNoArrow];
    [item setBordered:NO];
    [item setBezelStyle:NSShadowlessSquareBezelStyle];
    [item setMenu:[child->proxy submenu]];
    [item  setTitle:[child->proxy title]];
    [item sizeToFit];   
//    [menuBar addSubview:item];
    [child->proxy release];
    child->proxy = item;
	gtk_menu_shell_append (GTK_MENU_SHELL (menu_bar), child);

}
