//
//  NSGtkScale.h
//  Gtk+
//
//  Created by Paolo Costabel on Sat Feb 01 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#include <gtk/gtk.h>




@interface NSGtkScale : NSSlider 
{

    GtkWidget *proxy;
}

- (void)value_changed:(id)sender;
- (void)mouseUp:(NSEvent *)theEvent;

@end
