//
//  NSGtkDrawingArea.h
//  Gtk+
//
//  Created by Paolo Costabel on Tue Jul 22 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#include <gtk/gtk.h>

@interface NSGtkDrawingArea : NSView 
{
	GtkWidget *proxy;
}

- (BOOL)isFlipped;

@end
