//
//  NSGtkScrollbar.h
//  Gtk+
//
//  Created by Paolo Costabel on Mon Dec 30 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#include <gtk/gtk.h>


@interface NSGtkScrollbar : NSScroller
{

    GtkWidget *proxy;
}

- (void)value_changed:(id)sender;

@end
