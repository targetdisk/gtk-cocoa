//
//  NSGtkView.h
//  Gtk+
//
//  Created by Paolo Costabel on Sat Oct 05 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#include <gtk/gtk.h>

@interface NSGtkView : NSView
{
    GtkWidget *proxy;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent;

@end
