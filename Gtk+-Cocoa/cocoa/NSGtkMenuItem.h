//
//  NSGtkMenuItem.h
//  Gtk+
//
//  Created by Paolo Costabel on Mon Jan 20 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#include <gtk/gtk.h>

@interface NSGtkMenuItem : NSMenuItem 
{
@public
	void (*callback)(void *, void *);	
	gpointer user_data;
	GtkWidget *proxy;
}

- (void)activated:(id)sender;
- (void)display;
- (void)setNeedsDisplay:(BOOL)yesno;
@end
