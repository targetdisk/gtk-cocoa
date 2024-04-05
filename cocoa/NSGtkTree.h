//
//  NSGtkTree.h
//  Gtk+
//
//  Created by Paolo Costabel on Sun Jan 05 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#include <gtk/gtk.h>


@interface NSGtkTree : NSOutlineView
{
@public
    GtkWidget *proxy;
	gboolean lock_size;
	NSTrackingRectTag tag;
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)outlineView:(NSOutlineView *)olv objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item ;
- (int)outlineView:(NSOutlineView *)olv numberOfChildrenOfItem:(id)item ;
- (BOOL)outlineView:(NSOutlineView *)olv isItemExpandable:(id)item ;
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent;

@end

@interface NSGtkTreeNode : NSObject
{
@public
	GtkCTreeNode *node;
}

@end
