//
//  NSGtkText.h
//  Gtk+
//
//  Created by Paolo Costabel on Mon Dec 30 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#include <gtk/gtk.h>


@interface NSGtkText : NSTextView
{
@public
    GtkWidget *proxy;
	gboolean locked;
	NSTrackingRectTag tag;
}

- (void)reshape;
- (void)activate:(id)sender;
- (void)textDidChange:(NSNotification *)aNotification;
- (void)takeIntValueFrom : (id)sender;
- (void)mouseExited:(NSEvent *)theEvent;
- (void)mouseEntered:(NSEvent *)theEvent;
- (id) initWithFrame: (NSRect) frame;
- (void)viewWillMoveToWindow:(NSWindow *)newWindow;

@end
