//
//  GtkWindowPrivate.h
//  Gtk+
//
//  Created by Paolo Costabel on Sun Aug 18 2002.
//  Copyright (c) 2002 Zebra Development. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#include <gtk/gtk.h>

@interface GtkWindowPrivate : NSWindow
{
@public
    /* the widget associated with this window */
    GtkWidget *widget;
}
- (void)setFrame:(NSRect)frameRect display:(BOOL)flag;
- (void)windowDidResize:(NSNotification *)aNotification;
- (BOOL)makeFirstResponder:(NSResponder *)aResponder;
- (void)sendEvent:(NSEvent *)theEvent;
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent;

@end
