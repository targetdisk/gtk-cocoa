//
//  NSGtkButton.h
//  Gtk+
//
//  Created by Paolo Costabel on Sun Sep 22 2002.
//  Copyright (c) 2002 Zebra Development. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#include <gtk/gtk.h>

@interface NSGtkButton : NSButton
{
@public
    GtkWidget *proxy;
	int width, height;
}

- (void)clicked:(id)sender;
- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal;
- (void)mouseDown:(NSEvent *)theEvent;
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender;
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender;

@end
