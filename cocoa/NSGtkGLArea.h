//
//  NSGtkGLArea.h
//  Gtk+
//
//  Created by Paolo Costabel on Thu Jan 09 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

#include <gtk/gtk.h>

@interface NSGtkGLArea : NSOpenGLView 
{
	GtkWidget *proxy;
	NSTrackingRectTag tag;
}

- (void)drawRect:(NSRect)aRect;
- (void)reshape;
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
- (id) initWithFrame: (NSRect) frame;
- (void)willRemoveSubview:(NSView *)subview;
- (void)viewWillMoveToWindow:(NSWindow *)newWindow;
- (BOOL)acceptsFirstResponder;
- (BOOL)becomeFirstResponder;
@end
