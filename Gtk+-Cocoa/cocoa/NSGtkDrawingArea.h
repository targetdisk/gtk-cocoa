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
- (void)drawRect:(NSRect)aRect;
- (void)rightMouseUp:(NSEvent *)theEvent;
- (void)rightMouseDown:(NSEvent *)theEvent;
- (void)rightMouseDragged:(NSEvent *)theEvent;
- (void)otherMouseUp:(NSEvent *)theEvent;
- (void)otherMouseDown:(NSEvent *)theEvent;
- (void)otherMouseDragged:(NSEvent *)theEvent;
- (void)mouseUp:(NSEvent *)theEvent;
- (void)mouseDown:(NSEvent *)theEvent;
- (void)mouseDragged:(NSEvent *)theEvent;
- (void)mouseExited:(NSEvent *)theEvent;
- (void)mouseEntered:(NSEvent *)theEvent;
@end
