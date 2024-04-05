//
//  NSGtkTableView.h
//  Gtk+
//
//  Created by Paolo Costabel on Sun Jan 05 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#include <gtk/gtk.h>


@interface NSGtkTableView : NSTableView 
{
@public
    GtkWidget *proxy;
	gboolean lock_size;
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex; 
@end
