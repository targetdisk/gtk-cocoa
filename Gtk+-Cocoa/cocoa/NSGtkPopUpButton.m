//
//  NSGtkPopUpButton.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Jan 26 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "NSGtkPopUpButton.h"


@implementation NSGtkPopUpButton

- (void)changed:(id)sender
{
	GtkOptionMenu *om;
	GtkMenuItem *mi;

	NSGtkPopUpButton *pum = ( NSGtkPopUpButton *)sender;
	int idx = [pum indexOfSelectedItem];
	om = pum->proxy;

	gtk_option_menu_set_history(pum->proxy, idx);
    mi = gtk_menu_get_active (om->menu); 
	gtk_menu_item_activate(mi);
}
@end
