//
//  NSGtkMenuItem.m
//  Gtk+
//
//  Created by Paolo Costabel on Mon Jan 20 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "NSGtkMenuItem.h"

@implementation NSGtkMenuItem

- (void)activated:(id)sender
{
/*
	if(GTK_IS_CHECK_MENU_ITEM(proxy))
	{
		if([self state] == NSOffState)
		{
			[self setState:NSOnState];
			GTK_CHECK_MENU_ITEM(proxy)->active = TRUE;
		}
		else
		{
			[self setState:NSOffState];
			GTK_CHECK_MENU_ITEM(proxy)->active = FALSE;
		}
    }
	if(GTK_IS_RADIO_MENU_ITEM(proxy))
	{
		GSList *group;
 
		for(group = gtk_radio_menu_item_group(proxy);group; group = group->next)
			[GTK_WIDGET(group->data)->proxy setState:NSOffState];
        GTK_CHECK_MENU_ITEM(proxy)->active = TRUE;
		[self setState:NSOnState];
	}*/    
    gtk_signal_emit_by_name(proxy,"activate",proxy);
    if(callback)
		(callback)(proxy,user_data);
}

- (void)display
{
}
    
-(void)setFrameOrigin:(NSPoint)origin
{
    return;
}

-(void)setFrameSize:(NSSize)size
{
    return;
}
- (void)setNeedsDisplay:(BOOL)yesno
{
}

- (BOOL)validateMenuItem:(NSGtkMenuItem*)menuItem
{
	return GTK_WIDGET_SENSITIVE (menuItem->proxy);
}
@end
